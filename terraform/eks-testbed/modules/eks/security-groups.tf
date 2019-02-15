#
# This security group controls networking access to the Kubernetes masters.
# Has an ingress rule to allow traffic from the worker nodes.
#
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "EKS cluster ${var.cluster_name} communication with worker nodes"
  vpc_id      = "${var.cluster_vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.cluster_name}"
    env = "${var.env}"
  }
}

resource "aws_security_group_rule" "eks_cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the eks cluster ${var.cluster_name} API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_cluster.id}"
  source_security_group_id = "${aws_security_group.eks_nodes.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_test_node_ingress_ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow SSH to nodes of eks cluster ${var.cluster_name}"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks_nodes.id}"
  to_port           = 22
  type              = "ingress"
}

#
# This security group controls networking access to the Kubernetes worker nodes.
#
resource "aws_security_group" "eks_nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "Security group for all nodes in eks cluster ${var.cluster_name}"
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
     "env", "${var.env}",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks_node_ingress_self" {
  description              = "Allow nodes of eks cluster ${var.cluster_name} to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks_nodes.id}"
  source_security_group_id = "${aws_security_group.eks_nodes.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_node_ingress_cluster_443" {
  description              = "Allow worker Kubelets and pods to receive communication from the eks cluster ${var.cluster_name} control plane on port 443"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_nodes.id}"
  source_security_group_id = "${aws_security_group.eks_cluster.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the eks cluster ${var.cluster_name} control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_nodes.id}"
  source_security_group_id = "${aws_security_group.eks_cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}
