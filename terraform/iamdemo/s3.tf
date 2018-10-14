##
## Create a s3 bucket and configure a IAM role with access permission
##

# KNOWHOW: You can use AWS policy simulator to check IAM role permissions: https://policysim.aws.amazon.com/home/index.jsp

resource "aws_s3_bucket" "iamdemo" {
  bucket = "iamdemo-seligerit"

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = false
  }
}

data "aws_iam_policy_document" "iamdemo-s3-access-assume-role-policy" {
  statement {
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com", "s3.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
  statement {
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::059300324029:role/kiam-server"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# KNOWHOW: You cannot use resources directly in roles, so define role and attach policies later
resource "aws_iam_role" "iamdemo-s3-access" {
  name = "iamdemo-s3-access"
  assume_role_policy = "${data.aws_iam_policy_document.iamdemo-s3-access-assume-role-policy.json}"
}

# KNOWHOW: You can use a tf data resource instead of above inline json for amazon policies.
#
# Cons:
#   - another layer of abstraction
#   - slightly different from AWS json e.g. "resources" instead of "resource"
#
# Pros:
#   - a little more readable
#   - more expressive: "resources" is a list (its "resource" in AWS json, but also a list)
#   - more parsing for correctness before sending json to AWS api
#
data "aws_iam_policy_document" "iamdemo-s3-access" {
  statement {
    effect = "Allow"
    actions = ["s3:GetBucketLocation", "s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["s3:ListBucket"],
    resources = ["${aws_s3_bucket.iamdemo.arn}"]
  }

  statement {
    effect = "Allow"
    actions = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.iamdemo.arn}/*"]
  }
}

resource "aws_iam_policy" "iamdemo-s3-access" {
  name = "iamdemo-s3-access"
  policy = "${data.aws_iam_policy_document.iamdemo-s3-access.json}"
}

# KNOWHOW: You cannot use resources in roles, so attach policies to a role
resource "aws_iam_policy_attachment" "iamdemo-s3-access" {
  name       = "iamdemo-s3-access"
  roles      = ["${aws_iam_role.iamdemo-s3-access.name}"]
  policy_arn = "${aws_iam_policy.iamdemo-s3-access.arn}"
}

output "iamdemo_s3_http" {
  value = "${aws_s3_bucket.iamdemo.bucket_domain_name}"
}

output "iamdemo_s3_arn" {
  value = "${aws_s3_bucket.iamdemo.arn}"
}

output "iamdemo_iam_role_arn" {
  value = "${aws_iam_role.iamdemo-s3-access.arn}"
}