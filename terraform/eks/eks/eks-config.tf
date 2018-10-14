data "template_file" "maproles" {
  count = "${length(var.worker_groups)}"
  template = "${file("${path.module}/templates/maproles.yaml.tpl")}"
  vars {
    role_arn = "${aws_iam_role.eks_node.*.arn[count.index]}"
  }
}

data "template_file" "config_map_aws_auth" {
  template = "${file("${path.module}/templates/config-map-aws-auth.yaml.tpl")}"
  vars {
    maproles = "${join("\n", data.template_file.maproles.*.rendered)}"
  }
}

data "template_file" "kubectl_config" {
  template = "${file("${path.module}/templates/kubectl-config.yaml.tpl")}"
  vars {
    cluster_endpoint = "${aws_eks_cluster.eks_cluster.endpoint}"
    cluster_auth_base64 = "${aws_eks_cluster.eks_cluster.certificate_authority.0.data}"
    cluster_name = "${var.cluster_name}"
    aws_profile = "${var.aws_profile}"
  }
}

resource "local_file" "kubectl_config" {
  content = "${data.template_file.kubectl_config.rendered}"
  filename = "yaml/kubectl-config.yaml"
}

resource "local_file" "config_map_aws_auth" {
    content     = "${data.template_file.config_map_aws_auth.rendered}"
    filename = "yaml/config-map-aws-auth.yaml"
    depends_on = ["local_file.kubectl_config"]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=yaml/kubectl-config.yaml apply -f yaml/config-map-aws-auth.yaml"
  }
}
