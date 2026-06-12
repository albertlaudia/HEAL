import { notFound } from 'next/navigation';
import { getBySlug, getPublished } from '@/lib/pb';
import { TrackView } from '@/components/tracking/TrackView';
import { MeditationRitualClient } from '@/components/meditate/MeditationRitualClient';

export const revalidate = 3600;

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const m: any = await getBySlug('HEAL_meditations', slug);
  if (!m) return { title: 'Meditation' };
  return {
    title: m.title,
    description: m.reflection || `${m.title} — a guided meditation from HEAL.`,
  };
}

export async function generateStaticParams() {
  const all = await getPublished('HEAL_meditations', 'sort_order', 'is_published = true');
  return all.map((m: any) => ({ slug: m.slug }));
}

export default async function MeditationPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const m: any = await getBySlug('HEAL_meditations', slug);
  if (!m) notFound();

  // Find next/prev by sort_order
  const all: any[] = await getPublished('HEAL_meditations', 'sort_order', 'is_published = true');
  const idx = all.findIndex(x => x.id === m.id);
  const prev = idx > 0 ? all[idx - 1] : null;
  const next = idx < all.length - 1 ? all[idx + 1] : null;

  // Build share URL from request headers — server-side, no DOM
  const { headers } = await import('next/headers');
  const h = await headers();
  const proto = h.get('x-forwarded-proto') || 'https';
  const host = h.get('host') || 'heal.app';
  const shareUrl = `${proto}://${host}/meditate/${m.slug}`;

  return (
    <>
      <TrackView kind="meditation" slug={m.slug} />
      <MeditationRitualClient m={m} shareUrl={shareUrl} prev={prev} next={next} />
    </>
  );
}
