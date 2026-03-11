# ─── ec2.tf ────────────────────────────────────────────────────
# Dedicated t3.micro EC2 for Grafana observability stack

resource "aws_instance" "grafana" {
  #checkov:skip=CKV_AWS_135:T3 instances are automatically EBS-optimized; explicit flag unsupported
  #checkov:skip=CKV_AWS_126:Detailed monitoring disabled intentionally — cost vs. benefit for t3.micro
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.grafana_public.id
  vpc_security_group_ids = [aws_security_group.grafana.id]
  iam_instance_profile   = aws_iam_instance_profile.grafana.name
  key_name               = var.key_pair_name

  root_block_device {
    volume_size           = 20   # 20GB — sufficient for Loki 7-day log retention
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    domain_name = var.domain_name
    admin_email = var.admin_email
  }))

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "grafana-ec2" }
}
