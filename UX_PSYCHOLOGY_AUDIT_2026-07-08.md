# HEAL — UX Psychology Audit (2026-07-08)

> **Goal:** Make HEAL the most psychologically sound Christian mindfulness app — better than Calm, Headspace, Abide, Glorify, Lectio 365.

Audited against the principles that drive retention in mindfulness apps:
**1) Reduce friction to first session** · **2) Eliminate guilt** · **3) Make identity visible** · **4) Reward consistency, not perfection** · **5) Build the user's sense of self** · **6) Honor the spiritual weight of the content**.

---

## 🔴 Critical gaps (fix this week)

### 1. **Onboarding is too short — no "first breath" before commitment**
- **Now:** 3 swipes → notification permission → home. User sees a wall of content with no context.
- **Problem:** No commitment device before the user is asked for permissions. Permission denial = 1-star rating risk.
- **Calm/Headspace:** Show 1-2 minute "first breath" between intro and permission ask. User is already in the practice when prompted.
- **Fix:** Insert a 4th onboarding screen: a single 30-second breathing animation with the audio cue. User taps "I'm ready" → notification ask → home. They already feel the product.

### 2. **Home page practice grid shows ALL options at once (paradox of choice)**
- **Now:** 3×2 grid = Meditate · Praise · Pray · Reflections · Sleep · Stickers. Plus a "Today's practice" hero card.
- **Problem:** On day 1, the user has zero context to choose between "Sleep" and "Reflections". The grid is built for power users, not newcomers.
- **Headspace:** Day 1 shows ONE tile ("Start with this"). The grid emerges after 3 sessions.
- **Fix:** For the first 7 sessions, replace the 3×2 grid with a single "Start here →" tile. After session 3, show 2 options. After session 7, show the full grid.

### 3. **Notification copy is good but timing is wrong**
- **Now:** Morning (7am) + evening (9pm). Both fire even if user is mid-session.
- **Problem:** Evening notification at 9pm after a day of stress feels like "you didn't do enough." That's guilt.
- **Calm:** Only one daily nudge. Headspace: only after 3 missed days.
- **Fix:** Default to **one notification per day, morning only**. Evening becomes opt-in. Add a "tomorrow" snooze button on every notification.

### 4. **Missed-day notifications can sound passive-aggressive**
- **Now:** "You didn't finish today's reading. Tomorrow is a new day." + "Days are long, the Word is patient."
- **Problem:** "You didn't finish" is blame-language even when softened. The user knows they didn't finish.
- **Fix:** Rephrase to lead with the *practice*, not the failure:
  - ~~"You didn't finish today's reading."~~
  - **"Tomorrow's reading is ready. Three chapters, ten minutes."**
  - **"Wherever you are, the Word is waiting — no rush."**
  - **"A rested mind reads better. Day N is here when you are."**

### 5. **Comeback notification should never mention the gap**
- **Now:** "You've been away 30 days — pick up wherever feels right." (Positive framing, but mentions the gap.)
- **Problem:** Calling out the gap creates shame. The user *knows* they've been away.
- **Fix:** "Welcome back. Day N is here." That's it. No number, no "you've been away."

### 6. **Hero practice card hides the actual content**
- **Now:** Big "TODAY — A daily practice — Scripture · breath · prayer" → tap → 90-second ritual.
- **Problem:** The user can't see *what* they're being asked to do. The card says "5 minutes" but doesn't preview the scripture, breath, or prayer.
- **Fix:** Add a tiny preview line: "Today: 'The Lord is my shepherd' · 4-4-4 breath · a prayer for rest."

### 7. **The 90-second "Begin" ritual doesn't show progress**
- **Now:** Tap "Begin" → sequence starts → no visual progress until it's done.
- **Problem:** During a 90-second session, the user has no sense of how far they've come. Anxiety increases as time passes.
- **Fix:** Show a thin progress bar + step labels ("Pause — Breathe — Read — Pray"). Calm does this beautifully.

### 8. **Sticker book has no "next" hint**
- **Now:** Beautiful grid, but if you've earned 3 stickers, you don't know what to do next.
- **Fix:** Add a "Next milestones" panel: "5 more sessions → First Light (1-day streak)". Creates anticipatory motivation.

### 9. **Practice tiles have no estimated time**
- **Now:** "Meditate" — no context for how long.
- **Fix:** Add a tiny "~5 min" line on each tile.

### 10. **No exit affordance on immersive screens**
- **Now:** Once you tap "Begin" on a meditation, the back button works but it's not visible.
- **Fix:** Always show a small "✕" in the top-right of immersive player, even if minimal.

---

## 🟡 Important (next 2 weeks)

### 11. **Breath studio's "personal calibration" feels like homework**
- **Now:** Banner says "Calibrate your breath. Take 90 seconds."
- **Problem:** Most users won't tap it. It's a chore.
- **Fix:** Skip calibration. After 3 sessions, *quietly* average the user's actual breath length and apply it.

### 12. **The sticker book has 27 stickers but only 3 family labels**
- **Now:** Streak / Practice / Moment.
- **Problem:** Family labels feel arbitrary. "Moment" doesn't tell you what to expect.
- **Fix:** Rename to: **"Daily"** (streak), **"Firsts"** (first practices), **"Stories"** (Bible moments).

