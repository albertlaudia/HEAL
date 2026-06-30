# HEAL — Cost Model, Business Model, and Music Decision

> Status: pre-launch. Numbers are projections based on current architecture
> and May-2026 free-tier limits. Update quarterly.

---

## 1. Audio + content status (honest inventory)

### What plays today
| Asset | Count | Avg size | Total | Notes |
|---|---:|---:|---:|---|
| Voice meditations (B1) | 30 | 1.6 MB | 47 MB | Generated TTS, English Captivating Storyteller |
| Ambient tracks | 10 | 0.5 MB | 5 MB | Generated instrumental / room tone |
| Badge medallions | 6 | 0.04 MB | 0.2 MB | Watercolor, 1:1 webp |
| Prayer illustrations | 66 | 1.0 MB | 66 MB | Watercolor, 3:2 png (uncompressed) |
| Meditation illustrations | 250 | 1.5 MB | 370 MB | Watercolor, 3:2 png (uncompressed) |
| Praise illustrations | 0 | — | — | **None** |
| Essay illustrations | 0 | — | — | **None** |
| Scripture illustrations | 0 | — | — | **None** |
| **Praise song audio** | **0** | — | — | **None — lyrics + chords only** |
| Prayer audio | 0 | — | — | Optional future |
| Scripture audio | 0 | — | — | Optional future |
| Quote audio | 0 | — | — | Optional future |

### What's missing for true "1-366 day" coverage
- 336 more voice meditations (B2-B5)
- 170 more meditation illustrations
- 12 praise illustrations
- 3 essay illustrations
- Music for praise songs ← your question

**All of the above is "future" — the platform works fully without it. The /praise page is honest that these are lyrics + chords, not performances.**

---

## 2. Where the music would come from — the decision

Three options, ranked by my recommendation:

### Option A — AI-generated music (RECOMMENDED for MVP)
- **What:** Use a music-gen model (Suno, Udio, or our own batch_text_to_music) to generate simple instrumental arrangements from the chord charts we already have. No vocals — just piano/guitar/strings + light percussion, 2-3 minutes per song.
- **Pros:**
  - Free / near-free (~$0.10 per song with Suno Pro or our internal TTS-style pipeline)
  - Fully owned by positiveness.club — no licensing issues
  - Can match the mood/feel of each song (tempo, key signature, category all in our JSON)
  - 12 songs × 3 minutes = ~36 minutes of music total. Trivial to generate.
- **Cons:**
  - Won't be as polished as a real recording
  - Slight risk of model regurgitation (mitigated by using original chord progressions or public-domain melodies)
- **Effort:** Small. One week. Add `audio_url` to praise records, regenerate.
- **Cost:** $0 (our internal tool) or ~$1.20 (Suno Pro × 12)

### Option B — Royalty-free music library
- **What:** License 12-20 instrumental arrangements from a royalty-free service (Epidemic Sound, Artlist, or specifically Christian libraries like Royalty Free Worship).
- **Pros:**
  - Higher production quality
  - Properly licensed for streaming/distribution
- **Cons:**
  - $150-500/year subscription even at hobbyist tier
  - Doesn't match the chord charts (we'd have to write new chords to match the music)
  - Licensing audit burden for each track
- **Effort:** Small. One week to pick tracks + sync. Medium to do rights audit.
- **Cost:** ~$200/year subscription

### Option C — Partner with Christian musicians
- **What:** Commission original recordings from independent Christian musicians (Fiverr, church networks, indie artists).
- **Pros:**
  - Best quality
  - Real human connection to the work
  - Could become a revenue-share partnership (artist gets % of donations)
- **Cons:**
  - $50-300 per song × 12 = $600-3,600
  - 4-8 weeks lead time
  - Royalty negotiations for any future paid tier
- **Effort:** Medium-large. Music direction, contract, recording, mixing.
- **Cost:** $1,000-4,000 upfront

### My recommendation
**Start with Option A for the 12 originals, layer in Option C over time.** Reasoning:

1. The platform is pastoral, not commercial. A simple piano/guitar arrangement fits the tone better than a polished studio production.
2. Most users will play the **lyrics + chords + audio meditation** path, where music is mood, not the focus.
3. The chord charts are already in our data — we have a structured prompt template ready.
4. If the platform grows, we can hire a real musician to record 3-5 of the most popular songs as a "deluxe" version, A/B test, and learn.

**Will not do:** Licensing copyrighted hymn tunes (Amazing Grace, Be Still My Soul, etc.) without permission. The /terms page is clear on this. Public-domain melodies only, or AI-generated original settings.

