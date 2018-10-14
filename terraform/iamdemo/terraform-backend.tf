terraform {
  backend "s3" {
    bucket = "tfstate-seligerit"
    key    = "iamdemo"
    dynamodb_table = "tfstate-lock"
    encrypt = true
    region = "eu-central-1"
    profile = "seligerit"
  }
}