# HEAL — One-Page State (2026-06-29)

## 🚦 TRAFFIC LIGHT
| | Status |
|---|---|
| `heal.positiveness.club` (Next.js) | 🔴 502 |
| `healf.positiveness.club` (Flutter Web) | 🔴 502 |
| `pocketbase.scaleupcrm.com` | 🟢 200 |
| `resources.positiveness.club` | 🟢 200 |

## 📊 BUILT vs. MISSING (everything counted)

### Built (real, working code)

| Module | Count | Where |
|---|---:|---|
| Web pages (Next.js) | 18 routes | `web/app/` |
| Web components | 27 groups | `web/components/` |
| Flutter features | 11 | `mobile/lib/features/` |
| Flutter services | 4 | audio, notification, streak, voice |
| Flutter engagement | 6 | streak, voice cal, palette, in-pocket, sit-with-verse, welcome-back |
| Praise songs (full media) | 112 | PB |
| Meditations (text only) | 269 | PB |
| Prayers (text + image) | 67 | PB |
| Scriptures (text only) | 31 | PB |
| Quotes (text only) | 60 | PB |
| Essays (text + image) | 3 | PB |
| Breathwork (text only) | 6 | PB |
| Cron scripts | 55 | `web/scripts/` |
| Docs | 5 files | `docs/` |

### Missing (blockers for #1)

**P0 — Both surfaces DOWN:**
- Recover `heal.positiveness.club` (overlay detached)
- Recover `healf.positiveness.club` (Dockerfile build error)

**P1 — Content gaps (need for credibility):**
- 164 audios missing (67 prayers + 31 scriptures + 60 quotes + 6 breathwork)
- 97 images missing (31 scriptures + 60 quotes + 6 breathwork)
- 269 meditations missing `emotion` + `tags[]` field

**P1 — User persistence (mobile differentiator killed without this):**
- 0 user-data collections exist (`HEAL_users`, `HEAL_streaks`, `HEAL_mood`, etc.)
- Flutter mobile has `firebase_auth` in pubspec but 0 imports

**P1 — Monetization (zero revenue today):**
- No paywall, no Stripe, no RevenueCat, no subscription tier

**P2 — Polish:**
- 5 secrets exposed (GitHub PAT, PB password, Firebase key, JWT, Dokploy key)
- No backups running (`scripts/heal-backup/` exists but not installed)
- No tests (0 test files)
- No error reporting (no Sentry, no UptimeRobot)

## 🎯 BIGGER PICTURE — BE #1

### Market opportunity
- Headspace + Calm = $2B+ secular meditation, but generic
- Christian mindfulness = $50-100M annual market, <5% captured
- **Hallow** (12M users, $50M ARR) is the only true competitor — leaves Protestant/Evangelical/Orthodox uncontested
- YouVersion is a Bible app, not a mindfulness app

### The HEAL positioning
> "Headspace gives you 10 minutes of quiet.
>  HEAL gives you 10 minutes of Scripture, breath, and prayer.
>  For the hurried and the weary."

