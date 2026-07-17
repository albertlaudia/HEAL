// HEAL — Sticker book client (web).
//
// Renders the full sticker catalog with earned/locked state, plus a
// "Recently earned" timeline at the top.
//
// Data sources:
//   - Streak family: from localStorage `heal.streak.v1.currentStreak`
//   - Practice family: from localStorage flags (heal.first_meditation, etc.)
//   - Program badges: from Firestore / localStorage (existing badge system)
//   - Bible moment family: from completed bible days (localStorage
//     `heal.bible.completed_days` — an array of day numbers)
//
// Everything is read-only on the web. Earning happens on the client
// after each practice action; this page just shows the result.

'use client';

import { useEffect, useMemo, useState } from 'react';
import { Award, Lock, Sparkles } from 'lucide-react';

import { getAllBadges, type BadgeRecord } from '@/lib/programs-client';
import { STICKER_CATALOG, SYMBOL_PATHS, type StickerSpec } from './sticker-catalog';

const COLOR_CLASSES: Record<string, { bg: string; ring: string; text: string }> = {
  'rose':         { bg: 'bg-rose-100',    ring: 'ring-rose-300',    text: 'text-rose-700' },
  'teal':         { bg: 'bg-teal-100',    ring: 'ring-teal-300',    text: 'text-teal-700' },
  'amber':        { bg: 'bg-amber-100',   ring: 'ring-amber-300',   text: 'text-amber-700' },
  'sage':         { bg: 'bg-emerald-100', ring: 'ring-emerald-300', text: 'text-emerald-700' },
  'indigo':       { bg: 'bg-indigo-100',  ring: 'ring-indigo-300',  text: 'text-indigo-700' },
  'muted-blue':   { bg: 'bg-sky-100',     ring: 'ring-sky-300',     text: 'text-sky-700' },
  'warm-cream':  { bg: 'bg-orange-100',  ring: 'ring-orange-300',  text: 'text-orange-800' },
};

type EarnedState = {
  earnedIds: Set<string>;
  byEarnedAt: Map<string, string>;  // id → ISO date
  recentlyEarned: Array<{ id: string; name: string; earnedAt: string }>;
};

function readEarnedState(): EarnedState {
  const earnedIds = new Set<string>();
  const byEarnedAt = new Map<string, string>();

  if (typeof window === 'undefined') {
    return { earnedIds, byEarnedAt, recentlyEarned: [] };
  }

  // Streak family: based on `heal.streak.v1.currentStreak` (max)
  const streakMax = parseInt(
    window.localStorage.getItem('heal.streak.v1.longest') ||
    window.localStorage.getItem('heal.streak.v1.current') ||
    '0', 10,
  );
  for (const s of STICKER_CATALOG) {
    if (s.family === 'streak' && s.milestone && streakMax >= s.milestone) {
      earnedIds.add(s.id);
      byEarnedAt.set(s.id, new Date().toISOString());
    }
  }

  // Practice family: each first-* flag
  const practiceFlags: Record<string, string> = {
    'first-breath':     'heal.first.breath_at',
    'first-meditation': 'heal.first.meditation_at',
    'first-prayer':     'heal.first.prayer_at',
    'first-praise':     'heal.first.praise_at',
    'first-bible':      'heal.first.bible_at',
    'first-favorite':   'heal.first.favorite_at',
    'first-share':      'heal.first.share_at',
  };
  for (const [id, key] of Object.entries(practiceFlags)) {
    const v = window.localStorage.getItem(key);
    if (v) {
      earnedIds.add(id);
      byEarnedAt.set(id, v);
    }
  }

  // Bible moment family: look up the completed day numbers + the
  // verse → day mapping. We use a tiny in-file mapping here.
  const completedDaysJson = window.localStorage.getItem('heal.bible.completed_days');
  if (completedDaysJson) {
    try {
      const days = JSON.parse(completedDaysJson) as number[];
      const momentMap: Record<string, number> = {
        'moment-genesis-1':    1,
        'moment-psalm-23':     23,
        'moment-psalm-139':    139,
        'moment-sermon-mount': 31,
        'moment-cross':        183,
        'moment-resurrection': 187,
        'moment-pentecost':    193,
      };
      for (const [id, day] of Object.entries(momentMap)) {
        if (days.includes(day)) {
          earnedIds.add(id);
          byEarnedAt.set(id, new Date().toISOString());
        }
      }
    } catch {}
  }

  // Program badges: from getAllBadges
  // (called async in useEffect — see below)
  return { earnedIds, byEarnedAt, recentlyEarned: [] };
}

