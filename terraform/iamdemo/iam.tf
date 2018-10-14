# kiam role which will be used by a kiam server to
# attain sts credentials for pods

data "aws_iam_policy_document" "kiam-server" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
  statement {
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::059300324029:role/eks-test-node-kiam-server"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "kiam-server" {
  name = "kiam-server"
  assume_role_policy = "${data.aws_iam_policy_document.kiam-server.json}"
}


data "aws_iam_policy_document" "kiam-server-sts" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "kiam-server-sts" {
  name = "kiam-server-sts"
  policy = "${data.aws_iam_policy_document.kiam-server-sts.json}"
}

resource "aws_iam_role_policy_attachment" "kiam-server-sts" {
  policy_arn = "${aws_iam_policy.kiam-server-sts.arn}"
  role       = "${aws_iam_role.kiam-server.name}"
}

