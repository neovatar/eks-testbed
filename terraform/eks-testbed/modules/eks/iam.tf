#
# The below is an IAM role and policy to allow the EKS service to manage or retrieve data from other AWS services
#
# Before you can create an Amazon EKS cluster, you must create an IAM role that Kubernetes can assume to create AWS resources.
# For example, when a load balancer is created, Kubernetes assumes the role to create an Elastic Load Balancing load balancer in your account.
# This only needs to be done one time and can be used for multiple EKS clusters.
#
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