### Why we win (5-year moat)
1. **Theology depth** — Scripture-grounded every minute (vs Calm's "Christian add-on")
2. **5-min sessions** — Hallow's sessions are 10-30 min; the "I only have 5 min" tribe is bigger
3. **PWA-first** — works on any browser, install-prompt on iOS/Android
4. **Multi-language** — en + zh + ja + ms + ta by v1.0 (Hallow is en-only)
5. **Singapore base** — Asia-Pacific is the fastest-growing Christian region
6. **$4.99/mo Premium** — undercuts Hallow's $6.99
7. **Open content library** — like YouVersion but audio-first

### Pricing
| Tier | Price | What |
|---|---|---|
| Free | $0 | Daily meditation, 1 breath pattern, 1 prayer/day, all Scripture, all Praise |
| Premium | $4.99/mo | All patterns, voice calibration, all prayers, family sharing, offline |
| Family | $9.99/mo | 6 people + "Pray Together" + family reminders |

### Revenue math
- Year 1: 100k DL → 2k paid → **$120k ARR** (8x)
- Year 3: 1M DL → 30k paid → **$2M ARR**
- Year 5: 5M DL → 150k paid → **$10M ARR**
(Hallow hit ~$50M ARR with 12M users as the ceiling reference.)

## 📋 4-WEEK PLAN TO FIRST PAYING USER

### Week 1 — Recover surfaces (P0)
| When | Who | What |
|---|---|---|
| Day 1 | you | SSH VPS, run `tail -100 /etc/dokploy/logs/app-calculate-digital-bandwidth-h95pb2/app-calculate-digital-bandwidth-h95pb2-2026-06-28:02:23:07.log`, paste last 50 lines |
| Day 1 | me | Fix `web.Dockerfile` |
| Day 1 | you | Click Deploy in Dokploy UI for both `Sites/HEAL` and `mobile/heal-flutter-web` |
| Day 1 | you | Rotate 5 exposed secrets |
| Day 1 | me | Add kIsWeb guards on streak/sit-with-verse/welcome-back |
| Day 2 | me | Add "Begin Practice" cross-link on Next.js home |
| Day 3-5 | me | Backfill `emotion` + `tags[]` on 269 meditations + 9 other records |

### Week 2 — Content complete (P1)
| When | Who | What |
|---|---|---|
| Day 6-8 | me | TTS generate 164 missing audios (parallel batch via memory voice set) |
| Day 8-10 | me | Image gen 97 missing via wiki-commons-pipeline + gradient generator |
| Day 10-12 | me | Install PB auto-backup, add monitoring |

### Week 3 — User persistence + monetization
| When | Who | What |
|---|---|---|
| Day 13-15 | me | Create PB user collections (`HEAL_users`, `HEAL_sessions`, `HEAL_streaks`, `HEAL_mood`) |
| Day 15-18 | me | Wire Flutter to Firebase Auth + PB cross-device |
| Day 18-20 | me | RevenueCat SDK + paywall screen |

### Week 4 — Polish + launch
| When | Who | What |
|---|---|---|
| Day 21-23 | me | Stripe checkout for web + pricing page |
| Day 23-25 | me | App Store / Play Store metadata, screenshots, ASO |
| Day 25-28 | you/me | Submit to App Store + Play Store (7-day review) |

## 🚀 THE 5-YEAR ROADMAP

| Year | Milestone | Target |
|---|---|---|
| 2026 (now) | Both surfaces UP, content complete, first Premium subscriber | 100k DL, $120k ARR |
| 2027 | Multi-language (zh, ja, ms, ta), Family tier live | 1M DL, $2M ARR |
| 2028 | "Pray Together" 2-person sessions, AI Prayer Companion | 2.5M DL, $5M ARR |
| 2029 | Pastor partnerships, live prayer rooms | 4M DL, $8M ARR |
| 2030 | #1 mindfulness app for Christians globally | 5M+ DL, $10M ARR |

**Exit options (Year 5+):** Acquisition by YouVersion (LifeChurch), Glorify (another Christian app), or larger media (Salem, Hallow competitors).

## 🎬 WHAT I NEED FROM YOU NOW

```bash
# Most important — get me the Flutter build log so I can fix the Dockerfile
ssh root@84.247.174.141
tail -100 /etc/dokploy/logs/app-calculate-digital-bandwidth-h95pb2/app-calculate-digital-bandwidth-h95pb2-2026-06-28:02:23:07.log

# Then click Deploy in Dokploy UI for BOTH:
#   - Sites / HEAL (heal-app-apsqyt)
#   - mobile / heal-flutter-web (app-calculate-digital-bandwidth-h95pb2)

# Then rotate GitHub PAT:
#   github.com/settings/tokens → revoke ghp_Cxkc5kd...b9f3r5XF8
#   mint new, then: git remote set-url origin https://x-access-token:NEW_PAT@github.com/albertlaudia/HEAL.git
```

**Estimated time from now to both sites UP:** 30 minutes.
**Estimated time from now to first $1 of revenue:** 4-6 weeks.
