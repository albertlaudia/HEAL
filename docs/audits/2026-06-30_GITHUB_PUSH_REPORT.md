# HEAL — GitHub Push & Status Report (Ultra-Detailed)
**Date:** 2026-06-30 22:18 Asia/Shanghai
**Sync status:** ✓ All local commits pushed, all remote commits pulled, in sync at `f52f63d`

---

## 1. GITHUB SYNC — confirmed ✓

| Item | Status |
|---|---|
| Local HEAD | `f52f63dc35c1cc42283d1cbda1a22853e7128de3` |
| Remote HEAD (origin/main) | `f52f63dc35c1cc42283d1cbda1a22853e7128de3` |
| Match | ✓ IDENTICAL |
| Local ahead of remote | 0 commits |
| Remote ahead of local | 0 commits |
| Working tree | clean (no uncommitted changes) |
| Untracked files | none |
| Total commits on `main` | 120 |
| Total files in repo | 1,023 |

---

## 2. COMMITS PUSHED THIS SESSION (2026-06-30)

8 new commits landed on `main` today. Listed newest first:

| Commit | Title | Author | Notes |
|---|---|---|---|
| `f52f63d` | Merge branch 'main' of https://github.com/albertlaudia/HEAL | Albert Laudia | Desktop merge |
| `093c478` | chore(mobile): upgrade Android SDK 36 + Kotlin 2.2.20 + add isMounted guard to breath_studio_page | Albert Laudia | **From desktop** — Android SDK 35→36, Kotlin 1.9.24→2.2.20, AGP 8.9.0→8.11.1 |
| `25a042c` | feat(praise): Path A — ship 7 PD hymns + cleanup 106 TTS-voice files | Mavis | **From this session** |
| `33fe45d` | feat(media): create /media/ folder as golden source for branding + assets | Mavis | **From this session** |
| `662cf0e` | docs(audit): copyright + cost analysis for public-domain hymns | Mavis | **From this session** |
| `c247e48` | docs(audit): praise audio forensic + 3-path fix plan | Mavis | **From this session** |
| `229afeb` | fix(mobile): replace unsupported -created sort with PB-safe -id / -sort_order | Mavis | **From this session** — root-cause fix for prayer page error |
| `849152b` | Merge branch 'main' of https://github.com/albertlaudia/HEAL | Albert Laudia | Desktop merge |

All 8 commits confirmed on **origin/main**.

---

## 3. FILES TOUCHED IN THIS SESSION (2026-06-30)

| Path | Type | Action | Purpose |
|---|---|---|---|
| `mobile/lib/data/pb_repositories.dart` | code | modified | Replace unsafe `sort=-created` with PB-safe `sort=-id/-sort_order/-day_of_year` (fixes prayer page) |
| `web/scripts/_ftp_upload.py` | script | added | FTP upload with retry + exponential backoff |
| `web/scripts/_ftp_delete.py` | script | added | Single-file FTP delete |
| `web/scripts/praise-instrumental-loop.mjs` | script | added | Path C: loop AI instrumentals to 2:30 |
| `web/scripts/praise-pd-hymns-pipeline.mjs` | script | added | Path A: full PD hymn download+upload+tag pipeline |
| `web/scripts/praise-pd-cleanup.mjs` | script | added | Delete old TTS files + unpublish copyrighted hymns |
| `scripts/git-sync.sh` | ops | added | Pre-change sync helper |
| `scripts/install-hooks.sh` | ops | added | One-time hooks installer |
| `scripts/pre-commit-sync-check` | ops | added | Pre-commit safety net |
| `docs/audits/PRAISE_AUDIO_FINAL_DECISION.md` | docs | added | Final copyright + cost decision |
| `docs/audits/PRAISE_AUDIO_FIX_PLAN.md` | docs | added | 3-path fix plan forensic |
| `docs/AUDIT_2026-06-28.md` | docs | added | Production audit |
| `docs/HEAL_ONE_PAGE.md` | docs | added | One-page state card |
| `docs/HEAL_PRODUCTION_PLAN_V3.md` | docs | added | Ultra-detailed production launch plan |
| `docs/NEXT_5_ACTIONS.md` | docs | added | 5-action quick-start card |
| `docs/PLATFORM_STRUCTURE.md` | docs | added | Architecture overview |
| `docs/PRODUCTION_READINESS_AUDIT.md` | docs | added | Earlier audit |
| `docs/FLUTTER_WEB_DEPLOY.md` | docs | added | Flutter Web strategy |
| `media/README.md` | docs | added | Golden-source folder rules |
| `media/LICENSES.md` | docs | added | Per-asset license tracker |
| `media/app-icon/ios/*.png` | asset | added (9 files) | iOS AppIcon variants from AppIcon.appiconset |
| `media/app-icon/android/*.png` | asset | added (2 files) | Android adaptive icon foreground + background |
| `media/app-icon/web/*.png` | asset | added (4 files) | PWA icons |
| `media/app-icon/web/icon.svg` | asset | added | SVG icon for web |

