# Cooperation Tulsa

Website for [Cooperation Tulsa](https://cooperationtulsa.org) — a community organization in Tulsa, Oklahoma building power through urban gardens, popular education, mutual aid, and direct democracy.

Built with [Ghost](https://ghost.org/) and a custom Handlebars theme.

## Architecture

```
├── docker-compose.yml              # Ghost + MySQL + MailHog
├── .env                            # Database credentials (not in repo)
└── ghost/content/
    ├── settings/
    │   └── routes.yaml             # Custom routing config
    └── themes/
        └── cooperation-tulsa/      # Custom theme
            ├── assets/css/         # Stylesheets (variables.css, screen.css)
            ├── assets/js/          # Client JS (mobile nav toggle)
            ├── partials/           # Reusable components
            ├── default.hbs         # Base layout
            ├── index.hbs           # Homepage
            ├── post.hbs            # Blog post
            ├── page.hbs            # Generic page
            ├── page-about.hbs      # About page
            ├── page-donate.hbs     # Donate page
            ├── page-projects.hbs   # Projects page (dynamic, grouped by status)
            ├── custom-events.hbs   # Events collection
            ├── custom-resources.hbs # Resources collection
            ├── tag.hbs             # Tag archive
            ├── error.hbs           # Error page
            ├── error-404.hbs       # 404 page
            └── package.json        # Theme metadata & custom settings
```

## Routing

Defined in `ghost/content/settings/routes.yaml`:

| URL Pattern | Template | Content Source |
|---|---|---|
| `/` | `index.hbs` | Posts excluding `events` and `resources` tags |
| `/blog/{slug}/` | `post.hbs` | Individual posts |
| `/projects/` | `page-projects.hbs` | Ghost page, pulls posts tagged `#project` |
| `/events/` | `custom-events.hbs` | Collection filtered by `tag:events` |
| `/events/{slug}/` | `post.hbs` | Individual event posts |
| `/resources/` | `custom-resources.hbs` | Collection filtered by `tag:resources` |
| `/resources/{slug}/` | `post.hbs` | Individual resource posts |
| `/about/` | `page-about.hbs` | Ghost page |
| `/donate/` | `page-donate.hbs` | Static route |
| `/tag/{slug}/` | `tag.hbs` | Tag taxonomy |

## Content Model

Posts are organized using Ghost's internal tags (prefixed with `#`):

- **Projects:** Tagged `#project` + one of `#active`, `#community-managed`, or `#archived`
- **Events:** Tagged `events` (public tag) to appear in the events collection
- **Resources:** Tagged `resources` (public tag) + optional sub-tags: `reading-list`, `guides`, `theory`, `how-to`

## Theme Design

- **Fonts:** DM Serif Display (headings) + Source Sans 3 (body)
- **Palette:** Forest green (`#2D5F3E`), sage (`#4A7C59`), wheat (`#D4A843`), cream (`#FDF8F0`), sand (`#F5E6C8`), soil (`#5C3D2E`)
- **Responsive:** Mobile-first with hamburger nav at 768px breakpoint

### Custom Theme Settings

Configurable in Ghost Admin > Settings > Design:

| Setting | Description | Default |
|---|---|---|
| `donation_url` | Open Collective or donation page URL | `https://opencollective.com/cooperation-tulsa` |
| `discord_url` | Discord invite link | — |
| `instagram_url` | Instagram profile URL | — |
| `facebook_url` | Facebook page URL | — |
| `twitter_url` | Twitter/X profile URL | — |

## Deployment

### Prerequisites

- Docker and Docker Compose
- A server or LXC container with network access

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/YOUR_ORG/cooperation-tulsa.git
   cd cooperation-tulsa
   ```

2. Create `.env` with database credentials:
   ```bash
   MYSQL_ROOT_PASSWORD=your_root_password
   MYSQL_USER=ghost
   MYSQL_PASSWORD=your_db_password
   MYSQL_DATABASE=ghost
   ```

3. Set the Ghost URL in `docker-compose.yml`:
   ```yaml
   environment:
     url: http://your-domain-or-ip:port
   ```

4. Start the services:
   ```bash
   docker compose up -d
   ```

5. Access Ghost Admin at `http://your-url/ghost/` to create an admin account and configure the site.

6. Upload the custom routes file via Ghost Admin > Settings > Labs > Routes, or copy `ghost/content/settings/routes.yaml` into place.

### Current Deployment

| Component | Detail |
|---|---|
| Host | Proxmox cluster02 (192.168.50.201) |
| Container | LXC CT 202 (Debian, Docker) |
| Container IP | 192.168.50.198 |
| Ghost | Port 2368 |
| Ghost Admin | http://192.168.50.198:2368/ghost/ |
| MySQL | Internal Docker network (not exposed) |
| MailHog | Port 8025 (dev email capture) |

### Updating the Theme

After making changes to theme files locally:

```bash
# From the project root, zip and upload the theme
zip -r /tmp/theme.zip ghost/content/themes/cooperation-tulsa/

# Copy to server and extract
scp /tmp/theme.zip root@192.168.50.201:/tmp/
ssh root@192.168.50.201 'pct push 202 /tmp/theme.zip /tmp/theme.zip && \
  pct exec 202 -- bash -c "cd /tmp && unzip -o theme.zip && \
  rm -rf /opt/ghost-website/ghost/content/themes/cooperation-tulsa && \
  cp -r ghost/content/themes/cooperation-tulsa /opt/ghost-website/ghost/content/themes/"'

# Restart Ghost to pick up changes
ssh root@192.168.50.201 'pct exec 202 -- docker compose -f /opt/ghost-website/docker-compose.yml restart ghost'
```

Alternatively, upload the zipped theme through Ghost Admin > Settings > Design > Upload theme.

## License

MIT
