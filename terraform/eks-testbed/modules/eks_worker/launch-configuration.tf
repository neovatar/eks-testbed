resource "aws_iam_instance_profile" "eks_node" {
  name = "${data.aws_eks_cluster.eks_cluster.name}-node-${var.worker_group_name}"
  role = "${aws_iam_role.eks_node.name}"
}

# EKS currently needs userdata for EKS worker nodes to properly configure
# Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify base64 encoding this
# information into the AutoScaling Launch Configuration.
#
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html

data "template_file" "bootstrap" {
  template = "${file("${path.module}/templates/userdata.sh.tpl")}"
  vars {
    cluster_endpoint = "${data.aws_eks_cluster.eks_cluster.endpoint}"
    cluster_auth_base64 = "${data.aws_eks_cluster.eks_cluster.certificate_authority.0.data}"
    worker_group_name = "${var.worker_group_name}"
    cluster_name = "${data.aws_eks_cluster.eks_cluster.name}"
  }
}

resource "aws_launch_configuration" "eks_node" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks_node.name}"
  image_id                    = "${var.aws_eks_ami_id}"
  instance_type               = "${var.instance_type}"
  name_prefix                 = "${data.aws_eks_cluster.eks_cluster.name}-node-${var.worker_group_name}"
  security_groups             = ["${data.aws_security_group.eks_nodes.id}"]
  user_data_base64            = "${base64encode(data.template_file.bootstrap.rendered)}"
  key_name                    = "${var.ssh_admin_key_name}"

  lifecycle {
    create_before_destroy = true
  }
}