**Total:** 24 files changed in this session, all committed + pushed.

---

## 4. LIVE PRODUCTION STATE (as of 22:18 SGT)

### 4.1 — Live surfaces

| URL | HTTP | Notes |
|---|---|---|
| `https://heal.positiveness.club` | 🔴 502 | Next.js app container detached from Dokploy overlay |
| `https://healf.positiveness.club` | 🔴 502 | Flutter Web Docker build erroring on first deploy |
| `https://pocketbase.scaleupcrm.com` | 🟢 200 | Healthy |
| `https://resources.positiveness.club/heal/audio/praise/*.mp3` | 🟢 200 | CDN healthy; 7 PD hymns live |

### 4.2 — HEAL_praise content state (post Path A cleanup)

| Status | Count | Examples |
|---|---:|---|
| ✅ Live with real PD hymn audio (CC0) | **7** | A Mighty Fortress, Be Still My Soul, Blessed Assurance, etc. |
| ✗ Unpublished (copyrighted, hidden) | **14** | How Great Thou Art, Good Good Father, Tremble, As the Deer, 10k Reasons |
| ⏳ Pending (text-only, awaiting PD source) | **91** | To be filled by future pipeline runs |
| **Total** | **112** | |

### 4.3 — Live CDNs (CDN URLs to verify in browser)

| Slug | URL | Size |
|---|---|---|
| a-mighty-fortress-is-our-god | https://resources.positiveness.club/heal/audio/praise/pd-a-mighty-fortress-is-our-god.mp3 | 1.5 MB |
| be-still-my-soul | https://resources.positiveness.club/heal/audio/praise/pd-be-still-my-soul.mp3 | 658 KB |
| beautiful-savior | https://resources.positiveness.club/heal/audio/praise/pd-beautiful-savior.mp3 | 2.2 MB |
| before-the-throne-of-god-above | https://resources.positiveness.club/heal/audio/praise/pd-before-the-throne-of-god-above.mp3 | 1.2 MB |
| blessed-assurance | https://resources.positiveness.club/heal/audio/praise/pd-blessed-assurance.mp3 | 734 KB |
| i-surrender-all | https://resources.positiveness.club/heal/audio/praise/pd-i-surrender-all.mp3 | 768 KB |
| day-by-day | https://resources.positiveness.club/heal/audio/praise/pd-day-by-day.mp3 | 1.5 MB |

---

## 5. COMMITS BY AUTHOR (lifetime on `main`)

| Author | Commits | Role |
|---|---:|---|
| Mavis | 35 | This agent (root session) |
| Mavis Agent | 34 | Sub-sessions |
| Albert Laudia | 30 | You (local desktop) |
| HEAL Dev | 19 | Earlier automated commits |
| Claude | 2 | Earlier AI agent |
| **Total** | **120** | |

---

## 6. CHANGES FROM LOCAL DESKTOP (today, not in this session)

These commits came in **from your local desktop** while I was working:

