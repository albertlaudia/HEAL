'use client';

import { useEffect, useState } from 'react';
import { Award, Sparkles } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';
import { getAllBadges, type BadgeRecord } from '@/lib/programs-client';
import type { HEALProgram } from '@/lib/pb';

const themeColors: Record<string, string> = {
  rose: 'text-rose-700',
  teal: 'text-teal-700',
  amber: 'text-amber-700',
  sage: 'text-sage-700',
  indigo: 'text-indigo-700',
  'muted-blue': 'text-sky-700',
  'warm-cream': 'text-orange-800',
};

export function BadgesCollectionClient({ programs }: { programs: HEALProgram[] }) {
  const [badges, setBadges] = useState<BadgeRecord[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    getAllBadges().then((local) => {
      const enriched = local.map((b) => {
        const program = programs.find((p) => p.slug === b.programSlug);
        if (!program) return b;
        return {
          ...b,
          scriptureRef: b.scriptureRef || program.badge_scripture_ref,
          scriptureText: b.scriptureText || program.badge_scripture_text,
          imagePath: b.imagePath || program.badge_image_path,
        };
      });
      setBadges(enriched);
    }).catch(() => {});
  }, [programs]);

  if (!hydrated) {
    return (
      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {[1, 2, 3].map((i) => (
          <div key={i} className="animate-pulse aspect-[3/4] rounded-2xl bg-ink/5" />
        ))}
      </div>
    );
  }

  if (badges.length === 0) {
    return (
      <div className="card-quiet p-12 text-center max-w-2xl mx-auto">
        <Award className="mx-auto text-ink/30 mb-4" size={40} />
        <p className="serif text-2xl text-ink/70 mb-2">Your collection is empty.</p>
        <p className="text-ink/55 mb-6">
          Begin a program and complete its steps to earn your first badge.
        </p>
        <Link
          href="/programs"
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-sage-600 text-bone hover:bg-sage-700 transition-colors"
        >
          <Sparkles size={14} />
          Browse programs
        </Link>
      </div>
    );
  }

  return (
    <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {badges.map((b) => {
        const program = programs.find((p) => p.slug === b.programSlug);
        if (!program) return null;
        const accent = themeColors[program.theme_color] || 'text-sage-700';
        const earnedDate = new Date(b.earnedAt);
        return (
          <div key={b.programSlug} className="card-quiet p-6 hover:-translate-y-0.5 transition-transform">
            <div className="aspect-square rounded-2xl bg-gradient-to-br from-cream-50 to-bone flex items-center justify-center mb-4 overflow-hidden">
              {b.imagePath ? (
                <Image src={b.imagePath} alt={b.name} width={200} height={200} className="object-contain p-4" />
              ) : (
                <Award className={`opacity-50 ${accent}`} size={64} />
              )}
            </div>
            <div className="flex items-center gap-1.5 text-[10px] tracking-[0.25em] uppercase text-ink/50 mb-1">
              <Award size={11} className={accent} />
              Earned {earnedDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
            </div>
            <h3 className={`serif text-2xl mb-2 ${accent}`}>{b.name}</h3>
            <p className="serif italic text-ink/80 leading-relaxed mb-3">"{b.affirmation}"</p>
            {b.scriptureRef && (
              <div className="pt-3 border-t border-ink/5">
                <p className={`text-sm italic leading-relaxed ${accent}`}>"{b.scriptureText}"</p>
                <p className={`text-xs mt-1 ${accent}`}>— {b.scriptureRef}</p>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

export function LockedBadgesList({ programs, earnedSlugs }: { programs: HEALProgram[]; earnedSlugs: string[] }) {
  const remaining = programs.filter((p) => p.badge_name && !earnedSlugs.includes(p.slug));
  if (remaining.length === 0) {
    return (
      <p className="text-ink/55 text-sm italic">
        You've earned them all. New programs are written as the platform grows.
      </p>
    );
  }
  return (
    <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {remaining.map((p) => (
        <Link
          key={p.id}
          href={`/programs/${p.slug}`}
          className="block p-5 rounded-2xl border border-dashed border-ink/15 hover:border-sage-300 transition-colors"
        >
          <div className="flex items-center gap-2 text-[10px] tracking-[0.25em] uppercase text-ink/50 mb-2">
            <Award size={11} />
            Badge locked
          </div>
          <h3 className="serif text-lg text-ink mb-1">{p.badge_name}</h3>
          <p className="text-xs text-ink/55 leading-relaxed">
            Earn by completing <span className="font-medium">{p.title}</span>
          </p>
        </Link>
      ))}
    </div>
  );
}
