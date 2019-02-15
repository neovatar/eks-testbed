# IAM role and policies to allow worker nodes to:
#  - join cluster
#  - manage and retrieve data from other AWS services
data "aws_iam_policy_document" "eks_node" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Assume role policy
resource "aws_iam_role" "eks_node" {
  name = "${data.aws_eks_cluster.eks_cluster.name}-node-${var.worker_group_name}"
  assume_role_policy = "${data.aws_iam_policy_document.eks_node.json}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = "${aws_iam_role.eks_node.name}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = "${aws_iam_role.eks_node.name}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = "${aws_iam_role.eks_node.name}"
}

resource "aws_iam_policy" "node-group-additional-policy" {
  count = "${var.additional_policy_document_json != "" ? 1 : 0}"
  name = "additionalPolicy-${var.worker_group_name}"
  description = "Additional policies for worker group ${var.worker_group_name}"
  policy = "${var.additional_policy_document_json}"
}

resource "aws_iam_role_policy_attachment" "eks_node-additional-policies" {
  count = "${var.additional_policy_document_json != "" ? 1 : 0}"
  policy_arn = "${aws_iam_policy.node-group-additional-policy.arn}"
  role = "${aws_iam_role.eks_node.name}"
}
