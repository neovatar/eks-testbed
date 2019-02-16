variable "aws_profile" {
  description = "This aws profile will be used for the terraform aws provider"
  type = "string"
}

variable "aws_region" {
  description = "This aws region will be used when creating resources with terraform"
  type = "string"
}

variable "dns_route53_hosted_domain" {
  description = "A DNS domain that is served by route53 in your AWS account"
  type = "string"
}

variable "env" {
  description = "This is the environment of your config, so that you can have the same infrastructure for multiple environments e.g. dev, stage, prod"
  type = "string"
}

variable "eks_cluster_name" {
  description = "Name of your EKS cluster"
  type = "string"
  default = "eks"
}

variable "ssh_admin_pubkey_path" {
  description = "Path to ssh key that will be able to log into EKS nodes EC2 instances"
  type = "string"
  default = "~/.ssh/id_rsa.pub"
}

variable "tfstate_dynamodb" {
  description = "The name of the dynamodb that terraform will use for state locking information"
  type = "string"
}

variable "tfstate_s3" {
  description = "The s3 bucket that terraform will use for storing its state"
  type = "string"
}
