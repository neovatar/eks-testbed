#  Setup a VPC prepared to hold an EKS cluster as outlined at
#
#    https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
# 
#   Setup:
#    * VPC
#    * Subnets
#    * Internet Gateway
#    * Route Table
#
#   Note: The usage of the specific kubernetes.io/cluster/* resource tags below are
#         required for EKS and Kubernetes to discover and manage networking resources.
#         The would be craeted automatically by EKS but terraform would remove them
#         if they are not specified here.
#

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = "${
    map(
     "Name", "eks-vpc-${var.env}",
     "env", "${var.env}",
     "kubernetes.io/cluster/${var.eks_cluster_name}", "shared"
    )
  }"
}

resource "aws_subnet" "subnet" {
  count = 3

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.vpc.id}"

  tags = "${
    map(
     "Name", "eks-subnet-${count.index}",
     "env", "${var.env}",
     "kubernetes.io/cluster/${var.eks_cluster_name}", "shared",
     "kubernetes.io/role/elb", ""
    )
  }"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${
    map(
     "Name", "eks-internet-gateway-${var.env}",
     "env", "${var.env}",
    )
  }"
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }

  tags = "${
    map(
     "Name", "route-table-${var.env}",
     "env", "${var.env}",
    )
  }"
}

resource "aws_route_table_association" "route_table_assoc" {
  count = 3

  subnet_id      = "${aws_subnet.subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.route_table.id}"
}
