#
# Outputs
#

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

output "aws_iam_role_eks_node" {
  value = "${aws_iam_role.eks-test-node.arn}"
}

resource "local_file" "kubectl-config" {
    content     = "${local.kubeconfig}"
    filename = "yaml/kubectl-config.yaml"
}
