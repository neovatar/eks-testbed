# Get subnet ids ouf our VPC
data "aws_subnet_ids" "subnet_ids" {
  vpc_id = "${module.vpc.vpc_id}"
}