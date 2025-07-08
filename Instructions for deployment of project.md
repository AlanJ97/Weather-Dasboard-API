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
    *   Tasks are added to the `Backlog` as issues and moved across the board to track progress.

4.  **Configure GitFlow Branching Strategy:**
    *   The `develop` branch was created from the `master` branch to serve as the primary integration branch.
    *   Command used: `git checkout -b develop` followed by `git push -u origin develop`.

5.  **Set Up Branch Protection Rules:**
    *   Protection rules were configured for both the `master` and `develop` branches in the repository settings (`Settings` > `Branches`).
    *   **Rules Applied:**
        *   "Require a pull request before merging" is enabled.
        *   "Require approvals" is enabled and set to `1`.
    *   **Note:** The "Require status checks to pass" option will be configured later, once the CI pipelines are in place.

6.  **Implement CODEOWNERS:**
    *   The `.github/CODEOWNERS` file was created and configured to automatically assign reviewers for pull requests based on the directory being changed.
    *   This enforces that the right people review changes to the `app/`, `infra/`, and `docs/` directories.
    *   **Note on Self-Approval:** By default, PR authors cannot approve their own PRs. As a solo administrator, the "Merge without waiting for requirements to be met (bypass rules)" option must be used to merge changes.

## Module 3: Continuous Integration (CI)

1.  **Create Initial Infrastructure Pipeline:**
    *   Created the workflow file at `.github/workflows/infra-ci.yml`.
    *   The workflow is configured to trigger on pushes or pull requests to the `develop` branch that affect the `infra/` directory.
    *   **Initial Steps:**
        *   Checks out the code.
        *   Sets up a specific version of Terraform.
        *   Runs `terraform init` to initialize the configuration.
        *   Runs `terraform fmt -check` to ensure code is formatted correctly.
        *   Runs `terraform validate` to check the syntax of the Terraform files.
        *   Runs `checkov` using the `bridgecrewio/checkov-action@v12` action to perform a security scan of the IaC.

2.  **Create Initial Application Pipeline:**
    *   Created the workflow file at `.github/workflows/app-ci.yml`.
    *   The workflow is configured to trigger on pushes or pull requests to the `develop` branch that affect the `app/` directory.
    *   **Initial Steps:**
        *   Checks out the code.
        *   Sets up Python.
        *   Installs application and testing dependencies (`flake8`, `pytest`).
        *   Runs `flake8` to lint the Python code.
        *   Includes a placeholder step for running `pytest`.

## Workflow Trigger Debugging

1.  **Diagnose Workflow Trigger Issue:**
    *   **Problem:** After creating the initial CI pipelines, it was observed that the GitHub Actions workflows were not being triggered on pull requests.
    *   **Diagnosis:** The `.github/workflows` directory was incorrectly placed inside the `Weather-dashboard-API/` subfolder. GitHub requires this directory to be at the root of the repository to automatically discover and run workflows.

2.  **Correct Workflow Path:**
    *   The `.github` directory was moved from `c:\Users\AlanSegundo\OneDrive - SPS\Capacitaciones SPS\AWS DevOps Profesional\Weather-dashboard-API\.github` to the repository root `c:\Users\AlanSegundo\OneDrive - SPS\Capacitaciones SPS\AWS DevOps Profesional\.github`.
    *   The `paths` and `working-directory` configurations in `infra-ci.yml` and `app-ci.yml` were updated to remove the `Weather-dashboard-API/` prefix, aligning them with the new root location.

3.  **Resolve Git Push Authentication Error:**
    *   **Problem:** When attempting to push the updated workflow files, Git returned a `remote rejected` error.
    *   **Error Message:** `refusing to allow a Personal Access Token to create or update workflow '.github/workflows/app-ci.yml' without 'workflow' scope`.
    *   **Diagnosis:** This security measure prevents Personal Access Tokens (PATs) from modifying workflow files without explicit permission. The fine-grained token being used lacked the `workflow` scope.
    *   **Resolution:**
        *   Navigated to **GitHub Settings** > **Developer settings** > **Personal access tokens** > **Fine-grained tokens**.
        *   Edited the token used for this repository.
        *   Under the **Permissions** tab, located the **Repository permissions** section.
        *   Granted `Read and write` access for the `Contents` permission and ensured the `workflow` scope was included by granting `Read and write` access to **Actions**.
        *   Saved the changes to the token.
    *   After updating the token, the `git push` command completed successfully.

