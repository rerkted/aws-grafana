# ─── security-group.tf ─────────────────────────────────────────
# Grafana EC2 security group — minimal attack surface

resource "aws_security_group" "grafana" {
  name        = "grafana-sg"
  description = "Grafana observability stack security group"
  vpc_id      = aws_vpc.grafana.id

  # HTTPS — Grafana UI, home IP only
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.home_ip_cidr]
    description = "HTTPS Grafana (home IP only)"
  }

  # HTTP — Let's Encrypt ACME challenge only (certbot webroot)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for Lets Encrypt ACME challenge"
  }

  # SSH — home IP only for initial setup and debugging
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.home_ip_cidr]
    description = "SSH (home IP only)"
  }

  # Loki ingestion — portfolio EC2 Elastic IP only (read from SSM)
  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_ssm_parameter.portfolio_eip.value}/32"]
    description = "Loki log ingestion from portfolio EC2"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = { Name = "grafana-sg" }
}
