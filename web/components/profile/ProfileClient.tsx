// HEAL — Profile client (web).
//
// Renders the full practice profile. All data is read from localStorage
// (anonymous) or Firestore (signed in). The page is intentionally
// client-rendered so we can refresh the view in response to new
// practice events without a network round-trip.
//
// Sections:
//   - Header (avatar + name + sign-in state)
//   - Streak summary (3 stat tiles)
//   - Activity heatmap (last 90 days)
//   - Sticker highlights (rarest 3 + most recent 3)
//   - Quick links (Library, Stickers, Journal, Settings)

'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { Award, BookOpen, Flame, Heart, Settings, Sparkles } from 'lucide-react';

import { getCurrentUser } from '@/lib/auth-client';
import { getAllBadges, type BadgeRecord } from '@/lib/programs-client';
import { STICKER_CATALOG } from '@/components/stickers/sticker-catalog';

type StreakSummary = {
  current: number;
  longest: number;
  totalSessions: number;
  totalMinutes: number;
};

type ActivityDay = { date: string; count: number };

function readStreak(): StreakSummary {
  if (typeof window === 'undefined') {
    return { current: 0, longest: 0, totalSessions: 0, totalMinutes: 0 };
  }
  const current = parseInt(window.localStorage.getItem('heal.streak.v1.current') || '0', 10);
  const longest = parseInt(window.localStorage.getItem('heal.streak.v1.longest') || '0', 10);
  const totalSessions = parseInt(window.localStorage.getItem('heal.streak.v1.total_sessions') || '0', 10);
  const totalMinutes = parseInt(window.localStorage.getItem('heal.streak.v1.total_minutes') || '0', 10);
  return { current, longest, totalSessions, totalMinutes };
}

function readActivityHeatmap(days = 90): ActivityDay[] {
  if (typeof window === 'undefined') return [];
  // Source: heal.activity.v1 (mirrors mobile's activity_tracker)
  // Stored as a JSON array of {kind, target, at: ISO, ...}
  const raw = window.localStorage.getItem('heal.activity.v1');
  if (!raw) return Array.from({ length: days }, (_, i) => ({
    date: new Date(Date.now() - i * 86400000).toISOString().slice(0, 10),
    count: 0,
  }));
  try {
    const events = JSON.parse(raw) as Array<{ kind: string; at: string }>;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const byDate = new Map<string, number>();
    for (const e of events) {
      if (e.kind !== 'play_complete' && e.kind !== 'session') continue;
      const d = new Date(e.at);
      d.setHours(0, 0, 0, 0);
      const key = d.toISOString().slice(0, 10);
      byDate.set(key, (byDate.get(key) ?? 0) + 1);
    }
    const out: ActivityDay[] = [];
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date(today.getTime() - i * 86400000);
      const key = d.toISOString().slice(0, 10);
      out.push({ date: key, count: byDate.get(key) ?? 0 });
    }
    return out;
  } catch {
    return [];
  }
}

function readStickerHighlights(): { rarest: string[]; recent: string[] } {
  if (typeof window === 'undefined') return { rarest: [], recent: [] };
  // Read first-* flags + completed bible days.
  const earned: { id: string; at: string; rarity: number }[] = [];
  const practiceFlags: Record<string, [string, number]> = {
    'first-breath':     ['heal.first.breath_at',     1],
    'first-meditation': ['heal.first.meditation_at', 1],
    'first-prayer':     ['heal.first.prayer_at',     1],
    'first-praise':     ['heal.first.praise_at',     1],
    'first-bible':      ['heal.first.bible_at',      1],
    'first-favorite':   ['heal.first.favorite_at',   1],
    'first-share':      ['heal.first.share_at',      1],
  };
  for (const [id, [key, r]] of Object.entries(practiceFlags)) {
    const v = window.localStorage.getItem(key);
    if (v) earned.push({ id, at: v, rarity: r });
  }
  // Streak milestones
  const longest = parseInt(window.localStorage.getItem('heal.streak.v1.longest') || '0', 10);
  for (const s of STICKER_CATALOG) {
    if (s.family === 'streak' && s.milestone && longest >= s.milestone) {
      earned.push({ id: s.id, at: new Date().toISOString(), rarity: s.milestone });
    }
  }
  earned.sort((a, b) => b.rarity - a.rarity);
  const rarest = earned.slice(0, 3).map((e) => e.id);
  earned.sort((a, b) => (a.at > b.at ? -1 : 1));
  const recent = earned.slice(0, 3).map((e) => e.id);
  return { rarest, recent };
}

