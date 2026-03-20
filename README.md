# Cooperation Tulsa

Website for [Cooperation Tulsa](https://cooperationtulsa.org) — a community organization in Tulsa, Oklahoma building power through urban gardens, popular education, mutual aid, and direct democracy.

Built with [Ghost](https://ghost.org/) and a custom Handlebars theme. Self-hosted on Hetzner with Resend for transactional email and Umami for privacy-respecting analytics.

## Architecture

```
├── docker-compose.yml              # Ghost + MySQL
├── .env                            # Credentials (not in repo)
├── DEPLOYMENT.md                   # Ops runbook
└── ghost/content/
    ├── images/                     # Site images and gallery media
    ├── settings/
    │   └── routes.yaml             # Custom routing config
    └── themes/
        └── cooperation-tulsa/      # Custom theme
            ├── assets/
            │   ├── css/            # fonts.css, variables.css, screen.css
            │   ├── fonts/          # Self-hosted DM Serif Display + Source Sans 3
            │   └── js/             # Mobile nav toggle
            ├── partials/           # Reusable components (header, footer, cards, etc.)
            ├── default.hbs         # Base layout
            ├── index.hbs           # Homepage
            ├── post.hbs            # Blog post
            ├── page.hbs            # Generic page
            ├── page-about.hbs      # About page
            ├── page-donate.hbs     # Donate page
            ├── custom-gallery.hbs  # Gallery with lightbox + video clips
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
| `/about/` | `page-about.hbs` | Static route |
| `/gallery/` | `custom-gallery.hbs` | Static route with embedded media |
| `/donate/` | `page-donate.hbs` | Static route |
| `/events/` | `custom-events.hbs` | Collection filtered by `tag:events` |
| `/resources/` | `custom-resources.hbs` | Collection filtered by `tag:resources` |
| `/tag/{slug}/` | `tag.hbs` | Tag taxonomy |

## Theme Design

- **Fonts:** DM Serif Display (headings) + Source Sans 3 (body), self-hosted
- **Palette:** Forest green, sage, wheat, cream, sand, soil
- **Responsive:** Mobile-first with hamburger nav at 768px breakpoint
- **Gallery:** CSS grid with lightbox for images, inline click-to-play for videos
- **No external tracking:** Fonts self-hosted, analytics via self-hosted Umami

### Custom Theme Settings

Configurable in Ghost Admin > Settings > Design:

| Setting | Description |
|---|---|
| `donation_url` | Open Collective or donation page URL |
| `discord_url` | Discord invite link |
| `instagram_url` | Instagram profile URL |
| `facebook_url` | Facebook page URL |
| `twitter_url` | Twitter/X profile URL |

## Development

```bash
# Start local dev environment
cp .env.example .env  # Edit with your credentials
docker compose up -d

# Access Ghost Admin
open http://localhost:2368/ghost/
```

Theme changes take effect on Ghost restart:

```bash
docker compose restart ghost
```

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for production deployment, operations, and maintenance.

## License

MIT
