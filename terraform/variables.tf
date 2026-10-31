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

variable "jenkins_allowed_cidr" {
  description = "Your public IP in CIDR form (e.g. x.x.x.x/32). Allowed to reach Jenkins on ports 8080 and 22"
  type        = string

  validation {
    condition     = can(cidrhost(var.jenkins_allowed_cidr, 0))
    error_message = "jenkins_allowed_cidr must be a valid CIDR block, for example 203.0.113.10/32."
  }
}

variable "cluster_endpoint_public_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint (access still requires valid IAM credentials)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
