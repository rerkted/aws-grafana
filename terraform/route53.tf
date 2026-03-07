# ─── route53.tf ────────────────────────────────────────────────
# DNS record for grafana.rerktserver.com → Grafana EC2 Elastic IP

resource "aws_route53_record" "grafana" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.grafana.public_ip]
}
