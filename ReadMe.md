#### Temario lineal para “AWS DevOps Engineer – Professional” 

1. Módulo 1: Cultura DevOps y metodologías ágiles  
    - AWS Well-Architected DevOps Lens  
    - GitHub Projects & Issues  
    - GitHub Discussions  

2. Módulo 2: Control de versiones 
    - GitHub
    - Branch strategies
    - Branch policies
    - PR/Fork
    - GitHub Actions

3. Módulo 3: Integración Continua - CI
    - GitHub Actions
    - CodeBuild
    - CodePipeline

4. Módulo 4: Infraestructura como Código  - IaC
    - Terraform
    - GitHub Actions

5. Módulo 5: Gestión de configuración - CaC
    - Ansible
    - GitHub Actions


6. Módulo 6: Entrega Continua y estrategias de despliegue - CD
    - GitHub Actions
    - CodeDeploy

7. Módulo 7: Testing automatizado y quality gates
    - GitHub Actions
    - Checkov y terratest
    - GitHub CodeQL
    - SonarCloud

8. Módulo 8: DevSecOps – Seguridad como código  
    - AWS KMS
    - AWS Secrets Manager

9. Módulo 9: Observabilidad y monitorización avanzada  
    - AWS CloudWatch X-Ray

10. Módulo 10: Automatización de incidentes 
    - Bash/PowerShell
    - AWS Config
    - AWS Systems Manager Incident Manager 

11. Módulo 11: Documentación y buenas prácticas de entrega
    - Readme Files
		* Markdown Language
        * MarkdownLint
        * GitHub Pages

	- Diagramas
		* Draw.io
        * Mermaid
    

## Weather Dashboard API: A Practical DevOps Project

This project is the practical component of the "AWS DevOps Engineer – Professional" training. It is an enterprise-grade Weather Dashboard API designed to provide hands-on experience with a full CI/CD pipeline, Infrastructure as Code, DevSecOps, and advanced observability.

### Architecture Overview

Below is the high-level architecture for the Weather Dashboard API. It illustrates how the different components (FastAPI backend, Streamlit frontend, AWS services) interact.

![DevOps Architecture](Arquitectura%20DevOps%20Demo.png)