---

## 3. Cost model — what HEAL costs to run

### Fixed cost (current stack)
| Service | Tier | Monthly | Notes |
|---|---|---:|---|
| Dokploy (self-host) | Hetzner CX22 | $5 | 2 vCPU / 4GB / 40GB |
| PocketBase (self-host) | Same VPS | $0 | SQLite + same box |
| Firebase Auth | Spark (free) | $0 | Up to 50K MAU |
| Firestore | Spark (free) | $0 | 1 GiB storage, 50K reads/day, 20K writes/day |
| Firebase Hosting | n/a | $0 | We use Dokploy |
| Backblaze B2 | S3-compatible | $0 (free 10GB) → $0.006/GB-month after | Storage + egress |
| GitHub | Free | $0 | Public repo |
| Domain (positiveness.club) | Porkbun | $1/mo | $12/yr |
| **Total fixed** | | **$6/mo** | At current scale |

### Variable cost — content generation (one-time per asset)
| Asset | Unit cost | Tool |
|---|---:|---|
| TTS voice meditation (1.5min) | $0.02 | MiniMax / ElevenLabs / Cartesia |
| Watercolor illustration (3:2) | $0.05 | Image synthesis |
| Badge medallion (1:1) | $0.04 | Image synthesis |
| Music arrangement (3min, no vocals) | $0.10 | Suno / internal |
| Journal/favorite/history write | $0.0000014 | Firestore (per write) |
| PB record read | $0.0000006 | PB on same box |

**To generate the missing 420 B2-B5 voice meditations + 170 illustrations + 12 praise songs + 3 essay illustrations:**
- Voice: 336 × $0.02 = **$6.72**
- Illustrations: (170 + 12 + 3) × $0.05 = **$9.25**
- Praise music: 12 × $0.10 = **$1.20**
- **One-time content cost to fully backfill: ~$17**

**Year 2 (rotate to keep it fresh):** Assume 25% of content refreshed, ~$5/year

### Variable cost — per-user running cost

#### 1,000 users (current / pre-launch)

| Resource | Usage | Monthly cost |
|---|---|---:|
| Audio bandwidth (Dokploy) | 1K users × 5 plays/wk × 1.6 MB = 32 GB/mo | $0 (within VPS) |
| Audio bandwidth (B2 CDN) | Same, 32 GB egress | $0 (B2 first 10GB free, $0.01/GB after) |
| Firestore reads | 1K users × 5 reads/day × 30 days = 150K reads | $0 (under 50K/day limit) |
| Firestore writes | 1K × 1 write/day = 30K writes | $0 (under 20K/day limit) |
| PB reads | 1K × 10 reads/day × 30 days = 300K reads | $0 (same box) |
| PB storage | 1MB growing | $0 |
| Image bandwidth | 1K × 20 imgs/mo × 200KB = 4GB | $0 |
| **Total at 1K users** | | **$6/mo** |

#### 10,000 users (early traction)

| Resource | Usage | Monthly cost |
|---|---|---:|
| VPS upgrade to CX32 (8GB / 80GB) | | +$10 |
| B2 storage | 500MB growing | $0 |
| B2 egress | 320 GB | $3 |
| Firestore reads | 1.5M reads | $0.18 (above free tier) |
| Firestore writes | 300K writes | $0.06 (above free tier) |
| Firebase Auth | 10K MAU | $0 |
| **Total at 10K users** | | **~$20/mo** |

#### 100,000 users (established)

| Resource | Usage | Monthly cost |
|---|---|---:|
| VPS upgrade to dedicated (CCX13, 16 vCPU / 32GB) | | $60 |
| Or move to managed: Railway / Fly.io | | $80-200 |
| B2 storage | 5 GB | $0.03 |
| B2 egress | 3.2 TB | $32 |
| Firestore reads | 15M reads | $1.80 |
| Firestore writes | 3M writes | $0.60 |
| Firebase Auth | 100K MAU (still free under Blaze) | $0 |
| CDN (Cloudflare free tier) | 10TB bandwidth | $0 |
| **Total at 100K users** | | **~$120/mo** |

#### 1,000,000 users (scaled)

| Resource | Usage | Monthly cost |
|---|---|---:|
| Multi-region Next.js (3 nodes × CCX33) | | $1,200 |
| PB → managed Postgres (Supabase / Neon) | | $200-500 |
| Firestore reads | 150M | $18 |
| Firestore writes | 30M | $6 |
| Firebase Auth | 1M MAU (Blaze: $0.0050/MAU after 50K) | $4,750 |
| B2 storage | 50 GB | $0.30 |
| B2 egress | 32 TB | $320 |
| Cloudflare Pro | 100TB | $20 |
| Monitoring (Sentry / Logflare) | | $100 |
| Music licensing (if scaled) | | $500-2,000/yr |
| **Total at 1M users** | | **~$6,500-7,500/mo** |

