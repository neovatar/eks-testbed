#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#  * kubectl config
#  * config map to map node iam to k8s RBAC

resource "aws_iam_role" "eks-test-cluster" {
  name = "eks-test-cluster"

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

resource "aws_iam_role_policy_attachment" "eks-test-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-test-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "eks-test-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-test-cluster.name}"
}

resource "aws_security_group" "eks-test-cluster" {
  name        = "eks-test-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.eks-test.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "eks-demo"
  }
}

resource "aws_security_group_rule" "eks-test-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-test-cluster.id}"
  source_security_group_id = "${aws_security_group.eks-test-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_eks_cluster" "eks-test" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.eks-test-cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eks-test-cluster.id}"]
    subnet_ids         = ["${aws_subnet.eks-test.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-test-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-test-cluster-AmazonEKSServicePolicy",
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
    - rolearn: ${aws_iam_role.eks-test-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks-test.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks-test.certificate_authority.0.data}
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
        - "${var.cluster-name}"
      env:
        - name: AWS_PROFILE
          value: "seligerit"
KUBECONFIG
}


resource "local_file" "config-map-aws-auth" {
    content     = "${local.config_map_aws_auth}"
    filename = "yaml/config-map-aws-auth.yaml"
    depends_on = ["local_file.kubectl-config"]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=yaml/kubectl-config.yaml apply -f yaml/config-map-aws-auth.yaml"
  }
}
