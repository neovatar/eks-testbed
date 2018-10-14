# output "config_map_aws_auth" {
#   value = "${local.config_map_aws_auth}"
# }

# output "kubectl_config" {
#   value = "${local.kubectl_config}"
# }

output "aws_iam_role_eks_node" {
  value = "${aws_iam_role.eks_node.*.name}"
}