# Firebase architecture — free-tier safe at 1M+ users

> Target: stay on **Spark (free)** for as long as possible; cross to Blaze **only** when a user base of >50K DAU justifies it, and even then the per-user cost will be pennies.

## Threat model

The free tier (Spark) caps:

| Resource | Cap | Cost beyond |
|---|---|---|
| Firestore reads | 50,000 / day | $0.06 per 100K |
| Firestore writes | 20,000 / day | $0.18 per 100K |
| Firestore deletes | 20,000 / day | $0.02 per 100K |
| Auth (identitytoolkit) | unlimited verifications, but… | $0.01 / verification past 50K / month |
| Bandwidth | 1 GB / day egress | $0.12 / GB |

A naive design with `getDocs()` on every page load will burn the read cap within days. This doc explains how HEAL avoids that.

## Core principles

### 1. **Static content lives in PocketBase, not Firestore.**
All public meditations, quotes, scriptures, prayers, essays — everything the user *reads* — is in PB and served via Next.js ISR (revalidate=3600). Firestore sees **zero** reads for content. This is the single biggest design decision.

### 2. **User data writes are coalesced.**
- **Favorites**: 1 write per add/remove, idempotent by `(kind, slug)`. Retries are free.
- **Journal**: 1 write per save (low frequency by nature).
- **History**: debounced 30s. Multiple views of the same item within 30s = 1 write. This alone cuts history writes by 10–50×.

### 3. **No client-side `onSnapshot` on collections.**
Realtime UI is achieved via localStorage + a session-mirrored JWT cookie. We do not subscribe to Firestore. Each user can read all their data with **one getDoc** when they first open the app, and then it's all client-side state.

### 4. **A user "meta" doc with denormalized counters.**
`/users/{uid}` is a tiny doc with `{favCount, journalCount, lastActivityAt, firstName}`. The page checks this to decide whether to load the full favorites list, whether to show "Welcome back, Sarah," etc. — 1 read, not a collection scan.

### 5. **Per-user in-memory cache.**
`lib/firestore-cache.ts` caches reads for 5 minutes within a session. Going from `/favorites` to `/journal` and back uses 0 new reads if the cache is warm.

### 6. **Pagination on journal.**
`listJournalPage(uid, 20, cursor)` — never loads more than 20 entries at once, even though users can write thousands. The cap is server-enforced.

### 7. **Security rules deny everything by default.**
Even a misconfigured app can't read other users' data. Rules in `lib/firestore-rules-example.txt` to drop into the Firebase console.

## Projected cost at 1M users

Assuming:
- 5% DAU = 50,000 active users / day
- Each active user: 1 cold read of favorites, 1 cold read of history, 1 user meta doc
- 0.5 journal writes per user per day, 0.05 favorite writes per user per day
- 5 history views per user per day, 0.5 unique (debounced to 0.5 writes)

**Daily Firestore reads:** 50K × 3 = **150,000 / day** → **$6 / day** ($180 / month) on Blaze. On Spark: doesn't fit, you need Blaze by then.

**Daily Firestore writes:** 50K × (0.5 + 0.05 + 0.5) = **52,500 / day** → **$95 / day** ($2,850 / month) on Blaze. Still cheap at the per-user level — that's **$0.0001 per user per day**.

**Auth verifications:** 50K / day × $0.01 = $500 / day **if you exceed 50K/month and don't use a workaround.** Workaround: use **session cookies** (which we already do — see `lib/session.ts`). Firebase Auth session cookies mint a long-lived JWT, and our `verifyIdToken` only runs on sign-in. So 50K DAU × 1 sign-in / day = 1.5M / month → **$15/month**, not $15K.

### The dominant cost at scale is **writes**, not reads. The debounced history pattern + idempotent favorites keeps this manageable.

## What I would add when crossing 100K users

1. **Algolia / Meilisearch for any "search across favorites" feature.** Firestore's `array-contains` is fine for v1.
2. **Cloud Functions for the daily streak / reminder push.** Don't put cron in the web app.
3. **Mirror read-heavy aggregates to Cloud Datastore** (much cheaper reads, $0.036 per 100K). Favorites list as a single Datastore entity keyed by uid.
4. **Archive old journal entries to Cloud Storage as JSON after 1 year.** The vast majority of writes/reads are to the last 30 days anyway.

## What I would never do

- ❌ Put static content in Firestore. Always PB.
- ❌ `onSnapshot` a collection from a web client. That burns reads on every state change.
- ❌ Read the journal collection unfiltered and unpaginated. The naive `getDocs(query(collection))` is a free-tier killer.
- ❌ Verify the idToken on every API call. Mint a session cookie once at sign-in and reuse it.
- ❌ Use Firebase Hosting. Use Dokploy + Next.js — the rest of your stack is there.
- ❌ Use Cloud Functions for the website. Use Next.js API routes (cheaper, simpler, no cold start).

## TL;DR for the team

**PB for content, Firestore for user data, session cookies for auth, debounce history, cache reads, paginate journal, deny by default.** With this design, the free tier is fine to ~10K DAU. Beyond that, Blaze costs scale linearly with users, not super-linearly.
