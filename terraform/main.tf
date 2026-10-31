data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_ec2_tag" "public_elb" {
  for_each    = toset(data.aws_subnets.default.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

#############################
# Amazon ECR repository

resource "aws_ecr_repository" "frontend" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  # Allows `terraform destroy` to delete the repository even if it still has images
  force_delete = true
}

#######################################
# IAM role for the EKS control plane

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

###################
# EKS cluster


resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids

    # Public endpoint: lets run kubectl from laptop.
    # Private endpoint: Jenkins and the nodes (inside the VPC) reach the API privately.
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = var.cluster_endpoint_public_cidrs
  }

  # Use EKS access entries to grant cluster access.
  # The IAM identity that runs `terraform apply` becomes cluster admin.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Avoid paid "extended support" when the version gets old
  upgrade_policy {
    support_type = "STANDARD"
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

#####################################################
# IAM role and managed node group for worker nodes

resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Lets nodes pull the frontend image from ECR
resource "aws_iam_role_policy_attachment" "eks_ecr_read_only" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = data.aws_subnets.default.ids

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = [var.node_instance_type]
  disk_size      = 20

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = 1
    max_size     = var.node_desired_size + 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_read_only,
  ]
}

###############################################################################
# IAM role for Jenkins (attached to the Jenkins EC2 instance)


resource "aws_iam_role" "jenkins" {
  name = "${var.cluster_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Only what the Jenkinsfile needs: push to one ECR repo and describe one EKS cluster
resource "aws_iam_role_policy" "jenkins" {
  name = "${var.cluster_name}-jenkins-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
        ]
        Resource = aws_ecr_repository.frontend.arn
      },
      {
        Sid      = "EksDescribe"
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = aws_eks_cluster.main.arn
      },
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.cluster_name}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

###############################################################################
# EKS access for Jenkins: edit rights in the app namespace, plus read-only
# access to nodes (AWS access policies have no node permissions, so this uses
# the Kubernetes group bound in k8s/jenkins-node-reader.yaml)
###############################################################################

resource "aws_eks_access_entry" "jenkins" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = aws_iam_role.jenkins.arn
  type              = "STANDARD"
  kubernetes_groups = ["jenkins-node-readers"]
}

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.jenkins.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [var.app_namespace]
  }

  depends_on = [aws_eks_access_entry.jenkins]
}

##########################
# Jenkins EC2 instance

resource "aws_security_group" "jenkins" {
  name        = "${var.cluster_name}-jenkins-sg"
  description = "Jenkins server access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Jenkins web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound (GitHub, ECR, EKS, package repos)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jenkins reaches the EKS private endpoint, so allow HTTPS from Jenkins
# into the security group that EKS created for the cluster.
resource "aws_vpc_security_group_ingress_rule" "eks_api_from_jenkins" {
  security_group_id            = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.jenkins.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "EKS API from Jenkins"
}


data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.jenkins_instance_type
  subnet_id                   = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  key_name                    = var.jenkins_key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # Installs Java, Git, Docker, AWS CLI v2, kubectl and Jenkins on first boot.
  # Progress log on the instance: /var/log/cloud-init-output.log
  user_data = <<-EOF
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive

    # Java 21 (required by Jenkins), Git, Docker and tools used below
    apt-get update
    apt-get install -y fontconfig openjdk-21-jre-headless git docker.io curl unzip
    systemctl enable --now docker

    # AWS CLI v2 (official installer, installs to /usr/local/bin/aws)
    curl -fsSL -o /tmp/awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    # kubectl matching the EKS minor version
    KVER=$(curl -fsSL https://dl.k8s.io/release/stable-${var.kubernetes_version}.txt)
    curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$KVER/bin/linux/amd64/kubectl"
    chmod +x /usr/local/bin/kubectl

    # Jenkins LTS from the official repository
    mkdir -p /etc/apt/keyrings
    curl -fsSL -o /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
    apt-get update
    apt-get install -y jenkins

    # Let Jenkins run docker; restart so the new group takes effect
    usermod -aG docker jenkins
    systemctl enable jenkins
    systemctl restart jenkins
  EOF

  # A newer Ubuntu AMI or an edited install script would otherwise make every
  # later `terraform apply` rebuild Jenkins and wipe its setup. To rebuild on
  # purpose, run: terraform apply -replace="aws_instance.jenkins"
  lifecycle {
    ignore_changes = [ami, user_data]
  }

  tags = {
    Name = "${var.cluster_name}-jenkins"
  }
}
