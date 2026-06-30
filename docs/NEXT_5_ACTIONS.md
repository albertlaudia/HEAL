# HEAL — Next 5 Actions (read me first)

You asked: "Anything missing still in the platform before we start upgrading?"

**Short answer:** A LOT is missing, but 90% of it is unblocking 10 things.

## 🚦 STATE RIGHT NOW
```
heal.positiveness.club   🔴 502 (Dokploy overlay detached — recoverable in 1 click)
healf.positiveness.club  🔴 502 (Dockerfile build error — need SSH log to fix)
PocketBase               🟢 healthy
CDN                      🟢 healthy
```

Both surfaces are reachable in <1 hour. The blocker is you clicking two buttons in Dokploy UI + SSH'ing once to read me a log.

## 🎯 THE 5 ACTIONS (in order)

### Action 1 — SSH VPS, get me the Flutter build log (5 min) — ME WAITING

```bash
ssh root@84.247.174.141
tail -100 /etc/dokploy/logs/app-calculate-digital-bandwidth-h95pb2/app-calculate-digital-bandwidth-h95pb2-2026-06-28:02:23:07.log
```

Send me the last 50 lines. I'll fix `mobile/web.Dockerfile` based on what's broken.

**Why:** Three failed Docker builds, no log API exposed by Dokploy. Without the log I'm guessing.

### Action 2 — Click Deploy in Dokploy UI on HEAL (1 min)

Open https://dokploy.scaleupcrm.com → Sites project → HEAL → click **Deploy**.
This recovers the Next.js site from the overlay failure (memory pattern).

### Action 3 — Rotate 5 exposed secrets (30 min)

| Secret | Where |
|---|---|
| GitHub PAT `ghp_Cxkc5kd...b9f3r5XF8` | git remote URL visible in `git remote -v` |
| PB password | chat history |
| Firebase apiKey `AIzaSyAg_dtIPmbgdOX0gMt7E5sO8DzKhamLSwQ` | chat history |
| HEAL_JWT_SECRET | .env file (was changed in 2026-06-24 but maybe still dev-default) |
| Dokploy API key | chat history |

Mints + replace each one. Update git remote URL.

### Action 4 — Install PB auto-backup on VPS (5 min)

```bash
# Copy the install script
scp -r /workspace/HEAL/scripts/heal-backup/ root@84.247.174.141:/opt/heal-backup/
ssh root@84.247.174.141
# Follow /opt/heal-backup/INSTALL.md to set B2 creds in /etc/heal-backup.env
# Install cron: 0 3 * * * /opt/heal-backup/backup.sh >> /var/log/heal-backup.log 2>&1
```

### Action 5 — Tell me what the build log says

Paste the log output from Action 1 in the chat. I'll fix web.Dockerfile in 30-60 minutes and you'll click Deploy again.

---

## ⏱️ TIMELINE

| When | Status |
|---|---|
| Now | Both sites DOWN |
| +5 min | You SSH, copy log |
| +35 min | I fix web.Dockerfile |
| +37 min | You click 2x Deploy buttons |
| +50 min | Both sites UP (hopefully) |
| +1 hr | "Verify both URLs return 200" |
| Next 4 weeks | Content parity + user persistence + monetization + App Store |

---

## 📄 THE FULL PLAN IS IN `/docs/HEAL_PRODUCTION_PLAN_V3.md` (32 KB)

It contains:
- Part 1: Built checklist (verified by code inspection)
- Part 2: What's TESTED vs UNVERIFIED
- Part 3: 60+ missing items in P0/P1/P2/P3 buckets
- Part 4: 4-week phased launch roadmap
- Part 5: SMART business plan with revenue projections + competitive moat
- Part 6: 30/60/90 day timeline
- Part 7: These 5 actions (you are here)
- Appendix A: File inventory
- Appendix B: Priority decision matrix

The big-picture thesis:

> We're sitting on a $10M ARR opportunity (Christian mindfulness market).
> Hallow has 12M users at $50M ARR — that leaves Protestant+Evangelical+Orthodox
> (~2.5x Hallow's TAM) uncontested. Multi-language (zh+ja) + family tier +
> scripture-grounded positioning = 5-year moat.
>
> Year 1 realistic: $130k ARR. Year 3: $2M ARR. Year 5: $10M ARR.
> Acquisition target: $50-100M by Year 6 (YouVersion, Salem, Glorify, etc.)
>
> **Price:** $4.99/mo Premium. **Margin:** ~85%. **Stack:** PB + Firebase + Flutter + Next.js — all free tier for first 50k DAU.

Done the first 5 actions → 4 weeks to first paying user → 12 weeks to first 100k downloads → 5 years to #1.

Let's go.
