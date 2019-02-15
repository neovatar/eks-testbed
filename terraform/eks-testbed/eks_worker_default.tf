# Create a worker node group and pass cluster_id of the cluster above
# via module.eks.eks_cluster_id.
# 
# To add a new worker group, do the following and replace
# <worker group name> with the group you want to add:
#
# 1. add <worker group name> to the worker_group list in the
#    eks cluster definition in eks.tf
# 2. add the new eks_woker_group_<worker group module> below
# 3. run terraform init and apply:
#    'terraform init && terraform apply'
#
# To remove an existing worker node group, do the following
# and replace <worker group name> with the group you want to destroy:
# 
#    1. destroy worker node resources with:
#      'terraform destroy --target=module.eks_worker_<worker group name>'
#    2. remove module definition eks_worker_group_<worker group name> in this file and
#       remove <worker group name> from the worker_group parameter in eks.tf
#    3. terraform init and apply:
#       'terraform init && terraform apply'
#
module "eks_worker_default" {
  source = "modules/eks_worker"
  worker_group_name = "default"
  aws_profile = "${var.aws_profile}"
  eks_cluster_id = "${module.eks.eks_cluster_id}"
  cluster_subnets_ids = "${data.aws_subnet_ids.subnet_ids.ids}"
  instance_type = "m5.large"
  aws_eks_ami_id = "ami-05e062a123092066a"
  min_size = 1
  max_size = 2
  desired_capacity = 2
  ssh_admin_key_name = "${aws_key_pair.admin.key_name}"
}
