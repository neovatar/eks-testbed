provider "template" {}
provider "local" {}

data "template_file" "backend_config" {
  template = "${file("${path.module}/templates/aws_provider.tf")}"
  vars {
    aws_region = "${var.aws_region}"
    aws_profile = "${var.aws_profile}"
    env = "${var.env}"
  }
}

data "template_file" "header" {
  template = "${file("${path.module}/templates/header.txt")}"
}

resource "local_file" "bootstrap_backend_config" {
  content = "${join("\n", list(data.template_file.header.rendered, data.template_file.backend_config.rendered))}"
  filename = "../bootstrap/__aws_provider.tf"
}

resource "local_file" "eks_testbed_backend_config" {
  content = "${data.template_file.backend_config.rendered}"
  filename = "../eks-testbed/__aws_provider.tf"
}

data "template_file" "config" {
  template = "${file("${path.module}/templates/config.tfvars")}"
  vars {
    tfstate_s3 = "${var.tfstate_s3}"
    tfstate_dynamodb = "${var.tfstate_dynamodb}"
    aws_region = "${var.aws_region}"
    aws_profile = "${var.aws_profile}"
    env = "${var.env}"
    dns_route53_hosted_domain = "${var.dns_route53_hosted_domain}"
    ssh_admin_pubkey_path = "${var.ssh_admin_pubkey_path}"
    eks_cluster_name = "${var.eks_cluster_name}"
  }
}

resource "local_file" "config_auto_config" {
  content = "${data.template_file.config.rendered}"
  filename = "terraform.tfvars"
  lifecycle {
    ignore_changes = ["content"]
    prevent_destroy = true
  }
}

resource "local_file" "eks_testbed_auto_config" {
  content = "${join("\n", list(data.template_file.header.rendered, data.template_file.config.rendered))}"
  filename = "../eks-testbed/__config.auto.tfvars"
}

resource "local_file" "bootstrap_auto_config" {
  content = "${join("\n", list(data.template_file.header.rendered, data.template_file.config.rendered))}"
  filename = "../bootstrap/__config.auto.tfvars"
}