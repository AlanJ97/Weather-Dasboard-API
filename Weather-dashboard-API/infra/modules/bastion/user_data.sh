#!/bin/bash
# User data script for bastion host

# Set up logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update system
yum update -y

# Install essential packages
yum install -y \
    git \
    docker \
    amazon-cloudwatch-agent \
    awscli \
    htop \
    vim \
    curl \
    wget \
    jq \
    unzip

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install kubectl
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.1/2023-04-19/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# Install terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
mv terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform

# Install ansible
amazon-linux-extras install ansible2 -y

# Create useful aliases
cat >> /home/ec2-user/.bashrc << 'EOF'
# Custom aliases for weather dashboard
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias logs='docker logs'
alias dps='docker ps'
alias dim='docker images'
alias tf='terraform'
alias k='kubectl'

# AWS shortcuts
alias aws-whoami='aws sts get-caller-identity'
alias aws-region='aws configure get region'

# ECS shortcuts
alias ecs-clusters='aws ecs list-clusters --output table'
alias ecs-services='aws ecs list-services --cluster ${env}-weather-cluster --output table'
alias ecs-tasks='aws ecs list-tasks --cluster ${env}-weather-cluster --output table'

# Weather dashboard shortcuts
alias weather-logs='aws logs describe-log-groups --log-group-name-prefix /ecs/${env}-weather --output table'
alias weather-status='aws ecs describe-services --cluster ${env}-weather-cluster --services ${env}-weather-api ${env}-weather-frontend --output table'
EOF

# Create monitoring script
cat > /usr/local/bin/weather-monitor << 'EOF'
#!/bin/bash
# Weather dashboard monitoring script

echo "=== Weather Dashboard Status ==="
echo "Environment: ${env}"
echo "Region: ${aws_region}"
echo ""

echo "=== ECS Cluster Status ==="
aws ecs describe-clusters --clusters ${env}-weather-cluster --query 'clusters[0].{Name:clusterName,Status:status,RunningTasks:runningTasksCount,ActiveServices:activeServicesCount}' --output table

echo ""
echo "=== ECS Services Status ==="
aws ecs describe-services --cluster ${env}-weather-cluster --services ${env}-weather-api ${env}-weather-frontend --query 'services[].{Name:serviceName,Status:status,Desired:desiredCount,Running:runningCount,Pending:pendingCount}' --output table

echo ""
echo "=== Recent ECS Tasks ==="
aws ecs list-tasks --cluster ${env}-weather-cluster --max-items 10 --query 'taskArns' --output table

echo ""
echo "=== Load Balancer Status ==="
aws elbv2 describe-load-balancers --names ${env}-weather-alb --query 'LoadBalancers[0].{Name:LoadBalancerName,State:State.Code,DNS:DNSName}' --output table

echo ""
echo "=== Target Groups Health ==="
aws elbv2 describe-target-groups --names ${env}-weather-api-tg ${env}-weather-frontend-tg --query 'TargetGroups[].{Name:TargetGroupName,Health:HealthyHostCount,Port:Port}' --output table
EOF

chmod +x /usr/local/bin/weather-monitor

# Create log rotation for user data
cat > /etc/logrotate.d/user-data << 'EOF'
/var/log/user-data.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0644 root root
}
EOF

# Set environment variables
echo "export AWS_DEFAULT_REGION=${aws_region}" >> /home/ec2-user/.bashrc
echo "export ENV=${env}" >> /home/ec2-user/.bashrc

# Signal that user data is complete
/opt/aws/bin/cfn-signal -e $? --stack ${env}-weather-bastion --resource BastionHost --region ${aws_region} || true

echo "Bastion host setup complete!"
