# SMTP Setup — Resend for Cooperation Tulsa

## 1. Resend Account Setup

1. Sign in at [resend.com](https://resend.com)
2. Go to **Domains** → **Add Domain** → enter `cooperationtulsa.org`
3. Resend will provide DNS records to verify domain ownership

## 2. DNS Records (Namecheap)

Add the records Resend provides. They will look like:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| TXT | `@` | `v=spf1 include:resend.com ~all` (or append to existing SPF) | Auto |
| CNAME | `resend._domainkey` | *(Resend provides this)* | Auto |
| CNAME | *(Resend provides)* | *(Resend provides)* | Auto |
| TXT | `_dmarc` | `v=DMARC1; p=none;` | Auto |

**Important:** If you already have an SPF record, don't create a second TXT record. Instead, add `include:resend.com` to the existing one.

Wait for Resend to show the domain as **Verified** before proceeding.

## 3. Create API Key

1. In Resend, go to **API Keys** → **Create API Key**
2. Name: `Ghost CMS`
3. Permission: **Sending access**
4. Domain: `cooperationtulsa.org`
5. Copy the key (starts with `re_`)

## 4. Configure Ghost

SSH into the server and update the environment file:

```bash
ssh -i ~/.ssh/hetzner_cooperation_tulsa root@5.78.145.143
```

Edit `/opt/cooperation-tulsa/.env` and add:

```
MAIL_HOST=smtp.resend.com
MAIL_PORT=587
MAIL_USER=resend
MAIL_PASS=re_YOUR_API_KEY_HERE
```

Then update the docker-compose to use these variables (already configured):

```bash
cd /opt/cooperation-tulsa
docker compose restart ghost
```

## 5. Update Ghost Sender Address

In Ghost Admin (`https://cooperationtulsa.org/ghost/`):

1. Go to **Settings** → **Email newsletter**
2. Set sender email to `noreply@cooperationtulsa.org` (or whatever you prefer)
3. This must match the verified domain in Resend

## 6. Test

1. Go to your site and subscribe with your email
2. Check that you receive the magic link / confirmation email
3. Check Resend dashboard to confirm delivery

## SMTP Settings Reference

| Setting | Value |
|---------|-------|
| Host | `smtp.resend.com` |
| Port | `587` (STARTTLS) |
| Username | `resend` |
| Password | Your API key (`re_...`) |
| From address | `noreply@cooperationtulsa.org` |
