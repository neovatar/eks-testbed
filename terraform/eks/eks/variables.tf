variable "aws_profile" {
  type = "string"
}

variable "cluster_name" {
  type ="string"
}
variable "cluster_vpc_id" {
  type = "string"
}

variable "cluster_subnets_ids" {
  type = "list"
}

variable "ssh_admin_key_name" {
  type = "string"
}

variable "worker_groups" {
  description = "A list of maps defining worker group configurations."
  type        = "list"

  default = [{
    "name" = "default"
  }]
}