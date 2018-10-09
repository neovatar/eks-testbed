resource "aws_key_pair" "admin" {
  key_name   = "tom"
  public_key = "${file("~/.ssh/id_rsa_manji.pub")}"
}