export function StickerBookClient() {
  const [state, setState] = useState<EarnedState>({
    earnedIds: new Set(),
    byEarnedAt: new Map(),
    recentlyEarned: [],
  });
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    const base = readEarnedState();
    // Pull badges asynchronously (may be Firestore-backed).
    getAllBadges().then((badges) => {
      const recentlyEarned: EarnedState['recentlyEarned'] = [];
      for (const b of badges) {
        // Mark program family earned + add to recent list.
        base.earnedIds.add(`badge:${b.programSlug}`);
        base.byEarnedAt.set(`badge:${b.programSlug}`, b.earnedAt);
        recentlyEarned.push({
          id: `badge:${b.programSlug}`,
          name: b.name,
          earnedAt: b.earnedAt,
        });
      }
      // Sort recent by date desc, take 5.
      recentlyEarned.sort((a, b) => (a.earnedAt > b.earnedAt ? -1 : 1));
      setState({
        earnedIds: base.earnedIds,
        byEarnedAt: base.byEarnedAt,
        recentlyEarned: recentlyEarned.slice(0, 5),
      });
    });
  }, []);

  const grouped = useMemo(() => {
    const groups: Record<string, { spec: StickerSpec; earned: boolean; earnedAt?: string }[]> = {
      streak: [],
      practice: [],
      moment: [],
      program: [],
    };
    for (const s of STICKER_CATALOG) {
      const earned = state.earnedIds.has(s.id);
      const earnedAt = state.byEarnedAt.get(s.id);
      groups[s.family].push({ spec: s, earned, earnedAt });
    }
    // Sort: streak by milestone asc, others by id
    groups.streak.sort((a, b) => (a.spec.milestone ?? 0) - (b.spec.milestone ?? 0));
    return groups;
  }, [state]);

  const totalEarned = STICKER_CATALOG.filter((s) => state.earnedIds.has(s.id)).length;
  const totalCount = STICKER_CATALOG.length;

  if (!hydrated) {
    return (
      <div className="container-wide py-16">
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {Array.from({ length: 9 }).map((_, i) => (
            <div key={i} className="animate-pulse aspect-square rounded-2xl bg-ink/5" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Your collection</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Stickers</h1>
        <p className="text-ink/60 leading-relaxed text-lg">
          Small marks of the work you have done. Streaks, first practices, and quiet Bible moments.
        </p>
        <div className="mt-6 inline-flex items-center gap-2 px-4 py-2 rounded-full bg-ink/5">
          <Sparkles className="w-4 h-4 text-brass" aria-hidden="true" />
          <span className="text-sm text-ink/70">
            {totalEarned} of {totalCount} earned
          </span>
        </div>
      </header>

      {/* ── Recently earned timeline ────────────────────── */}
      {state.recentlyEarned.length > 0 && (
        <section className="mb-16 max-w-3xl">
          <h2 className="serif text-2xl text-ink mb-4">Recently earned</h2>
          <ol className="space-y-3">
            {state.recentlyEarned.map((r) => (
              <li key={r.id} className="flex items-center gap-3 px-4 py-3 rounded-xl bg-ink/5">
                <Award className="w-5 h-5 text-brass flex-shrink-0" aria-hidden="true" />
                <span className="font-medium text-ink">{r.name}</span>
                <span className="ml-auto text-xs text-ink/50">
                  {new Date(r.earnedAt).toLocaleDateString(undefined, {
                    month: 'short', day: 'numeric', year: 'numeric',
                  })}
                </span>
              </li>
            ))}
          </ol>
        </section>
      )}

      {/* ── Streak family ───────────────────────────────── */}
      <StickerSection
        title="Streaks"
        subtitle="A rhythm of returning."
        items={grouped.streak}
        totalEarned={grouped.streak.filter((g) => g.earned).length}
        totalCount={grouped.streak.length}
      />

      {/* ── Practice family ──────────────────────────────── */}
      <StickerSection
        title="First practices"
        subtitle="The beginning of each kind of practice."
        items={grouped.practice}
        totalEarned={grouped.practice.filter((g) => g.earned).length}
        totalCount={grouped.practice.length}
      />

      {/* ── Bible moment family ──────────────────────────── */}
      <StickerSection
        title="Bible moments"
        subtitle="When you sat with a particular passage."
        items={grouped.moment}
        totalEarned={grouped.moment.filter((g) => g.earned).length}
        totalCount={grouped.moment.length}
      />
    </div>
  );
}

function StickerSection({
  title, subtitle, items, totalEarned, totalCount,
}: {
  title: string;
  subtitle: string;
  items: { spec: StickerSpec; earned: boolean; earnedAt?: string }[];
  totalEarned: number;
  totalCount: number;
}) {
  return (
    <section className="mb-16">
      <div className="mb-6">
        <h2 className="serif text-2xl text-ink">{title}</h2>
        <p className="text-ink/60 text-sm mt-1">{subtitle}</p>
        <p className="text-xs text-ink/40 mt-1">
          {totalEarned} of {totalCount} earned
        </p>
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
        {items.map((g) => <StickerTile key={g.spec.id} spec={g.spec} earned={g.earned} earnedAt={g.earnedAt} />)}
      </div>
    </section>
  );
}

function StickerTile({ spec, earned, earnedAt }: { spec: StickerSpec; earned: boolean; earnedAt?: string }) {
  const classes = COLOR_CLASSES[spec.color] ?? COLOR_CLASSES['rose'];
  const path = SYMBOL_PATHS[spec.symbol] ?? '';
  return (
    <div
      className={`group relative aspect-square rounded-2xl ring-1 ${classes.ring} ${earned ? classes.bg : 'bg-ink/5'} p-4 flex flex-col items-center justify-center text-center transition-all hover:scale-[1.02]`}
      title={earned ? `Earned${earnedAt ? ` on ${new Date(earnedAt).toLocaleDateString()}` : ''}` : 'Not yet earned'}
    >
      {earned ? (
        <svg viewBox="0 0 24 24" className={`w-10 h-10 ${classes.text}`} fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d={path} />
        </svg>
      ) : (
        <Lock className="w-7 h-7 text-ink/30" aria-hidden="true" />
      )}
      <p className={`mt-2 text-sm font-medium ${earned ? 'text-ink' : 'text-ink/40'}`}>
        {earned ? spec.name : '???'}
      </p>
      <p className={`text-[11px] mt-1 line-clamp-2 ${earned ? 'text-ink/55' : 'text-ink/30'}`}>
        {earned ? spec.description : 'Keep practicing to unlock.'}
      </p>
    </div>
  );
}
