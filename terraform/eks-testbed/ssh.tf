resource "aws_key_pair" "admin" {
  key_name   = "eks-${var.eks_cluster_name}-${var.env}-admin"
  public_key = "${var.ssh_admin_pubkey}"
}