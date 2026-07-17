// HEAL — Scripture detail page.
// Detail view for a single scripture. Shows reference, translation,
// and the text. Suggests a related meditation or prayer.

import { notFound } from 'next/navigation';
import { getBySlug, getPublished } from '@/lib/pb';
import { TrackView } from '@/components/tracking/TrackView';
import { ScriptureDetailClient } from '@/components/scripture/ScriptureDetailClient';

export const revalidate = 3600;
export const dynamicParams = true;

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const s: any = await getBySlug('HEAL_scriptures', slug);
  if (!s) return { title: 'Scripture · HEAL' };
  return {
    title: `${s.reference || s.title} — HEAL Scripture`,
    description: s.text?.slice(0, 160) || `${s.reference} — sit with this verse.`,
  };
}

export default async function ScripturePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const verse: any = await getBySlug('HEAL_scriptures', slug);
  if (!verse) notFound();

  // Suggest related meditations by scripture_ref prefix
  const related: any[] = await getPublished(
    'HEAL_meditations',
    'sort_order,id',
    'is_published = true',
    5
  );

  return (
    <div>
      <TrackView kind="scripture" slug={verse.slug} />
      <ScriptureDetailClient verse={verse} related={related} />
    </div>
  );
}
