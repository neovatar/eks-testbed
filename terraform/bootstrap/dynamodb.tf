# dynamodb table for locking the state file
resource "aws_dynamodb_table" "tfstate-lock" {
  name = "tfstate-lock"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
