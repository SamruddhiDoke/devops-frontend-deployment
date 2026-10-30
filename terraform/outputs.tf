output "ecr_repository_url" {
  description = "ECR repository URL that Jenkins pushes to"
  value       = aws_ecr_repository.frontend.repository_url
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "configure_kubectl" {
  description = "Command to point your local kubectl at the cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "jenkins_url" {
  description = "Jenkins web UI"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_ssh" {
  description = "SSH command for the Jenkins server"
  value       = "ssh -i <path-to-${var.jenkins_key_name}.pem> ubuntu@${aws_instance.jenkins.public_ip}"
}

output "jenkins_role_arn" {
  description = "IAM role used by Jenkins (has EKS edit access in the app namespace)"
  value       = aws_iam_role.jenkins.arn
}
