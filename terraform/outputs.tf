# ─── outputs.tf ────────────────────────────────────────────────

output "grafana_public_ip" {
  value       = aws_eip.grafana.public_ip
  description = "Grafana EC2 Elastic IP — stored automatically in SSM at /rerktserver/grafana/eip"
}

output "grafana_instance_id" {
  value       = aws_instance.grafana.id
  description = "Grafana EC2 instance ID — stored automatically in SSM at /rerktserver/grafana/instance-id"
}

output "loki_endpoint" {
  value       = "${aws_eip.grafana.public_ip}:3100"
  description = "Loki push endpoint — used by portfolio EC2 Docker log driver"
}

output "grafana_url" {
  value       = "https://${var.domain_name}"
  description = "Grafana dashboard URL"
}
