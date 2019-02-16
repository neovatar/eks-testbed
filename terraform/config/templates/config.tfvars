#
# AWS aprovider specific configuration
#
aws_profile = "${aws_profile}"
aws_region = "${aws_region}"

#
# Terraform backend configuration
#
tfstate_s3 = "${tfstate_s3}"
tfstate_dynamodb = "${tfstate_dynamodb}"

#
# Global configuration
#
env = "${env}"
ssh_admin_pubkey_path = "${ssh_admin_pubkey_path}"

#
# DNS configuration
#
dns_route53_hosted_domain = "${dns_route53_hosted_domain}"

#
# EKS configuration
#
eks_cluster_name = "${eks_cluster_name}"

