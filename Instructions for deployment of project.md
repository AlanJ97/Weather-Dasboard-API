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
