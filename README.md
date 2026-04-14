# React + Terraform + Docker + GitLab CI/CD (Blue/Green)

## What was implemented

- A React application scaffolded with Vite under `frontend/`.
- A multi-stage Docker build that compiles the React app and serves static files with Nginx.
- Terraform infrastructure split by concern:
  - `infra/backend`: bootstrap remote Terraform backend (S3 state + DynamoDB lock table).
  - `infra/modules/network`: VPC, public subnets, IGW, routing.
  - `infra/modules/load_balancer`: ALB, blue/green target groups, HTTP listener.
  - `infra/modules/compute`: launch templates, ASGs for blue and green pools, EC2 IAM profile, app SG.
  - `infra/modules/ecr`: ECR repository for app images.
  - `infra/envs/prod`: environment composition and deploy controls.
- A GitLab pipeline (`.gitlab-ci.yml`) for blue/green deployment flow on AWS using Terraform.

## Project structure

- `frontend/`: React source code.
- `Dockerfile`: Dockerized build + runtime image.
- `nginx/default.conf`: SPA-friendly Nginx routing and `/health` endpoint.
- `infra/`: Terraform code.
- `.gitlab-ci.yml`: CI/CD workflow.
- `IMPLEMENTATION.md`: this guide.

## Terraform backend bootstrap

Terraform backend resources are created separately in `infra/backend` so the main environment can use remote state.

1. Bootstrap backend once:

```bash
cd infra/backend
terraform init
terraform apply -var="aws_region=us-east-1" -var="project_name=react-bluegreen" -var="environment=shared"
```

2. Use outputs from bootstrap for `infra/envs/prod` backend init:

- S3 bucket: `<project>-shared-tf-state`
- DynamoDB table: `<project>-shared-tf-lock`

You can copy `infra/envs/prod/backend.hcl.example` as a template for local runs.

## Dockerized React app

Build locally:

```bash
docker build -t react-bluegreen:local .
```

Run locally:

```bash
docker run --rm -p 8080:80 react-bluegreen:local
```

App will be available at `http://localhost:8080`.

## Blue/Green deployment model

- Two Auto Scaling Groups are maintained: blue and green.
- Both connect to separate ALB target groups.
- `active_color` determines which target group receives traffic.
- During deployment, green can be brought up with new image while blue stays live.
- After validation, switch ALB listener to green.
- Optional cleanup scales blue down.

## GitLab CI/CD flow

Pipeline stages:

1. `validate_frontend`: installs dependencies and builds React app.
2. `build_and_push_image`: builds Docker image and pushes to ECR with tag `CI_COMMIT_SHORT_SHA`.
3. `terraform_deploy_green`: deploys/updates green capacity with the new image while traffic remains blue.
4. `terraform_switch_to_green` (manual): flips traffic to green.
5. `terraform_decommission_blue` (manual): scales down blue.
6. `terraform_rollback_to_blue` (manual): rollback option.

## Required GitLab CI variables

Set these in GitLab Project CI/CD variables:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_ACCOUNT_ID`
- `ECR_REPOSITORY_NAME` (must match Terraform-created ECR repo)
- `TF_STATE_BUCKET`
- `TF_LOCK_TABLE`
- Optional: `BLUE_IMAGE_TAG` (defaults to `latest`)

## Terraform variables that control deployment

In `infra/envs/prod/variables.tf`:

- `active_color`: `blue` or `green`
- `blue_image_tag`, `green_image_tag`
- `blue_desired_capacity`, `green_desired_capacity`
- `instance_type`

These variables are used directly in the pipeline jobs to orchestrate blue/green transitions.
