# Instructions for Project Deployment

This document provides a step-by-step guide to setting up and deploying the Weather Dashboard API project. It is an iterative document that will be updated as the project evolves.

## Module 1 & 2: Initial Project and Version Control Setup

1.  **Create GitHub Repository:**
    *   A new repository was created on GitHub to host the project code.

2.  **Generate Personal Access Token (PAT):**
    *   A GitHub PAT was created with the necessary permissions (`repo`, `workflow`, `write:packages`, `delete:packages`) to allow communication between the local machine/VS Code and the remote repository.

3.  **Set Up GitHub Project:**
    *   A new project board was created in the repository using the "Kanban" template.
    *   The board is configured with columns: `Backlog`, `In Progress`, `Review`, and `Done`.

4.  **Configure GitFlow Branching Strategy:**
    *   The `develop` branch was created from the `master` branch to serve as the primary integration branch.

5.  **Set Up Branch Protection Rules:**
    *   Protection rules were configured for both `master` and `develop` branches, requiring a pull request and at least one approval before merging.

6.  **Implement CODEOWNERS:**
    *   The `.github/CODEOWNERS` file was created to automatically assign reviewers for pull requests based on the directory being changed.

## Module 3: Continuous Integration (CI)

1.  **Create Infrastructure Pipeline (`infra-ci.yml`):**
    *   Configured to trigger on pull requests targeting the `develop` branch when files in the `infra/` directory are changed.
    *   Steps include: checking out code, setting up Terraform, running `init`, `fmt`, `validate`, security scanning with Checkov, and `terraform plan`.

2.  **Create Application Pipeline (`app-ci.yml`):**
    *   Configured to trigger on pull requests targeting the `develop` branch when files in the `app/` directory are changed.
    *   Steps include: checking out code, setting up Python, installing dependencies, and running `flake8` for linting.

## Module 4: Infrastructure as Code (IaC) with Terraform

1.  **Configure Terraform S3 Backend:**
    *   `backend.tf` files were created in each environment (`dev`, `staging`, `prod`) to configure remote state storage in a shared S3 bucket, with separate state files for each environment.

2.  **Automate Backend Creation:**
    *   The `scripts/setup_terraform_backend.sh` script was created to automate the creation and versioning of the S3 bucket for Terraform state.

3.  **Handle Line Endings (`.gitattributes`):**
    *   A `.gitattributes` file was added to enforce Unix-style LF line endings for `.sh` files, ensuring cross-platform compatibility.

4.  **Enable Secure AWS Authentication (OIDC):**
    *   The `infra-ci.yml` workflow was updated to use the `aws-actions/configure-aws-credentials` action for secure, passwordless authentication.
    *   The `scripts/setup_aws_oidc.sh` script was created to automate the setup of the OIDC provider and the necessary IAM Role in AWS.
    *   The role's ARN was stored as a GitHub secret (`AWS_ROLE_TO_ASSUME`).

5.  **Create the Reusable VPC Module**:
    *   A reusable Terraform module for the VPC was created in `infra/modules/vpc/`.
    *   This module defines the VPC, public/private subnets, Internet Gateway, NAT Gateway, and all necessary route tables.
    *   **Security Features**: Includes VPC flow logging, restricted default security group, and least-privilege IAM roles.

6.  **Use the VPC Module in Environments**:
    *   The `dev`, `staging`, and `prod` environments were updated to use the new VPC module, each with its own unique CIDR block defined in its respective `variables.tf` file.

7.  **Update CI Pipeline for Validation**:
    *   The `infra-ci.yml` workflow was updated to run `terraform plan` within the `dev` environment's directory to validate the module changes in pull requests.
    *   Includes Checkov security scanning with documented exceptions for project-appropriate configurations.

8.  **Implement Manual Infrastructure Destroy Workflow**:
    *   A new workflow, `.github/workflows/infra-destroy.yml`, was created.
    *   This is triggered manually and allows you to run `terraform destroy` on a specific environment (`dev`, `staging`, or `prod`) to manage costs.

9.  **Create Reusable ECR, ALB, ECS, and Bastion Modules**:
    *   **ECR Module**: Created in `infra/modules/ecr/` to manage Elastic Container Registries for the API and frontend applications, including lifecycle policies to manage image retention.
    *   **ALB Module**: Created in `infra/modules/alb/` to set up a secure Application Load Balancer, target groups, and listeners. It handles HTTP to HTTPS redirection and path-based routing for the API and frontend services.
    *   **ECS Module**: Created in `infra/modules/ecs/` to define the ECS cluster, Fargate task definitions, and services for both the API and frontend. It includes IAM roles for task execution and secure integration with the ALB.
    *   **Bastion Module**: Created in `infra/modules/bastion/` to deploy a secure bastion host for emergency access, with a dedicated security group and IAM role with least-privilege permissions.

