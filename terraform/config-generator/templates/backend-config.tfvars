bucket = "${tfstate_s3}-${env}"
key    = "${env}/${eks_cluster_name}"
dynamodb_table = "${tfstate_dynamodb}-${env}"
encrypt = true
region = "${aws_region}"
profile = "${aws_profile}"
