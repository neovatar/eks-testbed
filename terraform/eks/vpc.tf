#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "eks-test" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
     "Name", "terraform-eks-test-node",
     "kubernetes.io/cluster/${local.cluster_name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks-test" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.eks-test.id}"

  tags = "${
    map(
     "Name", "terraform-eks-demo-node",
     "kubernetes.io/cluster/${local.cluster_name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "eks-test" {
  vpc_id = "${aws_vpc.eks-test.id}"

  tags {
    Name = "eks-test"
  }
}

resource "aws_route_table" "eks-test" {
  vpc_id = "${aws_vpc.eks-test.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks-test.id}"
  }
}

resource "aws_route_table_association" "eks-test" {
  count = 2

  subnet_id      = "${aws_subnet.eks-test.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks-test.id}"
}
