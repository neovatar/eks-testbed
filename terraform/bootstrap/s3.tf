resource "aws_s3_bucket" "tfstate-seligerit" {
  bucket = "tfstate-seligerit"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
