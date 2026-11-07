# Target: AWS

Most powerful, with the largest surface. Default shape: a container on **ECS Fargate** behind an ALB, **RDS** for the database, **ECR** for images, **Secrets Manager** for app secrets, and CloudWatch for logs and alarms. Use Lambda + API Gateway only when the architecture calls for serverless.

1. **Files:** IaC in the devops role's paths, using **CDK** (`cdk.json` + stacks) or **Terraform** (`*.tf` with a remote state backend and locking). Keep a separate stack or workspace per environment.
2. **CI steps:**
   ```bash
   # auth: OIDC → assume role (no long-lived keys)
   aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR"
   docker build -t "$ECR/$IMAGE:$GIT_SHA" . && docker push "$ECR/$IMAGE:$GIT_SHA"
   # infra (reviewed plan artifact): terraform plan -out=tfplan → terraform apply tfplan   |   cdk diff → cdk deploy --require-approval never
   # migrations: one-off ECS task with the new image running <migrate cmd>
   # app: update the service / task definition to the new image digest; wait for services-stable
   curl -fsS "$URL$HEALTH_PATH"
   ```
   Production applies only the plan produced and reviewed for this release (attach it to `RELEASE-REVIEW.md`).
3. **Secrets:** `AWS_ROLE_ARN` (OIDC deploy role per environment, least privilege), `AWS_REGION`. App secrets live in Secrets Manager and are referenced by ARN in the task definition.
4. **Health:** ALB target-group health check on `deploy.health_path`, plus CloudWatch alarms on 5xx rate and latency.
5. **Rollback:** ECS deployment circuit breaker with automatic rollback, or redeploy the previous task definition revision. For data, RDS point-in-time restore, or a snapshot taken before the migration.
6. **Bootstrap:** separate accounts (or at least separate VPCs) for staging and production; an OIDC identity provider for the CI platform; deploy roles; a Terraform state bucket and lock table (or `cdk bootstrap`); a Route 53 / ACM certificate; budget alarms.
