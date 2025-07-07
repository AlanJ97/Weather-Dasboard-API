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
