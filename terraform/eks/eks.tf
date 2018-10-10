module "eks" {
    source = "./eks"

    cluster_name = "${var.cluster_name}"
    cluster_vpc_id = "${aws_vpc.eks-test.id}"
    cluster_subnets_ids = "${aws_subnet.eks-test.*.id}"
    ssh_admin_key_name = "${aws_key_pair.admin.key_name}"
}