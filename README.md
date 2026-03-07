# Project 08 — Grafana + Loki Observability Stack

Centralized log aggregation and visualization for the rerktserver.com portfolio infrastructure.
Deployed at `grafana.rerktserver.com` — IP whitelisted, login required.

## Architecture

```
portfolio (nginx)  ─┐
rerkt-ai (node)   ──┤──▶ Promtail ──▶ Loki ──▶ Grafana
bedrock-ai (node) ─┘                              │
                                                   ▼
                                        grafana.rerktserver.com
```

## Stack

| Service  | Image                    | Port          | Purpose                    |
|----------|--------------------------|---------------|----------------------------|
| Loki     | grafana/loki:2.9.0       | 3100 internal | Log storage & query engine |
| Promtail | grafana/promtail:2.9.0   | 9080 internal | Docker log shipper         |
| Grafana  | grafana/grafana:10.2.0   | 3000 internal | Dashboard & visualization  |

All services run via Docker Compose. nginx proxies `grafana.rerktserver.com` → `127.0.0.1:3000`.

## Security

- Grafana port 3000 bound to `127.0.0.1` only (not publicly exposed)
- AWS Security Group restricts port 443 for `grafana.rerktserver.com` to home IP
- Grafana login required — anonymous access disabled
- Sign-up disabled

## GitHub Secrets Required

| Secret            | Description                  |
|-------------------|------------------------------|
| `GRAFANA_USER`    | Grafana admin username        |
| `GRAFANA_PASSWORD`| Grafana admin password        |

## Deployment

```bash
# 1. Terraform — Route53 + Security Group + EC2 resize
cd terraform
terraform init
terraform apply

# 2. Expand SSL cert on EC2
sudo certbot certonly --webroot -w /var/www/certbot \
  -d rerktserver.com -d www.rerktserver.com \
  -d ai.rerktserver.com -d bedrock.rerktserver.com \
  -d grafana.rerktserver.com \
  --expand --non-interactive --agree-tos --email Edwardrerk@proton.me
sudo docker restart portfolio

# 3. Push to main — pipeline deploys stack via SSM
git push origin main
```

## Log Retention

Loki is configured with 7-day retention to keep storage low on t3.micro.
