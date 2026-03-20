# Cooperation Tulsa — Content Creator Guide

This guide is for anyone publishing content on cooperationtulsa.org. You don't need access to the source code — everything is done through Ghost Admin.

**Ghost Admin:** `https://cooperationtulsa.org/ghost/`

---

## Creating a Blog Post

Blog posts appear on the homepage under "Latest Updates."

1. Go to Ghost Admin → **Posts** → **New post**
2. Write your title and content using the editor
3. Add a **feature image** at the top (wide landscape photos work best)
4. Click the **gear icon** (top right) to open post settings:
   - **Excerpt:** Write a 1-2 sentence summary. This shows on the homepage card and in social media previews.
   - **Tags:** Do NOT add `events` or `resources` tags unless the post is specifically an event or resource (see below). Regular blog posts should have no tag, or tags like `news`, `garden`, `recap`, etc.
5. Click **Publish** → choose **"Publish"** (website only) or **"Email"** (also sends newsletter to subscribers)

### Tips
- Use H2 (`##`) for section headings within posts
- Add images throughout — they break up text and make posts shareable
- The first image and excerpt are what show up when the post is shared on social media

---

## Creating an Event

Events appear on the `/events/` page.

1. Go to Ghost Admin → **Posts** → **New post**
2. Write the event title (e.g., "Work Day at Flat Rock — March 29")
3. Add event details in the body: date, time, location, what to bring
4. Add a feature image (flyer or relevant photo)
5. Open post settings (gear icon) and:
   - **Add the tag `events`** — this is what makes it appear on the events page instead of the blog
   - Write an excerpt with the key details (date, time, location)
6. Publish

### Important
- The tag must be exactly `events` (lowercase) — this is how the site routes the post to the events page
- Posts tagged `events` will NOT appear on the homepage "Latest Updates" — they only show on `/events/`

---

## Creating a Resource

Resources added through Ghost appear on the `/resources/` page under "Articles & Guides."

1. Go to Ghost Admin → **Posts** → **New post**
2. Write the resource title and content
3. Open post settings (gear icon) and:
   - **Add the tag `resources`** — this routes it to the resources page
   - Optionally add a second tag for categorization (e.g., `reading-list`, `guides`, `theory`, `how-to`)
4. Publish

### Important
- The tag must be exactly `resources` (lowercase)
- Posts tagged `resources` will NOT appear on the homepage — they only show on `/resources/`
- The static resource library (books, tools, coalition partners) is managed in the theme source code — talk to an admin to add entries there

---

## Tag Reference

| Tag | What it does |
|-----|-------------|
| `events` | Routes the post to the Events page (`/events/`) |
| `resources` | Routes the post to the Resources page (`/resources/`) |
| Any other tag | Post stays on the homepage under "Latest Updates" |

You can add multiple tags, but `events` and `resources` control where the post appears. If a post has the `events` tag, it won't show on the homepage even if it has other tags.

---

## Sending a Newsletter

Ghost can email your post to all subscribers when you publish.

1. Write your post as normal
2. When you click **Publish**, you'll see options:
   - **Publish only** — post goes on the website
   - **Email** — post is emailed to subscribers AND published on the website
   - **Send only** — email only, not published on the website
3. Select your option and confirm

Newsletters are sent via Resend through the `cooperationtulsa.org` domain.

---

## Managing Members

Members are people who subscribed through the site.

- View all members: Ghost Admin → **Members**
- Export member list: Members → gear icon → **Export**
- Members receive newsletters when you publish with the "Email" option

---

## Images

- **Feature images** should be landscape orientation, at least 1200px wide
- Ghost automatically resizes images for different screen sizes
- Preferred format: JPG or WebP (not PNG for photos — files are too large)
- If you replace an image file on the server, the cached resized versions need to be cleared (ask an admin)

---

## Quick Reference

| Action | Where |
|--------|-------|
| Write a blog post | Posts → New post → Publish |
| Create an event | Posts → New post → tag with `events` → Publish |
| Add a resource article | Posts → New post → tag with `resources` → Publish |
| Send newsletter | Publish → choose "Email" option |
| View subscribers | Members |
| Edit site settings | Settings |
| Upload a theme | Settings → Design → Upload theme |
