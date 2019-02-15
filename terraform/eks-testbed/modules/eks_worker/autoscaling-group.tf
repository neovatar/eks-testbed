resource "aws_autoscaling_group" "eks_nodes" {
  desired_capacity     = "${var.desired_capacity}"
  launch_configuration = "${aws_launch_configuration.eks_node.id}"
  max_size             = "${var.max_size}"
  min_size             = "${var.min_size}"
  name                 = "${data.aws_eks_cluster.eks_cluster.name}-node-${var.worker_group_name}"
  vpc_zone_identifier  = ["${var.cluster_subnets_ids}"]

  tag {
    key                 = "Name"
    value               = "${data.aws_eks_cluster.eks_cluster.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${data.aws_eks_cluster.eks_cluster.name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
