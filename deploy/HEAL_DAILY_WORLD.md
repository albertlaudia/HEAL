# HEAL — daily-world cron

## What it does
Every day at **21:00 UTC** (= 06:00 WST Australia), a fresh "today in the world"
piece is generated and saved to the `HEAL_world` collection in PocketBase.

Each piece has 4 sections, in order:
1. **prompt** — a 2-4 sentence description of the situation (challenge / grace / gratitude)
2. **scripture** — one Bible verse (ref + text) that meets the moment
3. **reflection** — 100-180 words on what the Bible says about this and why it matters
4. **prayer** — 60-100 words, addressed to God, gentle and usable
5. **expectation** — 30-60 words on how we could expect the best out of this

The mode rotates: Mon challenge, Tue grace, Wed gratitude, ...
Every 10th day forces gratitude so we never go too long without praise.

## Files

| Path | Purpose |
|---|---|
| `web/scripts/daily-world.py` | the generator |
| `web/scripts/run-daily-world.sh` | bash wrapper, sources env, runs script |
| `deploy/cron.d-heal-world.txt` | /etc/cron.d entry — install with `crontab -u root deploy/cron.d-heal-world.txt` |
| `deploy/cron.d-heal-watchdog.txt` | /etc/cron.d entry — keeps cron alive |
| `deploy/heal-world.env.example` | required env vars |

## Required env vars

```
PB_IDENTITY=minimax@scaleupcrm.com
PB_PASSWORD=8ik,9ol.Q123!
PB_URL=https://pocketbase.scaleupcrm.com
PY=/usr/bin/python3
```

## Manual run

```bash
PB_IDENTITY=minimax@scaleupcrm.com PB_PASSWORD='8ik,9ol.Q123!' \
  /workspace/HEAL/web/scripts/run-daily-world.sh
```

Idempotent — if today's record already exists, the script exits silently.

## Backfill past days

```python
from datetime import date, timedelta
import importlib.util
spec = importlib.util.spec_from_file_location('daily_world', 'web/scripts/daily-world.py')
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
import random, hashlib
token = mod.pb_auth()
for i in range(7):
    d = date(2026, 7, 5) - timedelta(days=i)
    mod.TODAY = d
    mod.SLUG = f'world-{d.isoformat()}'
    mod.DAY_OF_YEAR = d.timetuple().tm_yday
    mod.MODE = mod.MODE_ROTATION[d.weekday() % len(mod.MODE_ROTATION)]
    random.seed(int(hashlib.sha256(d.isoformat().encode()).hexdigest(), 16))
    if mod.already_exists(token):
        print(f"  {mod.SLUG}: skip")
        continue
    mod.upsert(mod.build_record(), token)
    print(f"  {mod.SLUG}: created")
```

## Australia timezone note

Cron fires 21:00 UTC = 06:00 WST (UTC+8) year-round.
= 07:00 AEST (UTC+10) and 08:00 AEDT (UTC+11) in Sydney/Melbourne summer.

The slug is `world-YYYY-MM-DD` in **UTC**. Web/mobile clients that want to show
"today's world" apply the same UTC+8 offset to the current date when computing
the slug they look up — so a user in Sydney at 5am local sees the new piece
that was generated at 21:00 UTC the previous day (which is also "today" in
their local time).
