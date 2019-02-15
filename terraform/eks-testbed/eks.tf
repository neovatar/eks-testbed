# Create EKS cluster and configure EKS cluster to allow 
# joining of worker nodes
#
# Note: We also need to specify the names of the worker node groups
#       that we will define later

locals {
  eks_cluster_fullname = "${var.eks_cluster_name}-${var.env}"
}

module "eks" {
  source = "modules/eks"
  env = "${var.env}"
  aws_profile = "${var.aws_profile}"
  cluster_name = "${local.eks_cluster_fullname}"
  cluster_vpc_id = "${module.vpc.vpc_id}"
  cluster_subnets_ids = "${data.aws_subnet_ids.subnet_ids.ids}"
  worker_groups = ["default"]
}
