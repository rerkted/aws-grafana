# ─── variables.tf ──────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type for Grafana server"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of existing EC2 key pair for SSH access"
  type        = string
}

variable "home_ip_cidr" {
  description = "Home IP in CIDR notation — allowed HTTPS + SSH access"
  type        = string
  default     = "REDACTED_IP/32"
  sensitive   = true
}

variable "admin_email" {
  description = "Email for Let's Encrypt cert expiry notifications"
  type        = string
}

variable "domain_name" {
  description = "Full subdomain for Grafana (used for SSL cert)"
  type        = string
  default     = "grafana.rerktserver.com"
}