**Note:** The diagram above was created using Mermaid. You can find the source code in the [devops-architecture.mermaid](./devops-architecture.mermaid) file. To edit or view it, you can use an online editor like [Mermaid Mind](https://mermaid-mind.vercel.app/).

### Getting Started

For instructions on how to set up your local environment and get the project running, please refer to the [Getting Started Guide](./getting-started.md).

If you run into any issues, please consult the [Troubleshooting Guide](./troubleshooting-guide.md).

## Plan de Desarrollo práctico - Weather Dashboard API

### Módulo 1: Cultura DevOps y metodologías ágiles
- Crear **GitHub Project** con metodología Kanban y épicas bien definidas para el proyecto.
- Configurar el tablero con columnas (Backlog → In Progress → Review → Done) y automatizaciones.

### Módulo 2: Control de versiones
- Crear el repositorio con una **estrategia GitFlow** (main, develop, feature/*).
- Configurar **reglas de protección de ramas** para `main` y `develop`.
- Implementar **CODEOWNERS** para asignar revisiones obligatorias por directorios (`infra/`, `app/`, `docs/`).

### Módulo 3: Integración Continua - CI
- **Pipeline de Infraestructura (GitHub Actions):**
    - Configurar un workflow que se dispare ante cambios en el directorio `infra/`.
    - Ejecutará los pasos de validación y plan de Terraform.
- **Pipeline de Aplicación (AWS CodePipeline):**
    - Orquestar el flujo completo: Source (GitHub) → Build (CodeBuild) → Test (CodeBuild/Ansible) → Deploy (CodeDeploy).
    - Configurar **AWS CodeBuild** como el motor de compilación:
        - Crear un directorio `scripts/` para almacenar scripts de automatización.
        - Implementar un script `build.sh` que se encargue de construir la imagen Docker, etiquetarla y subirla a ECR.
        - El `buildspec.yml` simplemente invocará a este script, manteniendo la definición de la build limpia y la lógica centralizada.
    - Gestionar los **artefactos de compilación** (imágenes Docker) en **Amazon ECR**.
- Asegúrate de que el repositorio de la aplicación incluya un `Dockerfile` y un `requirements.txt` para facilitar la construcción y despliegue de los contenedores.

### Módulo 4: Infraestructura como Código - IaC
- **Estructura recomendada de Terraform:**
    - Crear un directorio `modules/` para componentes reutilizables (VPC, ECS, ALB, Security Groups, Bastion Host, etc.).
    - Crear un directorio `environments/` con subcarpetas para cada entorno (`dev/`, `staging/`, `prod/`). Cada entorno tendrá su propia configuración y variables, y referenciará los módulos reutilizables.
    - Ejemplo:
      ```
      infra/
        modules/
          vpc/
          ecs/
          alb/
          bastion/
        environments/
          dev/
            main.tf
            variables.tf
            backend.tf      
          staging/
            main.tf
            variables.tf
            backend.tf
          prod/
            main.tf
            variables.tf
            backend.tf
      ```
- **Terraform para la Infraestructura Principal:**
    - Definir la infraestructura usando módulos reutilizables.
    - Configurar el **backend de S3** para el versionado y bloqueo del estado (`tfstate`) usando el locking nativo de S3 (no se requiere DynamoDB).
    - Usar **workspaces** para gestionar los diferentes entornos (dev, staging, prod) si se requiere aislamiento adicional.
- **Terraform para el Testing de Aceptación:**
    - Añadir un módulo de Terraform para **provisionar una instancia EC2 temporal (Bastion Host)** durante la fase de testing de la pipeline de aplicación.

### Módulo 5: Gestión de configuración - CaC
- **Ansible para la Configuración del Bastion Host:**
    - Crear un **rol de Ansible** para configurar el Bastion Host provisionado por Terraform.
    - El playbook se encargará de:
        - Instalar las herramientas necesarias para el testing (e.g., `pytest`, `requests`, `curl`).
        - Clonar el repositorio para obtener los scripts de prueba de aceptación.
        - Ejecutar el set de pruebas contra el endpoint interno de la aplicación desplegada en Staging.
- **Ansible Vault:** Utilizarlo para gestionar cualquier secreto necesario durante la fase de testing.

### Módulo 6: Entrega Continua y estrategias de despliegue - CD
- **AWS CodeDeploy para la Aplicación:**
    - Implementar una estrategia de despliegue **Blue/Green** para los servicios en ECS Fargate.
    - Configurar **health checks** y **políticas de rollback automático** para garantizar despliegues seguros.
- **Orquestación con CodePipeline:**
    - Automatizar los despliegues al entorno de `dev`.
    - Configurar una **etapa de aprobación manual** para promover los despliegues a `staging` y `production`.

### Módulo 7: Testing automatizado y quality gates
- **Pipeline de Infraestructura:**
    - Integrar **Checkov** como quality gate para escanear el código de Terraform en busca de vulnerabilidades y desviaciones de buenas prácticas.
- **Pipeline de Aplicación:**
    - Ejecutar **pruebas unitarias** con `pytest` en la etapa de Build.
    - Integrar **SonarCloud** y **GitHub CodeQL** para análisis de calidad de código (SAST) como un quality gate obligatorio.
    - Ejecutar las **pruebas de aceptación** desde el Bastion Host como el quality gate final antes de la aprobación para producción.

### Módulo 8: DevSecOps – Seguridad como código
- **AWS Secrets Manager:** Centralizar y gestionar de forma segura todos los secretos (tokens, API keys, etc.) que necesita la aplicación y la pipeline.
- **IAM Roles:** Definir roles con el principio de mínimo privilegio para cada componente (CodePipeline, CodeBuild, ECS Task Role).
- **Gestión de variables y secretos:** Todas las variables de entorno y secretos requeridos por la aplicación y pipelines deben gestionarse de forma centralizada usando **AWS Secrets Manager** o **GitHub Secrets**. Esto aplica tanto para entornos de desarrollo como de producción, garantizando seguridad y consistencia.

### Módulo 9: Observabilidad y monitorización avanzada
- **Amazon CloudWatch:**
    - Configurar **Logs** para centralizar los logs de la aplicación (FastAPI/Streamlit) y el ALB.
    - Crear **Métricas y Alarmas** para monitorear la salud del servicio en ECS (CPU, Memoria) y el ALB (peticiones 5xx).
- **AWS X-Ray:** Instrumentar la aplicación FastAPI para obtener trazas distribuidas y analizar el rendimiento.

### Módulo 10: Automatización de incidentes
- **AWS Config:** Implementar reglas para auditar la conformidad de la configuración de los recursos (e.g., "los Security Groups no deben tener el puerto 22 abierto a todo el mundo"). Su rol es detectar desviaciones de las buenas prácticas.



### Módulo 11: Documentación y buenas prácticas de entrega
- **README.md:** Mantenerlo como la fuente central de información del proyecto.
- **Diagramas:** Versionar el diagrama de arquitectura (`devops-architecture.mermaid`) junto con el código.
- **MarkdownLint:** Integrar un linter en la pipeline para asegurar la calidad y consistencia de la documentación en Markdown.

### Aplicación Final
Una **Weather Dashboard API** enterprise-grade que demuestra:
- **FastAPI backend + Streamlit frontend** containerizados en ECS Fargate
- **Full CI/CD pipeline** con CodePipeline orchestrando CodeBuild y CodeDeploy
- **Infrastructure as Code** con Terraform y configuration management con Ansible
- **Security integration** con secrets management
- **Production-ready observability** con monitoring y alerting
- **Professional documentation** y architectural best practices

**Resultado:** Un proyecto completo enfocado en DevOps core competencies que los consultores pueden implementar sin overthinking.

## How to Contribute

1. Haz un fork del repositorio y crea una rama para tu feature o fix.
2. Realiza tus cambios y abre un Pull Request hacia la rama `develop`.
3. Asegúrate de que todas las pipelines pasen y que la documentación esté actualizada.

## Ejemplos de Resultados

Incluye capturas de pantalla de:
- Un pipeline exitoso en GitHub Actions/CodeBuild.
- El dashboard desplegado en AWS.
- Un reporte de SonarCloud o CodeQL.