10. **Enhance CI/CD for Full Deployment and Destruction**:
    *   The `infra-ci-cd.yml` workflow was split into two jobs: `validate-terraform` and `deploy-infra`.
    *   The `validate` job now creates a Terraform plan and uploads it as an artifact.
    *   The `deploy` job, which only runs after a PR is merged into `develop`, downloads the plan artifact and applies it. This ensures that only the approved changes are deployed.
    *   The `infra-destroy.yml` workflow was updated to mirror this best practice, creating a `destroy` plan and applying it in a separate step for predictable and safe infrastructure teardown.

11. **Iterative Hardening and Debugging**:
    *   The `setup_aws_oidc.sh` script was iteratively updated to add missing IAM permissions as they were discovered during workflow runs (e.g., for ECS task definitions, ALB attributes, and instance profiles).
    *   A `cleanup_conflicting_resources.sh` script was created to programmatically delete orphaned AWS resources (like IAM roles and instance profiles) that could block subsequent Terraform runs.
    *   Race conditions in Terraform were resolved by adding explicit `depends_on` clauses between resources, for example, making the ECS services wait for the ALB listeners to be fully configured before attempting to register with them.

12. **Infrastructure Deployment Success and Lessons Learned**:
    *   **ALB Listener Conflicts Resolved**: Fixed the `DuplicateListener` error by implementing conditional listener creation based on SSL certificate availability using Terraform `count` parameters.
    *   **IAM Policy Size Limits**: Split the original large IAM policy into 4 focused policies (S3/IAM, EC2/VPC, ECS/ECR/ALB, Monitoring/AutoScaling) to overcome the 6,144 character limit.
    *   **S3 Backend with Object Lock**: Enhanced the Terraform backend configuration to use S3 Object Lock for state file protection and compliance.
    *   **Terraform Outputs Fix**: Updated ALB module outputs to properly handle count-based resources with array indexing (`aws_lb_listener.http[0].arn`).
    *   **Development Environment Deployed**: Successfully deployed the complete `dev` environment infrastructure including VPC, ECR, ALB, ECS cluster, and Bastion host.
    *   **Best Practice Implementation**: Used a two-stage CI/CD approach (plan → artifact → apply) for safe and auditable infrastructure deployments.

## Module 4.1: S3 Bucket Creation Workaround for Terraform

Due to persistent Terraform S3 bucket creation errors ("empty result"), we adopted a manual bucket creation approach for CI/CD pipeline artifacts and CodeBuild cache:

1. **Manual S3 Bucket Creation Script**
   - Created and ran `scripts_infra/CreateS3BucketsCodePipeline.sh` to provision both buckets:
     - `dev-weather-dashboard-pipeline-artifacts-2025` (for pipeline artifacts)
     - `dev-weather-dashboard-codebuild-cache-2025` (for CodeBuild cache)
   - The script configures versioning, encryption, and public access block for both buckets.

2. **Hardcoded Bucket References in Terraform**
   - Removed all Terraform resources that create or configure these buckets.
   - Updated `infra/environments/dev/main.tf` and `infra/modules/codebuild/main.tf` to reference the bucket names directly:
     ```hcl
     source_bucket_name = "dev-weather-dashboard-codebuild-cache-2025"
     # (and similarly for pipeline artifacts when CodePipeline is enabled)
     ```
   - This avoids the Terraform S3 creation bug and ensures reliable deployments.

3. **Deployment Success**
   - After this change, infrastructure deployment completed successfully via CI/CD pipeline.
   - See PR: https://github.com/AlanJ97/Weather-Dasboard-API/pull/62

**Note:** When enabling CodePipeline, manually create and reference the pipeline artifacts bucket in the same way.

## Module 5: Infrastructure Management and Operations

1.  **Infrastructure State Management**:
    *   All Terraform state is stored in S3 with Object Lock enabled for compliance and protection.
    *   State files are environment-specific with proper locking mechanisms to prevent concurrent modifications.

2.  **Deployment Validation**:
    *   The infrastructure pipeline includes comprehensive validation steps: format checking, security scanning with Checkov, and plan generation with artifact storage.
    *   Manual approval workflows ensure only validated changes reach production environments.

3.  **Cost Management**:
    *   Manual destroy workflows (`infra-destroy.yml`) enable controlled teardown of environments to manage AWS costs during development and training.

## Module 6: Application Development Phase ✅ COMPLETED

1. **FastAPI Backend Development**:
   * Created `app/api/main.py` with weather data endpoints (`/health`, `/api/weather`, `/api/weather/{city}`)
   * Configured proper CORS middleware for frontend communication
   * Implemented structured JSON responses with success/error handling
   * Created `app/api/requirements.txt` with pinned dependencies (FastAPI, Pydantic, Uvicorn)
   * Built `app/api/Dockerfile` with security best practices (non-root user, health checks)

