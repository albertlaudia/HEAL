// HEAL — Praise song detail page.
// Detail view for an individual praise song. Shows lyrics, scripture refs,
// reflection, and a play button. Plays audio via the same audio context
// the rest of the site uses.

import { notFound } from 'next/navigation';
import { getBySlug, getPublished } from '@/lib/pb';
import { TrackView } from '@/components/tracking/TrackView';
import { PraiseSongDetailClient } from '@/components/praise/PraiseSongDetailClient';

export const revalidate = 3600;
export const dynamicParams = true;

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const s: any = await getBySlug('HEAL_praise', slug);
  if (!s) return { title: 'Song · HEAL' };
  return {
    title: `${s.title} — HEAL Praise`,
    description: s.lyrics?.slice(0, 160) || `${s.title} — a praise song from HEAL.`,
  };
}

export default async function PraiseSongPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const song: any = await getBySlug('HEAL_praise', slug);
  if (!song) notFound();

  // Recommend next 5 songs in the same category (or all if no category)
  const sameCat: any[] = await getPublished(
    'HEAL_praise',
    'sort_order,id',
    song.category
      ? `is_published = true && category = '${song.category.replace(/'/g, "''")}'`
      : 'is_published = true',
    6
  );
  const more = sameCat
    .filter((x) => x.slug !== song.slug)
    .slice(0, 5);

  return (
    <div>
      <TrackView kind="praise" slug={song.slug} title={song.title} />
      <PraiseSongDetailClient song={song} more={more} />
    </div>
  );
}
