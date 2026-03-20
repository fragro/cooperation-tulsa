# Cooperation Tulsa — Deployment Guide

## Infrastructure Overview

| Component | Details |
|-----------|---------|
| **Server** | Hetzner VPS — `5.78.145.143` |
| **OS** | Ubuntu 24.04 LTS |
| **Specs** | 2GB RAM, 38GB disk |
| **Domain** | `cooperationtulsa.org` (Namecheap) |
| **Stack** | Ghost 5 + MySQL 8 (Docker), nginx reverse proxy, Let's Encrypt SSL |
| **SSH Key** | `~/.ssh/hetzner_cooperation_tulsa` |

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

## Key Paths on Server

| What | Path |
|------|------|
| Project root | `/opt/cooperation-tulsa/` |
| Docker Compose | `/opt/cooperation-tulsa/docker-compose.yml` |
| Environment / passwords | `/opt/cooperation-tulsa/.env` |
| Ghost content (themes, images, settings) | `/opt/cooperation-tulsa/ghost/content/` |
| Theme files | `/opt/cooperation-tulsa/ghost/content/themes/cooperation-tulsa/` |
| Nginx site config | `/etc/nginx/sites-available/cooperationtulsa.org` |
| SSL certificates | `/etc/letsencrypt/live/cooperationtulsa.org/` |
| SSL renewal hooks | `/etc/letsencrypt/renewal-hooks/post/reload-nginx.sh` |

## Admin Access

- **Ghost Admin:** `https://cooperationtulsa.org/ghost/`
- **Email:** `fragro@gmail.com`
- **Password:** `QIHKkiVWR0Q90UEYNDe4` *(change this after first login)*

## DNS Configuration (Namecheap)

| Type | Host | Value |
|------|------|-------|
| A | `@` | `5.78.145.143` |
| A | `www` | `5.78.145.143` |

## Common Operations

### SSH into the server

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143
```

### Deploy theme changes

After editing theme files locally:

```bash
rsync -avz -e "ssh -i ~/.ssh/hetzner_cooperation_tulsa" \
  ghost/content/themes/cooperation-tulsa/ \
  root@5.78.145.143:/opt/cooperation-tulsa/ghost/content/themes/cooperation-tulsa/

ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 \
  "cd /opt/cooperation-tulsa && docker compose restart ghost"
```

### Deploy image/content changes

```bash
rsync -avz -e "ssh -i ~/.ssh/hetzner_cooperation_tulsa" \
  ghost/content/images/ \
  root@5.78.145.143:/opt/cooperation-tulsa/ghost/content/images/
```

No restart needed — images are served directly.

### Restart Ghost

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 \
  "cd /opt/cooperation-tulsa && docker compose restart ghost"
```

### View logs

```bash
# Ghost logs
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 \
  "cd /opt/cooperation-tulsa && docker compose logs ghost --tail 50"

# Nginx logs
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 \
  "tail -50 /var/log/nginx/access.log"
```

### Check service status

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 \
  "cd /opt/cooperation-tulsa && docker compose ps"
```

## Database Operations

### Export database (backup)

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 'bash -s' << 'EOF'
source /opt/cooperation-tulsa/.env
docker exec cooperation-tulsa-db-1 \
  mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ghost > /opt/cooperation-tulsa/backup-$(date +%Y%m%d).sql
echo "Backup saved"
EOF
```

### Import database

```bash
scp -i ~/.ssh/hetzner_cooperation_tulsa backup.sql root@5.78.145.143:/tmp/

ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 'bash -s' << 'EOF'
source /opt/cooperation-tulsa/.env
docker exec -i cooperation-tulsa-db-1 \
  mysql -u root -p${MYSQL_ROOT_PASSWORD} ghost < /tmp/backup.sql
cd /opt/cooperation-tulsa && docker compose restart ghost
EOF
```

### Clear image cache

Ghost caches resized images. If you replace an image file on disk, clear the cache:

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 \
  "rm -rf /opt/cooperation-tulsa/ghost/content/images/size/* && \
   cd /opt/cooperation-tulsa && docker compose restart ghost"
```

## SSL Certificates

Certificates are issued by Let's Encrypt and auto-renew via certbot's systemd timer.

- **Certificate expires:** 2026-06-17 (auto-renews before then)
- **Renewal check:** runs twice daily via `certbot.timer`
- **Post-renewal hook:** automatically reloads nginx

### Manual renewal (if needed)

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 \
  "certbot renew && systemctl reload nginx"
```

### Check certificate status

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143 \
  "certbot certificates"
```

## Full Redeployment from Scratch

If you need to rebuild the server from a fresh Ubuntu 24.04 install:

```bash
# 1. Install dependencies
apt-get update
apt-get install -y ca-certificates curl gnupg nginx certbot

# 2. Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. From your local machine, sync everything
rsync -avz -e "ssh -i ~/.ssh/hetzner_cooperation_tulsa" \
  ghost/content/ root@5.78.145.143:/opt/cooperation-tulsa/ghost/content/

scp -i ~/.ssh/hetzner_cooperation_tulsa \
  docker-compose.yml root@5.78.145.143:/opt/cooperation-tulsa/
scp -i ~/.ssh/hetzner_cooperation_tulsa \
  .env root@5.78.145.143:/opt/cooperation-tulsa/

# 4. On the server: start services
cd /opt/cooperation-tulsa && docker compose up -d

# 5. Import database backup
docker exec -i cooperation-tulsa-db-1 mysql -u root -p<PASSWORD> ghost < backup.sql
docker compose restart ghost

# 6. Set up nginx config (see /etc/nginx/sites-available/cooperationtulsa.org)

# 7. Get SSL
certbot certonly --webroot -w /var/www/html \
  -d cooperationtulsa.org -d www.cooperationtulsa.org \
  --non-interactive --agree-tos --email fragro@gmail.com

# 8. Enable full nginx config and reload
nginx -t && systemctl reload nginx
```

## Mail Configuration

Ghost is configured to use SMTP for transactional emails (magic link sign-ins, newsletter confirmations). Set these in `/opt/cooperation-tulsa/.env`:

```
MAIL_HOST=smtp.mailgun.org
MAIL_PORT=587
MAIL_USER=postmaster@mg.cooperationtulsa.org
MAIL_PASS=your-mailgun-api-key
```

Then restart Ghost: `docker compose restart ghost`

Without mail configured, member sign-ups will fail to send confirmation emails.

## Routes Configuration

Custom routes are defined in `ghost/content/settings/routes.yaml`:

```yaml
routes:
  /donate/:
    template: page-donate
  /gallery/:
    template: custom-gallery

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
