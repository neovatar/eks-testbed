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