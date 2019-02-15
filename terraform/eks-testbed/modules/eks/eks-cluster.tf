#
# Creates EKS cluster
#
# For detailed information see the EKS User Guide:
#  https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html
#
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

