#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

# This is the base policy for the EKS nodes
data "aws_iam_policy_document" "eks-test-node" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# These are AWS provides policies that will be attached to the EKS nodes
variable "EKSPolicies" {
  type = "list"
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", 
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

# This is the role a normal EKS worker node
resource "aws_iam_role" "eks-test-node" {
  name = "eks-test-node"
  assume_role_policy = "${data.aws_iam_policy_document.eks-test-node.json}"
}

resource "aws_iam_role_policy_attachment" "eks-test-node-EKSPolicies" {
  count = 3
  policy_arn = "${element(var.EKSPolicies, count.index)}"
  role       = "${aws_iam_role.eks-test-node.name}"
}

# This is the role for our EKS nodes which host kiam and therefore need
# extended IAM permissions
resource "aws_iam_role" "eks-test-node-kiam-server" {
  name = "eks-test-node-kiam-server"
  assume_role_policy = "${data.aws_iam_policy_document.eks-test-node.json}"
}

resource "aws_iam_role_policy_attachment" "eks-test-node-kiam-server-EKSPolicies" {
  count = 3
  policy_arn = "${element(var.EKSPolicies, count.index)}"
  role       = "${aws_iam_role.eks-test-node-kiam-server.name}"
}

data "aws_iam_policy_document" "eks-test-kiam-server" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::059300324029:role/kiam-server"]
  }
}

resource "aws_iam_policy" "eks-test-kiam-server" {
  name = "eks-test-kiam-server"
  policy = "${data.aws_iam_policy_document.eks-test-kiam-server.json}"
}

resource "aws_iam_role_policy_attachment" "eks-test-kiam-server" {
  policy_arn = "${aws_iam_policy.eks-test-kiam-server.arn}"
  role = "${aws_iam_role.eks-test-node-kiam-server.name}"
}


resource "aws_iam_instance_profile" "eks-test-node" {
  name = "eks-test-node"
  role = "${aws_iam_role.eks-test-node.name}"
}

resource "aws_iam_instance_profile" "eks-test-node-kiam-server" {
  name = "eks-test-node-kiam-server"
  role = "${aws_iam_role.eks-test-node-kiam-server.name}"
}

resource "aws_security_group" "eks-test-node" {
  name        = "eks-test-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.eks-test.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "eks-test-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks-test-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks-test-node.id}"
  source_security_group_id = "${aws_security_group.eks-test-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-test-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-test-node.id}"
  source_security_group_id = "${aws_security_group.eks-test-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-test-node-ingress-ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow SSH to eks nodes"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks-test-node.id}"
  to_port           = 22
  type              = "ingress"
}

data "aws_ami" "eks-worker" {
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
  eks-test-node-worker-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh \
  --apiserver-endpoint '${aws_eks_cluster.eks-test.endpoint}' \
  --b64-cluster-ca '${aws_eks_cluster.eks-test.certificate_authority.0.data}' \
  --kubelet-extra-args '--node-labels=kiam=agent' \
  '${var.cluster-name}'
USERDATA
  eks-test-node-kiam-server-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh \
  --apiserver-endpoint '${aws_eks_cluster.eks-test.endpoint}' \
  --b64-cluster-ca '${aws_eks_cluster.eks-test.certificate_authority.0.data}' \
  --kubelet-extra-args '--node-labels=kiam=server' \
  '${var.cluster-name}'
USERDATA
}

# KNOWHOW: To label nodes differently, you can use two launch configurations. Possibly there is
#  a more elegant way to do this in terraform?
resource "aws_launch_configuration" "eks-test-node-worker" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks-test-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "eks-test"
  security_groups             = ["${aws_security_group.eks-test-node.id}"]
  user_data_base64            = "${base64encode(local.eks-test-node-worker-userdata)}"
  key_name                    = "${aws_key_pair.admin.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "eks-test-node-kiam-server" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks-test-node-kiam-server.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "eks-test"
  security_groups             = ["${aws_security_group.eks-test-node.id}"]
  user_data_base64            = "${base64encode(local.eks-test-node-kiam-server-userdata)}"
  key_name                    = "${aws_key_pair.admin.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks-test-nodes" {
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.eks-test-node-worker.id}"
  max_size             = 2
  min_size             = 1
  name                 = "eks-test-nodes-worker"
  vpc_zone_identifier  = ["${aws_subnet.eks-test.*.id}"]

  tag {
    key                 = "Name"
    value               = "eks-test"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "eks-test-kiam-server" {
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.eks-test-node-kiam-server.id}"
  max_size             = 2
  min_size             = 1
  name                 = "eks-test-nodes-kiam-server"
  vpc_zone_identifier  = ["${aws_subnet.eks-test.*.id}"]

  tag {
    key                 = "Name"
    value               = "eks-test"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
