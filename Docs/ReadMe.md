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
    

## Plan de Desarrollo práctico - Weather Dashboard API

### Módulo 1: Cultura DevOps y metodologías ágiles
- Crear **GitHub Project** con metodología Kanban y épicas bien definidas
- Configurar board: Backlog → In Progress → Review → Done con automation rules

### Módulo 2: Control de versiones
- Crear repositorio con **GitFlow strategy** (main, develop, feature/*, hotfix/*)
- Configurar **branch protection rules** estrictas: required reviews, status checks, signed commits
- Implementar **CODEOWNERS** para reviews obligatorios por área (infra/, app/, docs/)
- Definir **Fork-based workflow** para colaboradores externos y pull request guidelines
- Implementar **GitHub Actions** para auto-merge de dependabot PRs tras validaciones

### Módulo 3: Integración Continua - CI
- Configurar **AWS CodeBuild** como motor principal con múltiples buildspecs
- Implementar **CodePipeline** para orchestration: source → build → test → scan
- **GitHub Actions** como trigger inteligente con pre-flight validations
- **Artifact management**: CodeArtifact para dependencies, S3 para build outputs
- **Parallel builds**: unit tests, security scans, code quality, container builds


### Módulo 4: Infraestructura como Código - IaC
- Crear **archivos Terraform** organizados por servicios: vpc.tf, ecs.tf, alb.tf, s3.tf
- Implementar **workspace strategy**: dev, staging, prod con variables específicas
- Configurar **GitHub Actions** para `terraform plan` en PRs y validation workflows
- **State management**: S3 backend con S3 locking y encryption
- Configurar environments (dev/staging/prod) con variables por ambiente

### Módulo 5: Gestión de configuración - CaC
- Crear **Ansible roles** modulares: app-config, monitoring-setup
- Definir **inventarios dinámicos** desde AWS EC2/ECS y Terraform state
- Implementar **GitHub Actions** para ansible-lint y role validation
- Configurar **Ansible Vault** para secrets management y environment-specific configs
- **Post-deployment configuration**: API warmup, monitoring setup, DNS updates
- **Configuration validation**: health checks y smoke tests



### Módulo 6: Entrega Continua - CD
- Implementar **AWS CodeDeploy** con blue/green y canary deployment strategies
- **CodePipeline orchestration**: automated dev deploys, manual prod approvals
- Configurar **ECS Fargate** deployments con health checks y rollback automático
- **Traffic management**: ALB weighted routing para canary deployments
- **GitHub Actions** para post-deploy monitoring y rollback triggers
- **Environment promotion**: automated testing entre environments

### Módulo 7: Testing automatizado y quality gates
- Implementar **Kitchen-Terraform** para infrastructure testing y validation
- **CodeBuild parallelization**: unit, integration tests
- **SonarCloud integration** via CodeBuild para continuous code quality
- **GitHub CodeQL** para SAST y dependency vulnerability scanning
- **Quality gates enforcement**: bloqueo de deploys por quality issues

### Módulo 8: DevSecOps – Seguridad como código
- **AWS Secrets Manager** para los Keys y Token de las plataformas

### Módulo 9: Observabilidad y monitorización avanzada
- **AWS X-Ray** distributed tracing con service maps
- **Custom metrics**: FastAPI instrumentation con embedded metrics format
- **Alerting strategy**: escalation policies y notification setup
- **Log centralization**: CloudWatch Logs con structured logging

### Módulo 10: Automatización de incidentes
- **PowerShell/Bash scripts** para automated incident response y system recovery
- **AWS Config** con remediation actions y Systems Manager integration
- **Systems Manager Incident Manager** con escalation policies y communication plans
- **EventBridge automation**: event-driven responses y automated scaling

### Módulo 11: Documentación y buenas prácticas de entrega
- **Living documentation**: README auto-generado con terraform-docs
- **GitHub Pages** con Jekyll themes y architectural decision records (ADRs)
- **Draw.io integration** para architectural diagrams versionados en Git
- **MarkdownLint** enforcement en CodeBuild pipeline para consistency

### Aplicación Final
Una **Weather Dashboard API** enterprise-grade que demuestra:
- **FastAPI backend + Streamlit frontend** containerizados en ECS Fargate
- **Full CI/CD pipeline** con CodePipeline orchestrando CodeBuild y CodeDeploy
- **Infrastructure as Code** con Terraform y configuration management con Ansible
- **Security integration** con secrets management
- **Production-ready observability** con monitoring y alerting
- **Professional documentation** y architectural best practices

**Resultado:** Un proyecto completo enfocado en DevOps core competencies que los consultores pueden implementar sin over