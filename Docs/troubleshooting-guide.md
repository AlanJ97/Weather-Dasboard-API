# Troubleshooting Guide

This document lists common issues that you might encounter during the training and their solutions.

## General Issues

- **Issue:** AWS CLI commands are not working.
  - **Solution:** Ensure that the AWS CLI is installed correctly and that your credentials have been configured using `aws configure`. Verify that the credentials have the necessary permissions.

- **Issue:** Terraform commands fail with authentication errors.
  - **Solution:** Make sure your AWS CLI is configured correctly, as Terraform uses it for authentication. Check that your IAM user or role has the required permissions for creating the resources defined in the `.tf` files.

## Application Issues

- **Issue:** Python dependencies fail to install.
  - **Solution:** Ensure you are using a supported version of Python and that you have activated a virtual environment before running `pip install`.

- **Issue:** Docker build fails.
  - **Solution:** Check the Dockerfile for any syntax errors. Ensure that Docker is running and that you have sufficient permissions to run Docker commands.

## Security/Static Analysis Issues

- **Issue:** Checkov scan fails.
  - **Solution:** Revisa los mensajes de error para identificar recursos inseguros o configuraciones no recomendadas. Corrige el código Terraform según las recomendaciones.

- **Issue:** SonarCloud reporta vulnerabilidades o problemas de calidad.
  - **Solution:** Analiza los reportes y corrige los problemas de seguridad o calidad en el código fuente.

## Ansible/Bastion Host Issues

- **Issue:** El playbook de Ansible falla al configurar el Bastion Host.
  - **Solution:** Verifica la conectividad SSH, las variables de entorno y los permisos necesarios en la instancia EC2.

- **Issue:** Las pruebas de aceptación desde el Bastion Host no pasan.
  - **Solution:** Asegúrate de que la aplicación esté desplegada y accesible desde el Bastion Host. Revisa los logs de Ansible y de la aplicación.

## Deployment Issues

- **Issue:** CodeDeploy deployment fails.
  - **Solution:** Check the CodeDeploy agent logs on the target instances for detailed error messages. Verify that the IAM roles for CodeDeploy and the EC2 instances have the correct policies attached.

- **Issue:** The application is not accessible after deployment.
  - **Solution:** Check the security groups and network ACLs to ensure that traffic is allowed on the required ports. Verify that the application is running correctly by checking the logs.

## CI/CD Pipeline Issues

- **Issue:** Una pipeline falla en GitHub Actions, CodeBuild o CodeDeploy.
  - **Solution:** Consulta los logs detallados de la ejecución en la plataforma correspondiente para identificar el paso y el error exacto.
