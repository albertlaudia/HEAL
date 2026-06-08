# HEAL — A Quiet Practice

> Daily Christian mindfulness. Guided meditations, breathwork, scripture, prayers, and a private journal — wrapped in a quiet, beautiful interface.

> **Live preview:** https://app-bypass-wireless-bandwidth-jrb5a7-bd1242-84-247-174-141.sslip.io/

## Stack

- **Next.js 15** (App Router) + **React 19** + **TypeScript** + **Tailwind CSS**
- **PocketBase v0.39** for static content (`HEAL_` prefixed collections)
- **Backblaze B2** for media (audio, illustrations) under `HEAL/` root
- **Firebase Auth + Firestore** for user data (journal, favorites, history)
- **@vercel/og** for dynamic OG image generation per meditation
- **PWA** with offline support + install prompt
- **Deployed to Dokploy** (Railpack)

## Quick start

```bash
# Install
pnpm install    # or: npm install

# Copy env (edit with your B2 + PB creds before running)
cp .env.example .env.local

# Bootstrap PocketBase collections (idempotent)
pnpm pb:bootstrap

# Generate + seed launch content (90 meditations, 365 quotes, etc.)
pnpm content:generate
pnpm content:seed

# Upload generated media to B2
pnpm media:upload

# Dev
pnpm dev

# Build
pnpm build
```

## Project structure

```
app/                    # Next.js routes
  page.tsx              # /  — today's meditation, quote, breath, scripture
  meditate/             # /meditate  library + /meditate/[slug] player
  breathe/              # /breathe  breath studio
  scripture/            # /scripture
  prayers/              # /prayers
  essays/               # /essays + /essays/[slug]
  about, contact, privacy, terms
  opengraph-image.tsx   # dynamic OG image (root)
  meditate/[slug]/opengraph-image.tsx   # per-meditation OG card
  api/auth/session/     # Firebase ↔ cookie sync

components/
  auth/                 # AuthMenu, SessionSync
  content/              # SaveButton, ShareButton, JournalInline, ThemeBadge
  home/                 # DailyQuote, BreathWidget, ScriptureCard
  meditate/             # MeditationPlayer, MeditationFilters
  breathe/              # BreathStudio
  scripture/ prayers/   # list components
  nav/                  # Nav, Footer
  pwa/                  # InstallPrompt
  tracking/             # TrackView (localStorage recently viewed)

lib/
  firebase-client.ts    # client SDK (auth, firestore)
  firebase-server.ts    # admin SDK (firestore server-side)
  firebase-rest.ts      # auth REST verify + firestore helpers
  session.ts            # JWT cookie (jose)
  auth-store.ts         # React context
  pb.ts                 # PocketBase client
  utils.ts              # cn(), date helpers, theme palette

scripts/
  pb-bootstrap.mjs      # idempotent PB collections
  seed-content.mjs      # seed PB from /content JSON
  upload-media-to-b2.mjs# upload local media to B2/HEAL/
  generate-content.mjs  # AI-generate meditations, quotes, prayers, etc.

content/
  meditations/  quotes/  scriptures/  prayers/  breathwork/  essays/  pages/
  .url-map.json         # B2 URLs after upload (auto-generated)
```

## Content model (PocketBase)

All collections use the `HEAL_` prefix.

- `HEAL_meditations` — daily guided meditations, 90 at launch
- `HEAL_quotes` — 365 motivation/word-of-the-day entries
- `HEAL_scriptures` — NRSV passages with reflection prompts
- `HEAL_prayers` — short prayers by category
- `HEAL_breathwork` — 6 breath practices (4-7-8, box, etc.)
- `HEAL_essays` — long-form readings
- `HEAL_pages` — about, contact, legal

## User data model (Firestore)

`/users/{uid}/favorites/{id}`, `/users/{uid}/journal/{id}`, `/users/{uid}/history/{id}`

Auth via Firebase Auth (Google + email/password). Session mirrored to an HTTP-only JWT cookie for SSR.

## PWA / Offline

- `/sw.js` — network-first with cache fallback
- `manifest.json` — installable, with shortcuts to Today / Breathe / Scripture
- `InstallPrompt` component captures `beforeinstallprompt`

## Deployment

Deploys to Dokploy via the same Railpack pattern as `warisan-nusantara`:

```jsonc
// start
"start": "next start -p ${PORT:-3000} -H 0.0.0.0"
```

`memoryLimit` must be set in raw bytes (e.g. `1073741824`), not `"1g"`.

## Daily mechanic

Today is computed from `day_of_year()` (1-366) and looked up in `HEAL_meditations` by `day_of_year`. Fallback to most-recent-published if a day is empty. ISR refreshes the home page hourly so the day changes at midnight.

## Tone & visual direction

- Calm, reverent, accessible — Christian mindfulness, not preachy-medical
- Warm bone background, sage/dawn/mist accents, serif headings
- Watercolor illustrations (AI-generated, see `scripts/generate-content.mjs`)
- Audio: TTS-generated at launch, easily swappable to a cloned voice

## Built with care. Be still, and begin again.

_Last preview check: 2026-06-08T01:16:51Z_
