locals {
  aws_profile = "seligerit"
  cluster_name = "eks-test"
  worker_groups = [
    {
      node_type = "worker"
      min_size = 1
      max_size = 2
      desired_capacity = 2
      kubelet_extra_args = "--node-labels=kiam=agent"
    },
    {
      node_type = "kiam-server"
      min_size = 1
      max_size = 2
      desired_capacity = 1
      kubelet_extra_args = "--node-labels=kiam=server"
    }
  ]
}