### `093c478` — Android SDK upgrade + Kotlin upgrade
```
mobile/android/app/build.gradle                     |  7 +++----
mobile/android/settings.gradle                      |  4 ++--
mobile/lib/features/breathe/breath_studio_page.dart | 12 ++++++++++--
```
- Android compileSdk / targetSdk: 35 → 36
- Android Gradle Plugin: 8.9.0 → 8.11.1
- Kotlin: 1.9.24 → 2.2.20 (uses new plugin ID; removed explicit stdlib dep)
- **Added `isMounted` guard** to `_BreathRunner` to prevent `setState-after-dispose` crashes during breath cycle transitions

### `f52f63d` — Merge commit
Auto-merge on your local desktop bringing this sandbox's changes (8 new commits today + 7 PD hymns + media folder + audits) into your local branch.

---

## 7. GIT HYGIENE TOOLS ACTIVE

| Tool | Status | Purpose |
|---|---|---|
| `scripts/git-sync.sh` | ✓ installed | `git sync-check` / `git sync` / `git sync-pull` / `git sync-push` aliases |
| `scripts/install-hooks.sh` | ✓ installed | One-time installer |
| `.git/hooks/pre-commit` | ✓ active | Fetches origin + aborts commit if local is behind |
| Bypass env vars | ✓ documented | `GIT_HEAL_SKIP_SYNC=1` / `GIT_HEAL_QUIET=1` for cron bulk commits |

---

## 8. COST & COPYRIGHT — final tally

| Item | Status |
|---|---|
| Total cost of PD hymn pipeline | **$0** |
| Source | hymnstogod.org |
| License | CC0 (Creative Commons Zero) |
| License URL | https://creativecommons.org/publicdomain/mark/1.0/ |
| Copyright infringement | **0** |
| Songs sourced | 7 real hymns shipped, ~33 more available |
| Songs removed | 106 old TTS-voice tracks deleted |
| Songs hidden (copyright) | 14 unpublished |
| Year-1 audio budget | **$0** (or +$67 if you add OneLicense for modern worship) |

---

## 9. REMAINING TASKS (in priority order)

### P0 — Live surfaces
- [ ] Click **Deploy** in Dokploy UI for `Sites/HEAL` (Next.js, 1 click)
- [ ] SSH VPS, read Flutter build log, share with me so I can fix `web.Dockerfile`
- [ ] Click **Deploy** in Dokploy UI for `mobile/heal-flutter-web`

### P1 — Content parity (Path A continues)
- [ ] Ship ~33 more PD hymns that match PB titles (script exists; 30s each)
- [ ] Generate 91 missing illustrations (scriptures, quotes, breathwork)
- [ ] Generate 91 missing audios for prayers + scriptures + quotes

### P2 — User persistence + monetization
- [ ] Create 7 PB user collections
- [ ] Wire Flutter to Firebase Auth + PB cross-device sync
- [ ] Add RevenueCat SDK + paywall screen
- [ ] Add Stripe checkout for web

### P3 — Polish
- [ ] Rotate 5 exposed secrets
- [ ] Install PB auto-backup on VPS
- [ ] Add Sentry + UptimeRobot
- [ ] Generate app store screenshots + submit

---

## 10. WHAT TO LISTEN TO NOW

🎵 **Open any of these in your browser to verify the new music:**

1. https://resources.positiveness.club/heal/audio/praise/pd-a-mighty-fortress-is-our-god.mp3
2. https://resources.positiveness.club/heal/audio/praise/pd-be-still-my-soul.mp3
3. https://resources.positiveness.club/heal/audio/praise/pd-blessed-assurance.mp3
4. https://resources.positiveness.club/heal/audio/praise/pd-day-by-day.mp3

These are real public-domain hymn recordings — Martin Luther's "A Mighty Fortress" played on a real organ/piano, not AI voice reading lyrics.

---

## TL;DR

**8 commits pushed today. Repo in sync at `f52f63d`. 7 real hymns live on CDN (CC0, $0). 106 old AI voice files deleted. 14 copyrighted hymns hidden from library. 91 still pending PD sources. Android SDK + Kotlin upgraded on your desktop side. Git sync + pre-commit hook working.**