export function ProfileClient() {
  const [hydrated, setHydrated] = useState(false);
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [streak, setStreak] = useState<StreakSummary>({ current: 0, longest: 0, totalSessions: 0, totalMinutes: 0 });
  const [heatmap, setHeatmap] = useState<ActivityDay[]>([]);
  const [highlights, setHighlights] = useState<{ rarest: string[]; recent: string[] }>({ rarest: [], recent: [] });
  const [badges, setBadges] = useState<BadgeRecord[]>([]);

  useEffect(() => {
    setHydrated(true);
    setStreak(readStreak());
    setHeatmap(readActivityHeatmap(90));
    setHighlights(readStickerHighlights());
    getAllBadges().then(setBadges).catch(() => {});
    // Read user from auth-client (sets a global in module scope)
    try {
      const u = getCurrentUser();
      setUserEmail(u?.email ?? null);
    } catch {}
  }, []);

  const totalEarnedStickers = useMemo(() => {
    return highlights.rarest.length + highlights.recent.length + badges.length;
  }, [highlights, badges]);

  if (!hydrated) {
    return (
      <div className="container-wide py-16">
        <div className="animate-pulse space-y-8">
          <div className="h-24 bg-ink/5 rounded-2xl" />
          <div className="grid grid-cols-3 gap-4">
            {[1, 2, 3].map((i) => <div key={i} className="h-28 bg-ink/5 rounded-2xl" />)}
          </div>
          <div className="h-40 bg-ink/5 rounded-2xl" />
        </div>
      </div>
    );
  }

  return (
    <div className="container-wide py-16">
      {/* ── Header ──────────────────────────────────────── */}
      <header className="mb-12 flex items-start gap-6">
        <div className="w-20 h-20 rounded-full bg-ink/5 flex items-center justify-center text-2xl font-serif text-ink/40">
          {(userEmail ?? 'A')[0].toUpperCase()}
        </div>
        <div className="flex-1">
          <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-2">Your practice</p>
          <h1 className="serif text-4xl text-ink mb-1">
            {userEmail ? userEmail.split('@')[0] : 'A quiet friend'}
          </h1>
          <p className="text-ink/60 text-sm">
            {userEmail
              ? 'Signed in. Your practice syncs across devices.'
              : 'Not signed in. Your data lives only on this device.'}
          </p>
        </div>
        <Link
          href="/settings"
          className="p-3 rounded-full hover:bg-ink/5 transition-colors"
          aria-label="Settings"
        >
          <Settings className="w-5 h-5 text-ink/60" aria-hidden="true" />
        </Link>
      </header>

      {/* ── Streak summary ──────────────────────────────── */}
      <section className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-12">
        <StatTile
          icon={<Flame className="w-5 h-5" aria-hidden="true" />}
          label="Current streak"
          value={streak.current}
          suffix={streak.current === 1 ? 'day' : 'days'}
          accent="amber"
        />
        <StatTile
          icon={<Award className="w-5 h-5" aria-hidden="true" />}
          label="Longest streak"
          value={streak.longest}
          suffix={streak.longest === 1 ? 'day' : 'days'}
          accent="teal"
        />
        <StatTile
          icon={<BookOpen className="w-5 h-5" aria-hidden="true" />}
          label="Total sessions"
          value={streak.totalSessions}
          accent="rose"
        />
      </section>

      {/* ── Activity heatmap ────────────────────────────── */}
      <section className="mb-12 p-6 rounded-2xl bg-ink/5">
        <div className="flex items-baseline justify-between mb-4">
          <h2 className="serif text-2xl text-ink">Last 90 days</h2>
          <p className="text-xs text-ink/50">
            {heatmap.filter((d) => d.count > 0).length} active days
          </p>
        </div>
        <Heatmap days={heatmap} />
      </section>

      {/* ── Sticker highlights ──────────────────────────── */}
      <section className="mb-12">
        <div className="flex items-baseline justify-between mb-4">
          <h2 className="serif text-2xl text-ink">Sticker highlights</h2>
          <p className="text-xs text-ink/50">
            {totalEarnedStickers} earned ·{' '}
            <Link href="/stickers" className="text-brass hover:underline">see all</Link>
          </p>
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
          {[...highlights.rarest, ...highlights.recent].slice(0, 6).map((id) => {
            const spec = STICKER_CATALOG.find((s) => s.id === id);
            if (!spec) return null;
            return (
              <div key={id} className="p-4 rounded-2xl bg-ink/5 flex items-center gap-3">
                <Sparkles className="w-6 h-6 text-brass flex-shrink-0" aria-hidden="true" />
                <div>
                  <p className="font-medium text-ink text-sm">{spec.name}</p>
                  <p className="text-xs text-ink/55 line-clamp-1">{spec.description}</p>
                </div>
              </div>
            );
          })}
          {totalEarnedStickers === 0 && (
            <p className="col-span-full text-ink/55 text-sm">
              No stickers yet — keep practicing.
            </p>
          )}
        </div>
      </section>

      {/* ── Quick links ────────────────────────────────── */}
      <section className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <QuickLink href="/library" icon={<Heart className="w-5 h-5" />} label="Library" />
        <QuickLink href="/stickers" icon={<Award className="w-5 h-5" />} label="Stickers" />
        <QuickLink href="/journal" icon={<BookOpen className="w-5 h-5" />} label="Journal" />
        <QuickLink href="/history" icon={<Flame className="w-5 h-5" />} label="History" />
      </section>
    </div>
  );
}

