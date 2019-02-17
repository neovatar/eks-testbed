provider "template" {}
provider "local" {}

data "template_file" "backend_config" {
  template = "${file("${path.module}/templates/backend-config.tfvars")}"
  vars {
    aws_region = "${var.aws_region}"
    aws_profile = "${var.aws_profile}"
    env = "${var.env}"
    eks_cluster_name = "${var.eks_cluster_name}"
    tfstate_s3 = "${var.tfstate_s3}"
    tfstate_dynamodb ="${var.tfstate_dynamodb}"
  }
}

resource "local_file" "bootstrap_backend_config" {
  content = "${data.template_file.backend_config.rendered}"
  filename = "./tmp/backend-config.tfvars"
  provisioner "local-exec" {
    command = "cp ./tmp/backend-config.tfvars ../backend-config-${var.env}.tfvars"
  }
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

resource "local_file" "config" {
  content = "${data.template_file.config.rendered}"
  filename = "./tmp/config.tfvars"
  provisioner "local-exec" {
    command = "cp ./tmp/config.tfvars ../config-${var.env}.tfvars"
  }
}