2. **Streamlit Frontend Development**:
   * Created `app/frontend/main.py` with interactive weather dashboard
   * Implemented city selection, temperature charts, and data visualization using Plotly
   * Added responsive design with metrics, tables, and gauges
   * Resolved pandas/plotly installation issues on Windows (compiler dependencies)
   * Created `app/frontend/requirements.txt` with 39 pinned dependencies for reproducible builds
   * Built `app/frontend/Dockerfile` optimized for Python data science libraries

3. **Local Development Environment**:
   * Created `app_scripts/setup-dev.sh` for automated virtual environment setup
   * Created `app_scripts/start.sh` for unified application lifecycle management
   * Implemented `app_scripts/test_applications.py` with comprehensive API and frontend testing
   * Configured per-application virtual environments (`app/api/venv`, `app/frontend/venv`)
   * Added `docker-compose.yml` for local container orchestration

4. **Application Testing and Validation**:
   * ✅ API Health Check: Validates service availability and version information
   * ✅ Weather Endpoints: Tests both single city and all cities data retrieval
   * ✅ API Documentation: Verifies FastAPI automatic documentation accessibility
   * ✅ CORS Configuration: Validates cross-origin request handling
   * ✅ Frontend Availability: Confirms Streamlit dashboard responsiveness
   * **Result**: 5/5 tests passing - applications are production-ready

5. **Dependency Management**:
   * Resolved Python compilation issues (pandas/numpy on Windows without C++ compiler)
   * Implemented pip freeze approach for exact version pinning
   * Created reproducible build environments with locked dependencies
   * Optimized Docker images with appropriate base images and caching

6. **Local Testing Success**:
   * Backend running on http://localhost:8000 with interactive API docs
   * Frontend running on http://localhost:8501 with full dashboard functionality
   * Successful API communication and data visualization
   * All container health checks passing

## Module 7: Complete CI/CD Pipeline Implementation ✅ COMPLETED

**CodeBuild + CodeDeploy + CodePipeline Integration Success**

1. **Progressive CI/CD Module Deployment**:
   * **Phase 1**: Successfully deployed CodeBuild module with manual S3 bucket workaround
   * **Phase 2**: Successfully deployed CodeDeploy module with correct Blue/Green configuration
   * **Phase 3**: Successfully deployed CodePipeline module integrating both services

2. **CodeDeploy Configuration Resolution**:
   * Fixed deployment configuration name from `CodeDeployDefault.ECSAllAtOne` → `CodeDeployDefault.ECSAllAtOneBlueGreen`
   * Verified Blue/Green target group integration with ALB module
   * Confirmed ECS service compatibility with CodeDeploy deployment groups

3. **CodePipeline Integration**:
   * Verified container name consistency between ECS task definitions and CodePipeline expectations:
     - API container: `"weather-api"` ✅
     - Frontend container: `"weather-frontend"` ✅
   * Used hardcoded S3 bucket references: `"dev-weather-dashboard-pipeline-artifacts-2025"`
   * Confirmed proper module dependencies and output references

4. **Complete CI/CD Architecture Deployed**:
   * **CodeStar Connection**: GitHub integration for source code retrieval
   * **CodeBuild**: Docker image building and ECR push
   * **CodeDeploy**: Blue/Green ECS deployments with ALB traffic shifting
   * **CodePipeline**: End-to-end orchestration (Source → Build → Deploy)
   * **S3 Buckets**: Pipeline artifacts and build cache storage

5. **Infrastructure Components Summary**:
   * ✅ VPC with public/private subnets
   * ✅ ECR repositories for API and Frontend
   * ✅ ALB with Blue/Green target groups
   * ✅ ECS Fargate cluster and services
   * ✅ Bastion host for emergency access
   * ✅ Complete CI/CD pipeline (CodeBuild + CodeDeploy + CodePipeline)

## Next Steps (Ready for Implementation)

1. **Pipeline Activation and Testing**:
   * Activate CodeStar GitHub connection in AWS Console (one-time manual step)
   * Create application buildspec.yml files for CodeBuild
   * Test end-to-end pipeline with sample code push

2. **Application Deployment Phase**:
   * Push Docker images to ECR repositories
   * Update ECS task definitions with new image tags  
   * Deploy applications to existing ECS cluster
   * Configure ALB routing to ECS services
   * Update frontend API_BASE_URL to ALB endpoint

3. **Configuration Management**:
   * Ansible playbook development for bastion host configuration
   * Environment-specific configuration management

4. **Production Readiness**:
   * Staging and production environment deployment
   * Monitoring and alerting implementation
   * Load testing and performance optimization