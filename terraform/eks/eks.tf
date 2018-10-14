data "aws_iam_policy_document" "eks_kiam_server" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::059300324029:role/kiam-server"]
  }
}

resource "aws_iam_policy" "eks_kiam_server" {
  name = "${local.cluster_name}-kiam-server"
  policy = "${data.aws_iam_policy_document.eks_kiam_server.json}"
}

resource "aws_iam_role_policy_attachment" "eks_kiam_server" {
  policy_arn = "${aws_iam_policy.eks_kiam_server.arn}"
  role = "${module.eks.aws_iam_role_eks_node[1]}"
}

module "eks" {
    source = "./eks"

    aws_profile = "${local.aws_profile}"
    cluster_name = "${local.cluster_name}"
    cluster_vpc_id = "${aws_vpc.eks-test.id}"
    cluster_subnets_ids = "${aws_subnet.eks-test.*.id}"
    ssh_admin_key_name = "${aws_key_pair.admin.key_name}"
    worker_groups = "${local.worker_groups}"

    providers = {
      "aws" = "aws.eks"
    }
}