data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-${var.environment}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-instance-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  user_data_template = <<-EOT
              #!/bin/bash
              set -eux
              dnf update -y
              dnf install -y docker awscli
              systemctl enable docker
              systemctl start docker
              IMAGE_URI="%s"
              REGION="%s"
              REGISTRY=$(echo "$IMAGE_URI" | cut -d'/' -f1)
              aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"
              docker pull "$IMAGE_URI"
              docker rm -f app || true
              docker run -d --name app --restart always -p 80:80 "$IMAGE_URI"
              EOT
}

resource "aws_launch_template" "blue" {
  name_prefix   = "${var.project_name}-${var.environment}-blue-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = base64encode(format(local.user_data_template, var.blue_image_uri, var.aws_region))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "green" {
  name_prefix   = "${var.project_name}-${var.environment}-green-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = base64encode(format(local.user_data_template, var.green_image_uri, var.aws_region))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "blue" {
  name                = "${var.project_name}-${var.environment}-blue-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = 0
  max_size            = 2
  desired_capacity    = var.blue_desired_capacity
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  target_group_arns = [var.blue_target_group_arn]

  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_template"]
  }
}

resource "aws_autoscaling_group" "green" {
  name                = "${var.project_name}-${var.environment}-green-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = 0
  max_size            = 2
  desired_capacity    = var.green_desired_capacity
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  target_group_arns = [var.green_target_group_arn]

  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_template"]
  }
}
