resource "aws_dynamodb_table" "tfstate-lock" {
  name = "${var.tfstate_dynamodb}-${var.env}"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