### 13. **Praise library doesn't curate for the user**
- **Now:** All 112 songs in one scroll. Filter chips at top.
- **Problem:** On day 1, 112 songs is overwhelming.
- **Fix:** Default to "Today's praise" (one song, deterministic by day). Below: "All praise" with the filter.

### 14. **No "Begin again" after a long absence**
- **Now:** Calendar shows your heatmap with empty cells.
- **Problem:** Empty cells are shame-amplifying.
- **Fix:** When user returns after 7+ days, show a one-time "Restart Day 1" button. Or auto-reset streak gently.

### 15. **Profile "Recent stickers" doesn't motivate next unlock**
- See #8 — same fix.

### 16. **Sleep stories hero copy is poetic but vague**
- **Now:** "Slow your breathing. Lower the day. Lie in the Word."
- **Fix:** Add a one-line meta: "8-12 minutes · Psalm 23 · read by a calm voice"

### 17. **Ambient mixer has 6 tracks and 5 presets — too many to start**
- **Now:** Grid of 6 cards on first open.
- **Problem:** Calm's "Scenes" start with 3. We have 6.
- **Fix:** First time, show only 3. After 3 uses, reveal the rest.

### 18. **Notification permission is asked immediately on first onboarding**
- **Now:** 3rd onboarding screen asks for notifications.
- **Problem:** User hasn't experienced value yet.
- **Fix:** Ask for notifications AFTER the first completed session, in a gentle toast: "Want a gentle nudge tomorrow at 7am?"

### 19. **No "you finished a chapter" celebration**
- **Now:** Mark Bible day complete → toast + sticker (sometimes).
- **Problem:** The milestone moment deserves more weight.
- **Fix:** Add a 2-second brass-glow overlay with the verse name: "You finished Genesis 1-3. Day 1 of 365."

### 20. **"Today's practice" doesn't show what makes today different**
- **Now:** Same card every day, just different rotation.
- **Problem:** No reason to come back tomorrow.
- **Fix:** Subtle copy variation: "Today's practice — a chapter from the Psalms." "Today's practice — breath on gratitude." Make the *theme* visible.

---

## 🟢 Polish (do whenever)

- **Empty states:** When user has 0 stickers, 0 sessions, 0 favorites — the page should feel like a beginning, not a void. Currently feels clinical.
- **Color psychology:** Right now everything is rosewood + brass. Consider a slight shift per practice type (meditation = sage green, prayer = warm rose, praise = indigo).
- **Haptic vocabulary:** We use light/medium/heavy + selection click. Consider adding "success" haptic (two quick taps) on milestone.
- **Tap targets:** Some of the sticker detail sheet buttons may be smaller than 44×44 (Apple HIG). Audit.
- **Loading states:** When PB is slow, the today shelf shows blank cards. Replace with skeleton loaders.
- **A11y labels:** Add semantic labels to stickers, achievement overlays.
- **Sound design:** Breath sounds are procedural — fine. But a 2-second "session complete" bell would tie into audio_session better than just the audio fade.
- **Tab bar:** Currently has 5 tabs. Apple's HIG recommends max 5 but it gets tight on small phones. Sleep is a discoverable item via the Sleep tile in the home grid — could drop the dedicated tab if we wanted.

---

## Strategic notes (3-month outlook)

1. **The "moment" stickers** are HEAL's differentiator vs Calm/Headspace. Nobody else has Bible iconic moments as emotional markers. **Double down on these.** Add 30 more. Make each one feel like a milestone, not a checklist item.

2. **Identity formation beats behavior tracking.** A user who calls themselves "a person who meditates every morning" keeps the streak. A user who tracks streak numbers loses them. Our heatmap is great but the **identity card on profile should also say something like "You are the kind of person who shows up."**

3. **Spiritual authority requires restraint.** The app shouldn't gamify scripture — that would feel cheap. Stickers unlock, but the *scripture itself* should never be marked complete with a confetti explosion. The brass glow is right; the confetti would be wrong.

4. **The "Sleep" and "Ambient" features are perfect for a secondary audience.** Sleep tracker users (who aren't Christian) would pay for the ambient soundscape alone. This could become a freemium tier later.

5. **The "Bible-in-a-Year" is the killer retention feature.** Once a user starts Day 1, they have a reason to come back tomorrow. It's not a streak — it's a journey. Lean into this copy everywhere.

---

## What I will ship right now (Tier 1 only — top 5 critical gaps)

1. **"First breath" onboarding screen** between intro and permission ask
2. **"Tomorrow is a new day" notification copy** — lead with the practice, not the failure
3. **No number in comeback notification** — just "Welcome back"
4. **Preview line on hero practice card** — "Today: 'The Lord is my shepherd' · 4-4-4 breath"
5. **Progress bar + step labels on 90-second ritual**
6. **One-notification-per-day default** — morning only; evening opt-in
7. **Tiny "next milestone" hint on sticker book** for motivational pull

These 7 changes should ship today. They'll measurably reduce Day-1 abandonment and Day-30 churn.