**Caveat:** Auth cost spikes at 1M. Solutions: (1) keep MAU under 50K by aggressively pruning dormant users, (2) migrate to self-hosted auth (NextAuth + Postgres) at 500K.

### Content cost to scale the library to 1,410 unique meditations (1/day × 5 years)

| Component | Unit | Total |
|---|---:|---:|
| Hand-authored meditations (5,000-7,000 words × 1,410) | $0.10 each | $141 |
| TTS voice (1,410 × 1.6MB) | $0.02 each | $28 |
| Watercolor illustration (1,410 × 1.5MB) | $0.05 each | $71 |
| Fact-check + theological review | $0.50 each | $705 |
| **Total to scale content to 5-year uniqueness** | | **$945** |

Or: keep the 5-year rotation with 84 unique meditations × 5 batches = 420 total = **$20 in content + 60 hours of writing**.

---

## 4. Business model — how HEAL pays for itself

The platform is currently free. To sustain it long-term, here are the realistic options, ranked by how well they fit a contemplative Christian platform:

### Option 1 — Donations (RECOMMENDED for v1)
- **Model:** Ko-fi / Buy Me a Coffee / Stripe one-time / monthly patron
- **Pricing:** $0 platform, $5/mo patron tier, $50+ founding member
- **Pros:**
  - Matches the contemplative, no-pressure tone
  - No paywall = maximum reach for the ministry
  - Patreon model is familiar to Christian audiences
- **Cons:**
  - Unpredictable revenue
  - Tax/legal work to set up
- **Target:** $200-2,000/mo from 1K-10K users
- **Effort:** Small. One Stripe integration, "Support HEAL" link in footer.

### Option 2 — Freemium (RECOMMENDED for v2)
- **Model:** Free tier = static content (read/listen). Premium tier = personal features (journal backup, favorites sync, custom programs, progress dashboard, longer meditations)
- **Pricing:** $0 free, $4/mo or $36/yr premium
- **Pros:**
  - Predictable revenue
  - Free tier stays generous
  - Aligns with the "save your progress" feature we already built
- **Cons:**
  - Need to identify what features to gate
  - Subscription fatigue
- **Target:** 5% conversion × 10K users × $36/yr = $18K/yr
- **Effort:** Medium. Stripe Billing, account tiers in Firestore, gated UI components.

### Option 3 — Institutional / church licensing
- **Model:** License the platform to churches, retreat centers, hospitals, counseling practices
- **Pricing:** $200-1,000/yr per institution
- **Pros:**
  - Aligned with the ministry mission
  - B2B revenue is stickier than B2C
  - Multi-seat plans scale well
- **Cons:**
  - Sales work
  - White-label / multi-tenant complexity
- **Target:** 50-500 institutions = $50K-500K/yr
- **Effort:** Large. Auth roles, multi-tenant Firestore, admin dashboard, contract work.

### Option 4 — Content licensing
- **Model:** License meditations / prayers / programs to other apps, podcasts, retreat centers
- **Pricing:** Per-content, $5-50 per item
- **Pros:**
  - High-margin, low-cost (already written)
  - Could partner with Bible apps, prayer apps
- **Cons:**
  - Sales work
  - Need a content API + license agreement
- **Target:** $5K-50K/yr from a handful of partners
- **Effort:** Medium. API + contract templates.

### Option 5 — Workshops + retreats
- **Model:** HEAL hosts in-person or online contemplative retreats, with the platform as the takeaway practice
- **Pricing:** $100-500 per participant
- **Pros:**
  - Builds community
  - Marketing for the platform
- **Cons:**
  - Not scalable
  - Time-intensive
- **Target:** $5K-20K/yr (events-based)
- **Effort:** Large. Event planning, partnerships.

### My recommendation: stack
1. **v1 (now):** Donations via Ko-fi / Stripe. One button in the footer, no paywall.
2. **v2 (at 5K users):** Freemium — premium tier gates "save your journal" + "save your badges across devices" + "premium programs."
3. **v3 (at 25K users):** Institutional licensing — churches/retreats.
4. **v4 (anytime):** Content licensing to other apps.

This gives 4 monetization vectors without ever putting the core content behind a paywall.

---

## 5. MVP gaps — what to ship before public launch

Ranked by impact and effort. Items already done are excluded.

