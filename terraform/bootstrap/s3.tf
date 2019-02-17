resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.tfstate_s3}-${var.env}"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }
}
