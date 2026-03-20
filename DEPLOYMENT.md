# Cooperation Tulsa — Deployment Guide

## Infrastructure Overview

| Component | Details |
|-----------|---------|
| **Server** | Hetzner VPS |
| **OS** | Ubuntu 24.04 LTS |
| **Domain** | `cooperationtulsa.org` (Namecheap) |
| **Stack** | Ghost 5 + MySQL 8 (Docker), nginx reverse proxy, Let's Encrypt SSL |
| **Mail** | Resend (SMTP) |
| **Analytics** | Umami (self-hosted at `analytics.cooperationtulsa.org`) |

## Server Architecture

```
Internet
  │
  ├─ :80  ──► nginx ──► 301 redirect to HTTPS
  └─ :443 ──► nginx (SSL termination) ──► 127.0.0.1:2368 (Ghost container)
                                                │
                                          MySQL container (internal)
```

- **nginx** handles SSL, HTTP→HTTPS redirects, and www→non-www redirects
- **Ghost** runs in Docker, bound to localhost only (not publicly exposed)
- **MySQL 8** runs in Docker with a persistent named volume
- **Certbot** auto-renews SSL certificates via systemd timer
- **Umami** analytics runs on a separate Docker stack with PostgreSQL

## Key Paths on Server

| What | Path |
|------|------|
| Ghost project root | `/opt/cooperation-tulsa/` |
| Ghost Docker Compose | `/opt/cooperation-tulsa/docker-compose.yml` |
| Ghost environment | `/opt/cooperation-tulsa/.env` |
| Ghost content | `/opt/cooperation-tulsa/ghost/content/` |
| Theme files | `/opt/cooperation-tulsa/ghost/content/themes/cooperation-tulsa/` |
| Umami project root | `/opt/umami/` |
| Nginx configs | `/etc/nginx/sites-available/` |
| SSL certificates | `/etc/letsencrypt/live/` |

## Admin Access

- **Ghost Admin:** `https://cooperationtulsa.org/ghost/`
- **Analytics:** `https://analytics.cooperationtulsa.org`
- Credentials stored securely — not in this repo.

## DNS Configuration (Namecheap)

| Type | Host | Value |
|------|------|-------|
| A | `@` | Server IP |
| A | `www` | Server IP |
| A | `analytics` | Server IP |
| TXT/CNAME | *(Resend records)* | *(See Resend dashboard)* |

## Common Operations

### Deploy theme changes

```bash
rsync -avz -e "ssh -i ~/.ssh/hetzner_cooperation_tulsa" \
  ghost/content/themes/cooperation-tulsa/ \
  root@SERVER:/opt/cooperation-tulsa/ghost/content/themes/cooperation-tulsa/

ssh -i ~/.ssh/hetzner_cooperation_tulsa root@SERVER \
  "cd /opt/cooperation-tulsa && docker compose restart ghost"
```

### Deploy image/content changes

```bash
rsync -avz -e "ssh -i ~/.ssh/hetzner_cooperation_tulsa" \
  ghost/content/images/ \
  root@SERVER:/opt/cooperation-tulsa/ghost/content/images/
```

No restart needed — images are served directly.

### View logs

```bash
# Ghost logs
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@SERVER \
  "cd /opt/cooperation-tulsa && docker compose logs ghost --tail 50"

# Nginx logs
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@SERVER \
  "tail -50 /var/log/nginx/access.log"
```

## Database Operations

### Export database (backup)

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@SERVER 'bash -s' << 'EOF'
source /opt/cooperation-tulsa/.env
docker exec cooperation-tulsa-db-1 \
  mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ghost > /opt/cooperation-tulsa/backup-$(date +%Y%m%d).sql
EOF
```

### Import database

```bash
scp -i ~/.ssh/hetzner_cooperation_tulsa backup.sql root@SERVER:/tmp/

ssh -i ~/.ssh/hetzner_cooperation_tulsa root@SERVER 'bash -s' << 'EOF'
source /opt/cooperation-tulsa/.env
docker exec -i cooperation-tulsa-db-1 \
  mysql -u root -p${MYSQL_ROOT_PASSWORD} ghost < /tmp/backup.sql
cd /opt/cooperation-tulsa && docker compose restart ghost
EOF
```

### Clear image cache

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@SERVER \
  "rm -rf /opt/cooperation-tulsa/ghost/content/images/size/* && \
   cd /opt/cooperation-tulsa && docker compose restart ghost"
```

## SSL Certificates

Certificates are issued by Let's Encrypt and auto-renew via certbot's systemd timer.

- **Renewal check:** runs twice daily via `certbot.timer`
- **Post-renewal hook:** automatically reloads nginx

### Manual renewal (if needed)

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@SERVER \
  "certbot renew && systemctl reload nginx"
```

## Mail (Resend)

Ghost uses Resend for transactional email (magic link sign-ins, newsletter confirmations). SMTP credentials are stored in `/opt/cooperation-tulsa/.env` on the server. The sending domain `cooperationtulsa.org` is verified in the Resend dashboard.

## Security

- SSH: key-only authentication, password auth disabled, fail2ban active
- UFW firewall: only ports 22, 80, 443 open
- Ghost admin API rate-limited via nginx
- nginx server version hidden, X-Powered-By header stripped
- HSTS, X-Frame-Options, X-Content-Type-Options headers set
- Unattended security upgrades enabled

## Routes Configuration

Custom routes are defined in `ghost/content/settings/routes.yaml`:

```yaml
routes:
  /donate/:
    template: page-donate
  /gallery/:
    template: custom-gallery
  /about/:
    template: page-about

collections:
  /:
    permalink: /blog/{slug}/
    filter: tag:-events+tag:-resources
    template: index
  /events/:
    permalink: /events/{slug}/
    filter: tag:events
    template: custom-events
  /resources/:
    permalink: /resources/{slug}/
    filter: tag:resources
    template: custom-resources

taxonomies:
  tag: /tag/{slug}/
```

After modifying routes, restart Ghost for changes to take effect.
