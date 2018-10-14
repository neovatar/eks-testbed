#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

# This is the base policy for the EKS nodes
data "aws_iam_policy_document" "eks_node" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Assume role policy
resource "aws_iam_role" "eks_node" {
  count = "${length(var.worker_groups)}"
  name = "${var.cluster_name}-node-${lookup(var.worker_groups[count.index], "node_type")}"
  assume_role_policy = "${data.aws_iam_policy_document.eks_node.json}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  count = "${length(var.worker_groups)}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = "${aws_iam_role.eks_node.*.name[count.index]}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  count = "${length(var.worker_groups)}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = "${aws_iam_role.eks_node.*.name[count.index]}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  count = "${length(var.worker_groups)}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = "${aws_iam_role.eks_node.*.name[count.index]}"
}

resource "aws_iam_instance_profile" "eks_node" {
  count = "${length(var.worker_groups)}"
  name = "${var.cluster_name}-node-${lookup(var.worker_groups[count.index], "node_type")}"
  role = "${aws_iam_role.eks_node.*.name[count.index]}"
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${var.cluster_vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${var.cluster_name}-node",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks_node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks_nodes.id}"
  source_security_group_id = "${aws_security_group.eks_nodes.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_nodes.id}"
  source_security_group_id = "${aws_security_group.eks_cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_test_node_ingress_ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow SSH to eks nodes"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks_nodes.id}"
  to_port           = 22
  type              = "ingress"
}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html

data "template_file" "bootstrap" {
  count = "${length(var.worker_groups)}"
  template = "${file("${path.module}/templates/userdata.sh.tpl")}"
  vars {
    cluster_endpoint = "${aws_eks_cluster.eks_cluster.endpoint}"
    cluster_auth_base64 = "${aws_eks_cluster.eks_cluster.certificate_authority.0.data}"
    kubelet_extra_args = "${lookup(var.worker_groups[count.index], "kubelet_extra_args", "")}"
    cluster_name = "${var.cluster_name}"
  }
}

# KNOWHOW: To label nodes differently, you can use two launch configurations. Possibly there is
#  a more elegant way to do this in terraform?
resource "aws_launch_configuration" "eks_node" {
  count = "${length(var.worker_groups)}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks_node.*.name[count.index]}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "${var.cluster_name}-node-${lookup(var.worker_groups[count.index], "node_type")}"
  security_groups             = ["${aws_security_group.eks_nodes.id}"]
  user_data_base64            = "${base64encode(data.template_file.bootstrap.*.rendered[count.index])}"
  key_name                    = "${var.ssh_admin_key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks_nodes" {
  count = "${length(var.worker_groups)}"
  desired_capacity     = "${lookup(var.worker_groups[count.index], "desired_capacity")}"
  launch_configuration = "${aws_launch_configuration.eks_node.*.id[count.index]}"
  max_size             = "${lookup(var.worker_groups[count.index], "max_size")}"
  min_size             = "${lookup(var.worker_groups[count.index], "min_size")}"
  name                 = "${var.cluster_name}-node-${lookup(var.worker_groups[count.index], "node_type")}"
  vpc_zone_identifier  = ["${var.cluster_subnets_ids}"]

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