### P0 — Block launch
| Item | Why | Effort |
|---|---|---|
| **Dokploy container bug** — click Deploy in UI | Site is 404; code is ready | 1 click |
| **Bucket-scoped B2 key** (user action) | Cannot upload to B2 without it | 5 min web UI |
| **HEAL_JWT_SECRET rotation** | Dev-default secret in env | 5 min |
| **HEAL_B2_KEY_ID + APPLICATION_KEY rotate** | Exposed in chat history | 5 min |
| **B2 password/PB password rotate** | Exposed in chat history | 5 min |
| **Add "music" honesty to /praise page** | Already in /terms but should be on /praise | 15 min |

### P1 — Ship within 2 weeks of launch
| Item | Why | Effort |
|---|---|---|
| Generate 12 AI instrumental praise tracks (Option A) | User asked for it; matches chord charts | Small (1 week) |
| Generate 170 more meditation illustrations | B2-B5 meditations look bad without them | Small (2 days at scale) |
| Generate 336 B2-B5 voice meditations | Voice experience is B1-only currently | Small (1 week) |
| Praise illustrations (12) + essay illustrations (3) | Visual consistency | Small (1 day) |
| "Sign in to save" prompt — already exists in ProgramProgressTracker | Verify UX flow | 0 |
| Add a "Support HEAL" donation link in footer | First monetization vector | Small (1 day) |
| OpenGraph preview test on Twitter/FB | Make sure dynamic OG images work | Small (1 day) |
| Real-device audio test (iOS Safari!) | Background audio, autoplay restrictions | Medium |
| Add /praise audio_url field to schema + 12 generated tracks | Wire up the data | Small |

### P2 — Ship within 1 month
| Item | Why | Effort |
|---|---|---|
| Premium tier scaffolding (Stripe + feature flags) | Start revenue | Medium (1 week) |
| Journal export to JSON (Privacy policy promises) | Compliance | Small (2 days) |
| Account deletion flow (Privacy policy promises) | Compliance | Small (2 days) |
| "Today's program" widget on home page | Engagement | Small (1 day) |
| Push notifications for daily meditation (PWA) | Re-engagement | Medium |
| Email digest (weekly, opt-in) | Re-engagement | Medium |
| Mobile-first PWA install banner | Distribution | Small |
| Light-mode toggle | Many users prefer light | Small |
| HiDPI logo + favicon polish | Branding | Small |

### P3 — Post-MVP
| Item | Why | Effort |
|---|---|---|
| Real musician recordings for top 5 praise songs (Option C) | Premium quality for popular songs | Medium |
| Multi-language (zh-CN, ja, es) | China / Japan / Latin America are your target markets per concept doc | Large |
| Native app (Flutter) | Better notification + offline | Large |
| Community-contributed meditations (with review) | UGC scale | Large |
| Public sharing of badge images (optional opt-in) | Social proof | Small |
| iOS / Android app store listing | Distribution | Large |
| Multi-tenant for churches (Option 3) | Revenue | Large |

---

## 6. Recommended launch sequence

**Day 0 (now):** Fix Dokploy container bug, rotate exposed secrets, ship to live URL.

**Day 1-3:** Add donation link. Run content generation for missing praise illustrations + 12 AI music tracks + praise illustrations + essay illustrations. Verify audio plays end-to-end on real device.

**Day 4-7:** Backfill 336 B2-B5 voice meditations + 170 illustrations. These are the biggest content gaps. ~$17 total cost, ~40 hours of generation + uploading.

**Day 8-14:** Soft launch to a small Christian newsletter / Facebook group. ~50-200 users. Watch logs. Iterate on UX bugs.

**Day 15-30:** Public launch. Submit to Product Hunt, Indie Hackers, relevant Christian directories. Get first 1,000 users. Add P2 items as they come up.

**Day 30-60:** Add Stripe + premium tier. Test at 1K-5K users.

**Day 60-180:** Scale to 10K users. Optimize. Consider multi-region.

---

## 7. The honest answer to your music question

**Today: no music. Lyrics + chords only.** The /praise page is honest about it.

**Next step (1 week, ~$1.20):** Generate 12 AI instrumental arrangements (piano + light guitar, no vocals, 2-3 min each) using internal tools. This matches the chord charts in our data, costs almost nothing, and is fully owned by positiveness.club.

**Future (1-2 months, $1K-4K):** Commission a real musician to record the 3-5 most-played songs as a "deluxe" version. A/B test. Use what works.

The platform works fully without music. Adding it is a quality-of-life improvement, not a launch blocker.
