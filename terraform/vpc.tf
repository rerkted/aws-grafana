# ─── vpc.tf ────────────────────────────────────────────────────
# Standalone VPC for Grafana EC2 — independent from portfolio VPC

resource "aws_vpc" "grafana" {
  #checkov:skip=CKV2_AWS_11:VPC flow logging disabled intentionally — cost decision for single-instance observability stack
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "grafana-vpc" }
}

resource "aws_internet_gateway" "grafana" {
  vpc_id = aws_vpc.grafana.id

  tags = { Name = "grafana-igw" }
}

resource "aws_subnet" "grafana_public" {
  #checkov:skip=CKV_AWS_130:Public subnet required — single EC2 serves public Grafana UI
  vpc_id                  = aws_vpc.grafana.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "grafana-public-subnet" }
}

resource "aws_route_table" "grafana_public" {
  vpc_id = aws_vpc.grafana.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.grafana.id
  }

  tags = { Name = "grafana-public-rt" }
}

resource "aws_route_table_association" "grafana_public" {
  subnet_id      = aws_subnet.grafana_public.id
  route_table_id = aws_route_table.grafana_public.id
}

# CKV2_AWS_12: Restrict default VPC security group — deny all traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.grafana.id

  tags = { Name = "grafana-default-sg-restricted" }
}
