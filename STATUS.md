# Cooperation Tulsa Ghost Site — Status & QA Report

## Infrastructure

| Component | Details |
|-----------|---------|
| **Platform** | Ghost 5.130.6 in Docker |
| **Container** | LXC CT 202 on Proxmox cluster02 (192.168.50.201) |
| **Container IP** | 192.168.50.198 |
| **Site URL** | http://192.168.50.198:2368 |
| **Ghost Admin** | http://192.168.50.198:2368/ghost/ |
| **Admin Login** | admin@cooperationtulsa.org / CoopTulsa2024! |
| **Database** | MySQL 8 (Docker service) |
| **Mail** | MailHog (dev only, captures at :8025) |
| **Docker Compose** | `/opt/ghost-website/docker-compose.yml` (inside CT 202) |
| **Theme Location** | `/opt/ghost-website/ghost/content/themes/cooperation-tulsa/` (inside CT 202) |
| **Content API Key** | `86f7080ff42494b291198590e8` |

---

## What Has Been Done

### Theme Development
- Built complete custom Ghost theme `cooperation-tulsa` (v1.0.0)
- Earthy design palette: forest green, sage, wheat, cream, sand, clay, soil, charcoal
- Fonts: DM Serif Display (headings) + Source Sans 3 (body) via Google Fonts
- Fully responsive with mobile hamburger nav

### Templates Created (16 total)
| Template | Purpose | Status |
|----------|---------|--------|
| `default.hbs` | Base layout (header, main, footer) | Working |
| `index.hbs` | Homepage — hero, mission, featured projects, recent posts, events, newsletter | Working |
| `post.hbs` | Blog post — tag, title, author, date, reading time, feature image, content | Working |
| `page.hbs` | Generic page — title, feature image, content | Working |
| `page-about.hbs` | About page — custom template with mission, history, principles | Working |
| `page-donate.hbs` | Donate page — 4 donation options, Open Collective link | Working |
| `page-projects.hbs` | Projects page — dynamic cards grouped by Active / Community-Managed / Archived | Working |
| `custom-events.hbs` | Events collection — recurring schedule (hardcoded) + dynamic event posts | Working (empty dynamic section) |
| `custom-resources.hbs` | Resources collection — filter tabs + dynamic resource posts | Working (empty, shows placeholder) |
| `tag.hbs` | Tag archive page | Working |
| `error.hbs` | Generic error page | Working |
| `error-404.hbs` | 404 page | Working |

### Partials (9 total)
| Partial | Purpose |
|---------|---------|
| `header.hbs` | Sticky header, logo/title, Ghost `{{navigation}}`, Donate button |
| `footer.hbs` | 3-column footer: description + social, nav links, newsletter |
| `post-card.hbs` | Blog post card with image, tag, title, excerpt, date |
| `project-card.hbs` | Project card with status badge |
| `event-card.hbs` | Event card with date badge |
| `resource-card.hbs` | Resource card with tag badge |
| `pagination.hbs` | Prev/next page links |
| `newsletter-form.hbs` | Email subscribe form (Ghost members) |
| `bookchin-quote.hbs` | Murray Bookchin quote block |

### Custom Routes (routes.yaml)
```yaml
routes:
  /donate/:
    template: page-donate

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

### Ghost Content Created
**Pages (3):**
- About (`/about/`) — uses `page-about.hbs`
- Donate (`/donate/`) — uses `page-donate.hbs`
- Projects (`/projects/`) — uses `page-projects.hbs`

**Posts (7, all tagged `#project`):**
| Post | Internal Tags | Featured |
|------|---------------|----------|
| Flat Rock Urban Garden | #project, #active | Yes |
| Popular Education | #project, #active | Yes |
| Organizer Education | #project, #active | No |
| Tabling and Infoshop | #project, #active | Yes |
| Church of the Restoration Garden | #project, #community-managed | No |
| Vernon AME Community Garden | #project, #community-managed | No |
| Community Center | #project, #archived | No |

### Bugs Fixed
1. **post.hbs empty variables** — Template was a debug stub without `{{!< default}}` or `{{#post}}` block. Replaced with full post template.
2. **Ghost URL set to localhost** — Nav links pointed to `http://localhost:2368` which was unreachable from the browser. Updated `docker-compose.yml` to use `http://192.168.50.198:2368`.

---

## QA Sweep Results (2026-02-13)

### Pages — All Return HTTP 200

| Page | URL | Renders | Content |
|------|-----|---------|---------|
| Homepage | `/` | OK | Hero, mission, 3 featured projects, post cards, newsletter |
| Projects | `/projects/` | OK | 3 active, 2 community-managed, 1 archived project cards |
| Events | `/events/` | OK | 4 hardcoded recurring events, empty "Event Updates" section |
| Resources | `/resources/` | OK | Filter tabs, "Resources are being gathered" placeholder |
| About | `/about/` | OK | Full mission/history/principles content |
| Donate | `/donate/` | OK | 4 donation options with Open Collective link |
| Blog Post | `/blog/flat-rock-urban-garden/` | OK | Title, author, date, content all render |
| 404 | `/nonexistent/` | OK | Custom error page |

---

## Open Issues / TODO

### Bugs
- [ ] **Author links go to /404/** — On post pages, "By Cooperation Tulsa" links to `/404/` instead of a valid author page or being unlinked. Fix in `post.hbs`.

### Content Gaps
- [ ] **No event posts exist** — The `/events/` "Event Updates" section is empty because no posts are tagged with the public tag `events`. Need to either create event posts with that tag, or remove the dynamic section.
- [ ] **No resource posts exist** — The `/resources/` page is entirely empty (shows placeholder text). Need to create posts tagged `resources` (and optionally sub-tagged `reading-list`, `guides`, `theory`, `how-to`).
- [ ] **Resource filter tabs lead to empty tag pages** — The tabs link to `/tag/reading-list/`, `/tag/guides/`, etc. which will be empty or 404 until tagged content exists.
- [ ] **Homepage "Latest Updates" section** — Shows the same project posts as cards since no non-project blog posts exist. Consider creating actual blog/news posts or hiding section when empty.

### Navigation
- [ ] **Donate not in Ghost navigation** — The Donate button in the header uses `{{@custom.donation_url}}` and renders as an external link to Open Collective. It is NOT in the Ghost `{{navigation}}` helper, so it only appears because it's hardcoded in `header.hbs`. Verify the custom theme setting `donation_url` is configured in Ghost Admin > Settings > Design.

### Configuration
- [ ] **Ghost URL is hardcoded IP** — Currently `http://192.168.50.198:2368`. Will need updating when a real domain is configured.
- [ ] **mail.from not configured** — Ghost warns about missing mail config; emails will use a generated address.
- [ ] **Theme validation warning** — Ghost logs: "The currently active theme has errors, but will still work." Related to `{{@page}}` global not being implemented (Beta editor feature). Non-blocking.

### Production Readiness
- [ ] **No HTTPS** — Site runs on plain HTTP.
- [ ] **No reverse proxy** — Ghost exposed directly on port 2368. Should be behind Nginx/Caddy with proper domain.
- [ ] **No backups configured** — No automated backup of Ghost content or MySQL database.
- [ ] **DHCP IP** — Container IP (192.168.50.198) is DHCP-assigned, not reserved. Could change on reboot.
- [ ] **Social media URLs not configured** — `discord_url`, `instagram_url`, `facebook_url`, `twitter_url` theme settings are empty.
- [ ] **No favicon/logo uploaded** — Site uses text title, no logo image configured in Ghost Admin.
