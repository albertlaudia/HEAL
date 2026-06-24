# HEAL — A Quiet Practice

> Daily Christian mindfulness. Guided meditations, breathwork, scripture, prayers, and a private journal — wrapped in a quiet, beautiful interface.

> **Live preview:** https://heal.positiveness.club

## Monorepo structure

This repo hosts both surfaces of HEAL — a single content model in PocketBase,
served by two clients:

```
HEAL/
├── web/           # Next.js 15 + React 19 — the primary web app (deployed)
├── mobile/        # Flutter 3.24+ — iOS + Android (in development)
├── docs/          # Content briefs, design notes
└── README.md
```

Both clients read the same `HEAL_*` collections from
`https://pocketbase.scaleupcrm.com/` and stream all media (illustrations,
audio, hymns) from the Cloudflare-fronted CDN at
`https://resources.positiveness.club/heal/`.

## Quick start

### Web (`/web`)

```bash
cd web
npm install --legacy-peer-deps
cp .env.example .env.local        # fill in PB_* + Firebase creds
npm run dev                       # http://localhost:3000
npm run build                     # production build
```

### Mobile (`/mobile`)

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=CDN_BASE=https://resources.positiveness.club/heal
```

> The mobile app's `defaultValue` for `CDN_BASE` already points at the
> production CDN. Override only if you point at a different environment.

## Content model (PocketBase)

All collections use the `HEAL_` prefix.

| Collection | Purpose | Count |
|---|---|---|
| `HEAL_meditations` | daily guided meditations, year-cycle (1-366) | 264 |
| `HEAL_praise` | hymns, contemporary praise, scripture chants, communion | 112 |
| `HEAL_prayers` | short prayers by category | 66 |
| `HEAL_essays` | long-form readings | 3 |
| `HEAL_breathwork` | 6 breath practices (4-7-8, box, etc.) | 6 |
| `HEAL_scriptures` | NRSV passages with reflection prompts | rotating |
| `HEAL_quotes` | 365 motivation/word-of-the-day entries | rotating |
| `HEAL_pages` | about, contact, legal | 3 |
| `HEAL_programs` + `HEAL_program_steps` | multi-day programs | rotating |
| `HEAL_badges` | earned-badge gallery | rotating |

## User data model (Firestore)

`/users/{uid}/favorites/{id}`, `/users/{uid}/journal/{id}`, `/users/{uid}/history/{id}`

Auth via Firebase Auth (Google + email/password). Session mirrored to an
HTTP-only JWT cookie for SSR on the web app.

## PWA / Offline (web only)

- `/sw.js` — network-first with cache fallback
- `manifest.json` — installable, with shortcuts to Today / Breathe / Scripture
- `InstallPrompt` component captures `beforeinstallprompt`

## Deployment (web → Dokploy)

Dokploy builds from `/web` (Dokploy `dockerfile` build context = `web/`).

Required env vars (set in Dokploy UI):
- `PORT=3000`
- `HOSTNAME=0.0.0.0`
- `PB_URL`, `PB_IDENTITY`, `PB_PASSWORD`
- `NEXT_PUBLIC_SITE_URL`, `HEAL_JWT_SECRET`
- `NEXT_PUBLIC_HEAL_CDN_URL=https://resources.positiveness.club/heal`
- 9 Firebase `NEXT_PUBLIC_*` vars

## Daily mechanic

Today is computed from `day_of_year()` (1-366) and looked up in
`HEAL_meditations` by `day_of_year`. Fallback to most-recent-published
if a day is empty. ISR refreshes the home page hourly so the day changes
at midnight.

## Mobile builds

CI workflow at `.github/workflows/mobile-build.yml` builds Android APK
on every push. iOS builds require a self-hosted runner with macOS + a
provisioning profile. Distribution is via internal TestFlight + Play
internal track.

## Tone & visual direction

- Calm, reverent, accessible — Christian mindfulness, not preachy-medical
- Dark Material 3 base with rosewood / brass / bronze palette
- Cormorant Garamond display, Inter body — both via Google Fonts on mobile
- Watercolor illustrations (AI-generated, see `web/scripts/generate-content.mjs`)
- Audio: TTS-generated at launch (multi-voice: Serene Woman, Sentimental
  Lady, Captivating Storyteller, Upbeat Woman, Passionate Warrior, Friendly
  Person, Gentle-voiced Man) + 100 generated praise vocals

## Built with care. Be still, and begin again.

