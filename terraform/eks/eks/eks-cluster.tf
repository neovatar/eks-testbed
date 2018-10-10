#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#  * kubectl config
#  * config map to map node iam to k8s RBAC

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks_cluster.name}"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks_cluster.name}"
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "EKS cluster ${var.cluster_name} communication with worker nodes"
  vpc_id      = "${var.cluster_vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.cluster_name}"
  }
}

resource "aws_security_group_rule" "eks_cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_cluster.id}"
  source_security_group_id = "${aws_security_group.eks_nodes.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.cluster_name}"
  role_arn = "${aws_iam_role.eks_cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eks_cluster.id}"]
    subnet_ids         = ["${var.cluster_subnets_ids}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy",
  ]
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${aws_iam_role.eks_node_kiam_server.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks_cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks_cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster_name}"
      env:
        - name: AWS_PROFILE
          value: "seligerit"
KUBECONFIG
}

resource "local_file" "kubectl_config" {
    content     = "${local.kubeconfig}"
    filename = "yaml/kubectl-config.yaml"
}

resource "local_file" "config_map_aws_auth" {
    content     = "${local.config_map_aws_auth}"
    filename = "yaml/config-map-aws-auth.yaml"
    depends_on = ["local_file.kubectl_config"]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=yaml/kubectl-config.yaml apply -f yaml/config-map-aws-auth.yaml"
  }
}
