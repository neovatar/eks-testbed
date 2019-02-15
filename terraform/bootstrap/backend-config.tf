
data "template_file" "backend_config" {
  template = "${file("${path.module}/templates/backend-config.tfvars")}"
  vars {
    tfstate_s3 = "${var.tfstate_s3}"
    tfstate_dynamodb = "${var.tfstate_dynamodb}"
    aws_region = "${var.aws_region}"
    aws_profile = "${var.aws_profile}"
    env = "${var.env}"
  }
}

resource "local_file" "backend_config" {
  content = "${data.template_file.backend_config.rendered}"
  filename = "../backend-config.tfvars"
}