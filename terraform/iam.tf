# ─── iam.tf ────────────────────────────────────────────────────
# IAM role for Grafana EC2 — SSM access only (no ECR needed)

resource "aws_iam_role" "grafana_ec2" {
  name        = "grafana-ec2-role"
  description = "IAM role for Grafana observability EC2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# SSM — required for GitHub Actions SSM deploy (no SSH in pipeline)
resource "aws_iam_role_policy_attachment" "grafana_ssm" {
  role       = aws_iam_role.grafana_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "grafana" {
  name = "grafana-instance-profile"
  role = aws_iam_role.grafana_ec2.name
}
