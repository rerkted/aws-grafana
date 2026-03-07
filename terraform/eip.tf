# ─── eip.tf ────────────────────────────────────────────────────
# Elastic IP for Grafana EC2 — static address, DNS never needs updating

resource "aws_eip" "grafana" {
  instance = aws_instance.grafana.id
  domain   = "vpc"

  tags = { Name = "grafana-eip" }
}
