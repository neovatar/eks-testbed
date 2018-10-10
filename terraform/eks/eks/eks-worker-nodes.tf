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

# These are AWS provides policies that will be attached to the EKS nodes
locals {
  EKSPolicies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", 
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

# This is the role a normal EKS worker node
resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node"
  assume_role_policy = "${data.aws_iam_policy_document.eks_node.json}"
}

resource "aws_iam_role_policy_attachment" "eks_node_EKSPolicies" {
  count = 3
  policy_arn = "${element(local.EKSPolicies, count.index)}"
  role       = "${aws_iam_role.eks_node.name}"
}

# This is the role for our EKS nodes which host kiam and therefore need
# extended IAM permissions
resource "aws_iam_role" "eks_node_kiam_server" {
  name = "${var.cluster_name}-node-kiam-server"
  assume_role_policy = "${data.aws_iam_policy_document.eks_node.json}"
}

resource "aws_iam_role_policy_attachment" "eks_node_kiam_server_EKSPolicies" {
  count = 3
  policy_arn = "${element(local.EKSPolicies, count.index)}"
  role       = "${aws_iam_role.eks_node_kiam_server.name}"
}

data "aws_iam_policy_document" "eks_kiam_server" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::059300324029:role/kiam-server"]
  }
}

resource "aws_iam_policy" "eks_kiam_server" {
  name = "${var.cluster_name}-kiam-server"
  policy = "${data.aws_iam_policy_document.eks_kiam_server.json}"
}

resource "aws_iam_role_policy_attachment" "eks_kiam_server" {
  policy_arn = "${aws_iam_policy.eks_kiam_server.arn}"
  role = "${aws_iam_role.eks_node_kiam_server.name}"
}


resource "aws_iam_instance_profile" "eks_node" {
  name = "${var.cluster_name}-node"
  role = "${aws_iam_role.eks_node.name}"
}

resource "aws_iam_instance_profile" "eks_node_kiam_server" {
  name = "${var.cluster_name}-node-kiam-server"
  role = "${aws_iam_role.eks_node_kiam_server.name}"
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
locals {
  eks_node_worker_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh \
  --apiserver-endpoint '${aws_eks_cluster.eks_cluster.endpoint}' \
  --b64-cluster-ca '${aws_eks_cluster.eks_cluster.certificate_authority.0.data}' \
  --kubelet-extra-args '--node-labels=kiam=agent' \
  '${var.cluster_name}'
USERDATA
  eks_node_kiam_server_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh \
  --apiserver-endpoint '${aws_eks_cluster.eks_cluster.endpoint}' \
  --b64-cluster-ca '${aws_eks_cluster.eks_cluster.certificate_authority.0.data}' \
  --kubelet-extra-args '--node-labels=kiam=server' \
  '${var.cluster_name}'
USERDATA
}

# KNOWHOW: To label nodes differently, you can use two launch configurations. Possibly there is
#  a more elegant way to do this in terraform?
resource "aws_launch_configuration" "eks_node_worker" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks_node.name}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "${var.cluster_name}-worker"
  security_groups             = ["${aws_security_group.eks_nodes.id}"]
  user_data_base64            = "${base64encode(local.eks_node_worker_userdata)}"
  key_name                    = "${var.ssh_admin_key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "eks_node_kiam_server" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks_node_kiam_server.name}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "${var.cluster_name}-kiam-server"
  security_groups             = ["${aws_security_group.eks_nodes.id}"]
  user_data_base64            = "${base64encode(local.eks_node_kiam_server_userdata)}"
  key_name                    = "${var.ssh_admin_key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks_nodes_worker" {
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.eks_node_worker.id}"
  max_size             = 2
  min_size             = 1
  name                 = "${var.cluster_name}-nodes-worker"
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

resource "aws_autoscaling_group" "eks_nodes_kiam_server" {
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.eks_node_kiam_server.id}"
  max_size             = 2
  min_size             = 1
  name                 = "${var.cluster_name}-nodes-kiam-server"
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
