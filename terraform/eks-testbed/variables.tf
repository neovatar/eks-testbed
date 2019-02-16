variable "aws_profile" {
  type = "string"
}

variable "aws_region" {
  type = "string"
}

variable "eks_cluster_name" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "dns_route53_hosted_domain" {
  type = "string"
}

variable "ssh_admin_pubkey_path" {
  type = "string"
}

variable "tfstate_dynamodb" {
  type = "string"
}

variable "tfstate_s3" {
  type = "string"
}

