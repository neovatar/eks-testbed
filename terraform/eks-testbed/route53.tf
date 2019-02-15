data "aws_route53_zone" "domain" {
  name         = "${var.dns_route53_hosted_domain}"
}

locals {
  dns_k8s = "k8s.${var.dns_route53_hosted_domain}"
  dns_k8s_env = "${var.env}.${local.dns_k8s}"
}

resource "aws_route53_zone" "k8s_env" {
  name = "${local.dns_k8s_env}"
}

resource "aws_route53_record" "k8s_ns" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "${local.dns_k8s_env}"
  type    = "NS"
  ttl     = "30"

  records = [
     "${aws_route53_zone.k8s_env.name_servers.0}",
     "${aws_route53_zone.k8s_env.name_servers.1}",
     "${aws_route53_zone.k8s_env.name_servers.2}",
     "${aws_route53_zone.k8s_env.name_servers.3}",
  ]
}

resource "aws_acm_certificate" "k8s_env" {
  domain_name       = "*.${local.dns_k8s_env}"
  validation_method = "DNS"
}

resource "aws_route53_record" "k8s_env_cert_validation" {
  name    = "${aws_acm_certificate.k8s_env.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.k8s_env.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.k8s_env.zone_id}"
  records = ["${aws_acm_certificate.k8s_env.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "k8s_env" {
  certificate_arn         = "${aws_acm_certificate.k8s_env.arn}"
  validation_record_fqdns = ["${aws_route53_record.k8s_env_cert_validation.fqdn}"]
}
