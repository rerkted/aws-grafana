# Grafana Stack Runbook

## Destroy and Recreate (Full Teardown)

```bash
# 1. Destroy infrastructure
cd aws-grafana/terraform
terraform destroy

# 2. Recreate infrastructure
terraform apply
# Automatically stores new EIP + instance ID in SSM — no manual updates needed
```

```bash
# 3. Check your home IP hasn't changed
curl ifconfig.me
# Compare to home_ip_cidr in terraform.tfvars
# If different, update terraform.tfvars and re-run terraform apply
```

```bash
# 4. Wait for bootstrap to complete (~5-8 min)
ssh -i ~/.ssh/portfolio-key.pem ec2-user@$(aws ssm get-parameter \
  --name "/rerktserver/grafana/eip" --query "Parameter.Value" --output text)

sudo tail -f /var/log/grafana-bootstrap.log
# Wait for: "=== Bootstrap complete ==="
# Then exit SSH
```

```bash
# 5. Trigger the app deploy (stack was not deployed during bootstrap)
cd aws-grafana
git commit --allow-empty -m "trigger: deploy to new grafana instance"
git push origin main
```

```bash
# 6. Verify
# GitHub Actions should pass
# https://grafana.rerktserver.com should load
```

---

## Normal Deploy (No Infrastructure Changes)

Just push to main — GitHub Actions handles everything:

```bash
git push origin main
```

---

## IP Whitelist Changed

If your home IP changes, SSH and HTTPS will time out. Fix:

```bash
# Get your current IP
curl ifconfig.me

# Update terraform.tfvars
vi aws-grafana/terraform/terraform.tfvars
# Change home_ip_cidr to <your-ip>/32

# Apply the security group change
cd aws-grafana/terraform
terraform apply
```

---

## Useful Commands

```bash
# Get current Grafana EIP
aws ssm get-parameter --name "/rerktserver/grafana/eip" \
  --query "Parameter.Value" --output text

# Get current Grafana instance ID
aws ssm get-parameter --name "/rerktserver/grafana/instance-id" \
  --query "Parameter.Value" --output text

# Check instance state
aws ec2 describe-instances \
  --instance-ids $(aws ssm get-parameter --name "/rerktserver/grafana/instance-id" \
    --query "Parameter.Value" --output text) \
  --query "Reservations[0].Instances[0].State.Name" --output text

# SSH into Grafana EC2
ssh -i ~/.ssh/portfolio-key.pem ec2-user@$(aws ssm get-parameter \
  --name "/rerktserver/grafana/eip" --query "Parameter.Value" --output text)

# Watch bootstrap log
sudo tail -f /var/log/grafana-bootstrap.log

# Check stack status on EC2
docker compose -f /home/ec2-user/aws-grafana/docker-compose.yml ps
```

---

## Deployment Order (First-Time Setup)

If setting up from scratch, deploy in this order:

1. `aws-server` terraform — stores portfolio EIP in SSM
2. `aws-grafana` terraform — reads portfolio EIP from SSM for security group
3. Push `aws-grafana` to trigger app deploy

---

## GitHub Secrets Required

| Repo | Secret | Description |
|------|--------|-------------|
| aws-grafana | `GRAFANA_USER` | Grafana admin username |
| aws-grafana | `GRAFANA_PASSWORD` | Grafana admin password |

Instance IDs and IPs are read from SSM automatically — no secrets needed for those.
