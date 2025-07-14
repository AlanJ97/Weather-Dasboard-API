# Getting Started Guide

This guide provides the steps to set up your local environment to work on the Weather Dashboard API project.

## Prerequisites

Before you begin, ensure you have the following tools installed and configured:

1.  **AWS Account:** You will need an AWS account with appropriate permissions to create and manage resources.
2.  **AWS CLI:** The AWS Command Line Interface is required to interact with your AWS account.
    - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    - After installation, configure it with your credentials by running `aws configure`.
3.  **Terraform:** The infrastructure for this project is managed using Terraform.
    - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
4.  **Ansible:** Ansible is used for configuration management.
    - [Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
5.  **Docker:** The application is containerized using Docker.
    - [Installation Guide](https://docs.docker.com/engine/install/)
6.  **Python:** The backend API is written in Python with FastAPI.
    - [Installation Guide](https://www.python.org/downloads/)
    - It is recommended to use a virtual environment.

## Setup Instructions

1.  **Clone the Repository:**
    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```

2.  **Install Application Dependencies:**
    (Instructions for setting up Python virtual environment and installing packages from `requirements.txt` will go here once the file is created).

3.  **Review the Architecture:**
    Familiarize yourself with the project's architecture by reviewing the diagram in the main `ReadMe.md`.

4.  **Start with Module 1:**
    Begin the training by following the practical steps outlined for Module 1 in the `ReadMe.md`.

### Running Tests Locally

To run unit tests locally:

```bash
pytest
```

Make sure all dependencies are installed and your virtual environment is activated.

### Build and Run the Application Locally with Docker

To build the Docker image:

```bash
docker build -t weather-dashboard-api .
```

To run the container:

```bash
docker run -p 8000:8000 --env-file <your-env-file> weather-dashboard-api
```

Happy coding!
