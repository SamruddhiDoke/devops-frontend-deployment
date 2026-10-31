variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for the frontend image"
  type        = string
  default     = "taskflow-frontend"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "taskflow-eks"
}

variable "app_namespace" {
  description = "Kubernetes namespace Jenkins is allowed to deploy into"
  type        = string
  default     = "default"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Check supported versions with: aws eks describe-cluster-versions --region ap-south-1"
  type        = string
  default     = "1.37"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for the Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "jenkins_key_name" {
  description = "Name of an EXISTING EC2 key pair in the region, used to SSH into the Jenkins server"
  type        = string
}

variable "cluster_endpoint_public_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint (access still requires valid IAM credentials)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
