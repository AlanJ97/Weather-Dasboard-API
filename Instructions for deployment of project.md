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