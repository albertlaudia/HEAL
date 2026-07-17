// HEAL — Today's Praise hero (web).
//
// A full-bleed, illustrated hero card that surfaces one song per day
// at the top of the praise library. The pick is deterministic by
// day-of-year so the user sees a fresh song each day but the same
// pick across sessions.
//
// Clicking the card navigates to the song's detail page.

'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useMemo } from 'react';
import type { HEALPraise } from '@/lib/pb';

function pickTodays(songs: HEALPraise[]): HEALPraise | null {
  if (songs.length === 0) return null;
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 1);
  const dayOfYear = Math.floor((now.getTime() - start.getTime()) / 86_400_000);
  // 1. Prefer a song with matching day_of_year
  const exact = songs.find((s) => s.day_of_year === dayOfYear);
  if (exact) return exact;
  // 2. Fall back to a deterministic pick
  return songs[dayOfYear % songs.length];
}

function illustrationUrl(song: HEALPraise): string {
  if (song.illustration_url) return song.illustration_url;
  return `https://f004.backblazeb2.com/file/GOPResources/heal/heal/images/praise/praise-${song.slug}.png`;
}

export function TodaysPraiseHero({
  songs,
  onClearFilters,
}: {
  songs: HEALPraise[];
  onClearFilters?: () => void;
}) {
  const today = useMemo(() => pickTodays(songs), [songs]);
  if (!today) return null;
  const url = illustrationUrl(today);
  return (
    <Link
      href={`/praise/${today.slug}`}
      className="group block relative overflow-hidden rounded-3xl mb-10 shadow-sm hover:shadow-md transition-all"
      aria-label={`Today's praise: ${today.title}`}
    >
      <div className="relative aspect-[16/9] md:aspect-[21/9]">
        <Image
          src={url}
          alt={today.title}
          fill
          sizes="(max-width: 768px) 100vw, 1200px"
          className="object-cover group-hover:scale-[1.02] transition-transform duration-700"
          priority
        />
        {/* Gradient overlay for text legibility */}
        <div
          className="absolute inset-0 bg-gradient-to-t from-bone/95 via-bone/30 to-transparent"
          aria-hidden="true"
        />
        <div className="absolute inset-x-0 bottom-0 p-6 md:p-10">
          <span className="inline-block px-3 py-1 text-[10px] tracking-[0.2em] uppercase bg-ink text-bone rounded-full mb-3">
            Today's Praise
          </span>
          <h2 className="serif text-3xl md:text-5xl text-ink leading-tight mb-2 max-w-2xl">
            {today.title}
          </h2>
          {today.subtitle && (
            <p className="serif italic text-ink/65 text-base md:text-lg max-w-xl">
              {today.subtitle}
            </p>
          )}
          {today.scripture_refs && today.scripture_refs.length > 0 && (
            <p className="text-[11px] tracking-widest uppercase text-ink/50 mt-3">
              {today.scripture_refs.slice(0, 2).join(' · ')}
            </p>
          )}
        </div>
      </div>
    </Link>
  );
}