## Module 4: Foundational Infrastructure with Terraform

### Objective
Define and provision the core network infrastructure (VPC, subnets, etc.) using a reusable Terraform module.

### Steps

1.  **Create the VPC Module**:
    *   In `infra/modules/vpc/`, create `main.tf`, `variables.tf`, and `outputs.tf`.
    *   **`main.tf`**: Define the core VPC resources:
        *   `aws_vpc`
        *   Public and private `aws_subnet`s
        *   `aws_internet_gateway`
        *   `aws_nat_gateway` with an `aws_eip`
        *   Public and private `aws_route_table`s and associations.
    *   **`variables.tf`**: Define input variables (`env`, `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`, `aws_region`).
    *   **`outputs.tf`**: Define outputs (`vpc_id`, `public_subnet_ids`, `private_subnet_ids`).

2.  **Use the VPC Module in Environments**:
    *   Update `infra/environments/dev/main.tf` to use the `vpc` module.
    *   Create `infra/environments/dev/variables.tf` to provide values for the VPC module, including a unique CIDR block (e.g., `10.0.0.0/16`).
    *   Repeat for the `staging` and `prod` environments, ensuring each has a unique CIDR block (e.g., `10.1.0.0/16` for staging, `10.2.0.0/16` for prod).

3.  **Update CI Pipeline for Validation**:
    *   Modify `.github/workflows/infra-ci.yml` to run `terraform plan` on the `dev` environment. This validates the new module and its integration before any deployment.

4.  **Configure Terraform S3 Backend:**
    *   **Goal:** To store the Terraform state file (`.tfstate`) remotely in a secure and versioned S3 bucket.
    *   Created `backend.tf` files in each environment directory (`infra/environments/dev`, `staging`, `prod`).
    *   Each file was configured to use the `weather-app-backend-terraform-bucket-2025` S3 bucket, with a unique key for each environment (e.g., `dev/terraform.tfstate`).

5.  **Automate Backend Creation:**
    *   To make the S3 bucket setup repeatable, the `scripts/setup_terraform_backend.sh` script was created.
    *   This script automates the creation of the S3 bucket and enables versioning on it using the AWS CLI.

6.  **Handle Line Endings for Cross-Platform Compatibility:**
    *   **Problem:** A `LF will be replaced by CRLF` warning appeared when adding shell scripts on Windows.
    *   **Solution:** A `.gitattributes` file was created in the root directory to enforce that all `.sh` files use Unix-style LF line endings, ensuring they are runnable in the Linux-based GitHub Actions environment.

7.  **Enable Secure AWS Authentication from GitHub Actions (OIDC):**
    *   **Problem:** The `terraform init` step in the CI pipeline failed because the GitHub runner lacked AWS credentials to access the S3 backend.
    *   **Solution:** Configured a secure, passwordless connection between GitHub Actions and AWS using OpenID Connect (OIDC).
    *   **Workflow Update:** The `aws-actions/configure-aws-credentials@v4` action was added to the `infra-ci.yml` workflow.
    *   **Automation Script:** The `scripts/setup_aws_oidc.sh` script was created to automate the entire AWS-side configuration. This script:
        *   Creates the OIDC Identity Provider in IAM to trust GitHub.
        *   Creates an IAM Role with a trust policy scoped specifically to the `develop` branch of the `Weather-Dasboard-API` repository.
        *   Creates and attaches an IAM policy granting the role the necessary S3 permissions for the Terraform backend.
    *   **Final Step:** The ARN of the created IAM role was added as a secret named `AWS_ROLE_TO_ASSUME` in the GitHub repository settings. This allowed the workflow to assume the role and successfully initialize the Terraform backend.
