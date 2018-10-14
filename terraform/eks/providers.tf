provider "aws" {
  region = "eu-west-1"
  profile = "${local.aws_profile}"
}

provider "aws" {
  region = "eu-west-1"
  profile = "${local.aws_profile}"
  alias = "eks"
}

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}
