#
# Outputs
#

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks-test-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks-test.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks-test.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster-name}"
      env:
        - name: AWS_PROFILE
          value: "seligerit"
KUBECONFIG
}

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

resource "local_file" "kubectl-config" {
    content     = "${local.kubeconfig}"
    filename = "yaml/kubectl-config.yaml"
}

resource "local_file" "config-map-aws-auth" {
    content     = "${local.config_map_aws_auth}"
    filename = "yaml/config-map-aws-auth.yaml"
    depends_on = ["local_file.kubectl-config"]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=yaml/kubectl-config.yaml apply -f yaml/config-map-aws-auth.yaml"
  }
}