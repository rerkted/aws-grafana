# ─── eip.tf ────────────────────────────────────────────────────
## Elastic IP for Grafana EC2 — static address, DNS never needs updating

resource "aws_eip" "grafana" {
  instance = aws_instance.grafana.id
  domain   = "vpc"

  tags = { Name = "grafana-eip" }
}

# Store Grafana EIP and instance ID in SSM — deploy workflow reads these dynamically
resource "aws_ssm_parameter" "grafana_eip" {
  #checkov:skip=CKV2_AWS_34:Grafana EIP is a public IP address — not sensitive data requiring SecureString
  name  = "/rerktserver/grafana/eip"
  type  = "String"
  value = aws_eip.grafana.public_ip

  tags = { Name = "grafana-eip" }
}

resource "aws_ssm_parameter" "grafana_instance_id" {
  #checkov:skip=CKV2_AWS_34:EC2 instance ID is not sensitive — used for SSM targeting
  name  = "/rerktserver/grafana/instance-id"
  type  = "String"
  value = aws_instance.grafana.id

  tags = { Name = "grafana-instance-id" }
}

# Read portfolio EIP from SSM (set by aws-server terraform)
data "aws_ssm_parameter" "portfolio_eip" {
  name = "/rerktserver/portfolio/eip"
}
