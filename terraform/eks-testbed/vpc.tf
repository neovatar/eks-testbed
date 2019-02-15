module "vpc" {
  source = "modules/vpc"
  eks_cluster_name = "${var.eks_cluster_name}"
  env = "${var.env}"
}
