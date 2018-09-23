terraform {
  backend "s3" {
    bucket = "tfstate-seligerit"
    key    = "eks-test"
    dynamodb_table = "tfstate-lock"
    encrypt = true
    region = "eu-central-1"
    profile = "seligerit"
  }
}