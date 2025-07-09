output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "bastion_dns" {
  description = "Public DNS name of the bastion host"
  value       = aws_instance.bastion.public_dns
}

output "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  value       = aws_security_group.bastion.id
}

output "bastion_key_pair_name" {
  description = "Key pair name used by the bastion host"
  value       = aws_key_pair.bastion.key_name
}

output "bastion_iam_role_arn" {
  description = "IAM role ARN of the bastion host"
  value       = aws_iam_role.bastion.arn
}

output "bastion_instance_profile_arn" {
  description = "IAM instance profile ARN of the bastion host"
  value       = aws_iam_instance_profile.bastion.arn
}

output "ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ~/.ssh/${aws_key_pair.bastion.key_name}.pem ec2-user@${aws_eip.bastion.public_ip}"
}

output "bastion_connection_info" {
  description = "Connection information for the bastion host"
  value = {
    public_ip    = aws_eip.bastion.public_ip
    private_ip   = aws_instance.bastion.private_ip
    dns_name     = aws_instance.bastion.public_dns
    key_name     = aws_key_pair.bastion.key_name
    ssh_command  = "ssh -i ~/.ssh/${aws_key_pair.bastion.key_name}.pem ec2-user@${aws_eip.bastion.public_ip}"
    ssh_user     = "ec2-user"
  }
}