function StatTile({ icon, label, value, suffix, accent }: {
  icon: React.ReactNode;
  label: string;
  value: number;
  suffix?: string;
  accent: 'rose' | 'teal' | 'amber';
}) {
  const accentMap = {
    rose: 'text-rose-700 bg-rose-50',
    teal: 'text-teal-700 bg-teal-50',
    amber: 'text-amber-700 bg-amber-50',
  };
  return (
    <div className="p-5 rounded-2xl bg-ink/5">
      <div className={`inline-flex p-2 rounded-lg ${accentMap[accent]} mb-3`}>{icon}</div>
      <p className="text-xs tracking-[0.2em] uppercase text-ink/50">{label}</p>
      <p className="serif text-3xl text-ink mt-1">
        {value}
        {suffix && <span className="text-base text-ink/50 ml-1.5">{suffix}</span>}
      </p>
    </div>
  );
}

function Heatmap({ days }: { days: ActivityDay[] }) {
  // Group into weeks (7 columns × N rows).
  if (days.length === 0) return null;
  // Pad to start on a Sunday for clean grid alignment.
  const firstDow = new Date(days[0].date).getDay();
  const padded: (ActivityDay | null)[] = [
    ...Array.from({ length: firstDow }, () => null),
    ...days,
  ];
  const weeks: (ActivityDay | null)[][] = [];
  for (let i = 0; i < padded.length; i += 7) {
    weeks.push(padded.slice(i, i + 7));
  }
  const max = Math.max(1, ...days.map((d) => d.count));
  return (
    <div className="overflow-x-auto">
      <div className="flex gap-1" style={{ minWidth: weeks.length * 14 }}>
        {weeks.map((week, wi) => (
          <div key={wi} className="flex flex-col gap-1">
            {Array.from({ length: 7 }, (_, di) => {
              const d = week[di];
              if (!d) return <div key={di} className="w-3 h-3 rounded-sm bg-transparent" />;
              const intensity = d.count === 0 ? 0 : Math.max(0.25, d.count / max);
              const bg = d.count === 0
                ? 'bg-ink/5'
                : `bg-brass`;
              return (
                <div
                  key={di}
                  className={`w-3 h-3 rounded-sm ${bg}`}
                  style={{ opacity: intensity }}
                  title={`${d.date}: ${d.count} session${d.count === 1 ? '' : 's'}`}
                />
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}

function QuickLink({ href, icon, label }: { href: string; icon: React.ReactNode; label: string }) {
  return (
    <Link
      href={href}
      className="p-5 rounded-2xl bg-ink/5 hover:bg-ink/10 transition-colors flex flex-col items-center gap-2 text-ink"
    >
      {icon}
      <span className="text-sm font-medium">{label}</span>
    </Link>
  );
}
