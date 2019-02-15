# Get our EKS cluster resource information
data "aws_eks_cluster" "eks_cluster" {
  name = "${var.eks_cluster_id}"
}

# Get security group of our nodes
data "aws_security_group" "eks_nodes" {
  name = "${var.eks_cluster_id}-nodes"
}

# Current aws region
data "aws_region" "current" {}
