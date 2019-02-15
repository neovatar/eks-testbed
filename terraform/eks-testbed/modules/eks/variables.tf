variable "aws_profile" {
  type = "string"
}

variable "env" {
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

variable "worker_groups" {
  type = "list"
}