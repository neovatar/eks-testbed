variable "additional_policy_document_json" {
  type = "string"
  default = ""
}

variable "aws_profile" {
  type = "string"
}

variable "aws_eks_ami_id" {
  type = "string"
}

variable "cluster_subnets_ids" {
  type = "list"
}

variable "desired_capacity" {
  type = "string"
}

variable "instance_type" {
  type ="string"
}

variable "max_size" {
  type = "string"
}

variable "min_size" {
  type = "string"
}

variable ssh_admin_key_name {
  type = "string"
}

variable "eks_cluster_id" {
  type = "string"
}

variable worker_group_name {
  type = "string"
}
