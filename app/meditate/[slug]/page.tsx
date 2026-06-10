import { notFound } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { headers } from 'next/headers';
import { getBySlug, getPublished } from '@/lib/pb';
import { ThemeBadge } from '@/components/content/ThemeBadge';
import { MeditationPlayer } from '@/components/meditate/MeditationPlayer';
import { SaveButton } from '@/components/content/SaveButton';
import { ShareButton } from '@/components/content/ShareButton';
import { JournalInline } from '@/components/content/JournalInline';
import { formatDuration } from '@/lib/utils';
import { ArrowLeft, ArrowRight } from 'lucide-react';
import { TrackView } from '@/components/tracking/TrackView';

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

  // Build share URL from request headers
  const h = await headers();
  const proto = h.get('x-forwarded-proto') || 'https';
  const host = h.get('host') || 'heal.app';
  const shareUrl = `${proto}://${host}/meditate/${m.slug}`;

  return (
    <article className="container-wide py-12">
      <TrackView kind="meditation" slug={m.slug} />

      <Link href="/meditate" className="inline-flex items-center gap-2 text-sm text-ink/60 hover:text-ink mb-8">
        <ArrowLeft size={14} /> Library
      </Link>

      <header className="max-w-2xl mx-auto text-center mb-12">
        <div className="flex items-center justify-center gap-2 mb-4">
          <ThemeBadge theme={m.theme} />
          {m.season && <span className="text-xs text-ink/50 uppercase tracking-wider">· {m.season}</span>}
          {m.duration_seconds ? <span className="text-xs text-ink/50">· {formatDuration(m.duration_seconds)}</span> : null}
        </div>
        <h1 className="serif text-4xl md:text-5xl mb-4">{m.title}</h1>
        {m.scripture_ref && (
          <p className="serif italic text-ink/60">— {m.scripture_ref}</p>
        )}
      </header>

      {(m.illustration_url || m.slug) && (
        <div className="relative max-w-3xl mx-auto aspect-[2/1] rounded-2xl overflow-hidden mb-12 bg-sage-100">
          <Image
            src={m.illustration_url || `/images/meditations/illustration-${m.slug}.png`}
            alt={m.title}
            fill
            className="object-cover"
            priority
          />
        </div>
      )}

      <MeditationPlayer
        title={m.title}
        audioUrl={m.audio_url}
        fallbackSlug={m.slug}
        duration={m.duration_seconds}
        body={m.body}
        prayer={m.prayer}
        scriptureRef={m.scripture_ref}
        scriptureText={m.scripture_text}
        reflection={m.reflection}
        illustrationUrl={m.illustration_url}
      />

      {m.scripture_text && (
        <section className="max-w-2xl mx-auto mt-16 p-8 md:p-12 bg-paper border border-ink/5 rounded-2xl">
          <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">Scripture</p>
          <blockquote className="serif text-2xl leading-relaxed text-ink/85">
            "{m.scripture_text}"
          </blockquote>
          <p className="mt-4 serif italic text-ink/60">— {m.scripture_ref}</p>
        </section>
      )}

      {m.reflection && (
        <section className="max-w-2xl mx-auto mt-12">
          <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">For reflection</p>
          <p className="serif text-xl leading-relaxed text-ink/80 italic">{m.reflection}</p>
        </section>
      )}

      <div className="max-w-2xl mx-auto mt-12 flex flex-wrap gap-3">
        <SaveButton
          kind="meditation"
          slug={m.slug}
          title={m.title}
          subtitle={m.scripture_ref}
          illustration_url={m.illustration_url}
        />
        <ShareButton
          title={m.title}
          text={`"${m.reflection || m.title}" — HEAL`}
          url={shareUrl}
        />
      </div>

      <section className="max-w-2xl mx-auto mt-12">
        <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">Your journal</p>
        <JournalInline refKind="meditation" refSlug={m.slug} refTitle={m.title} />
      </section>

      <nav className="max-w-2xl mx-auto mt-16 pt-12 border-t border-ink/5 flex justify-between text-sm">
        {prev ? (
          <Link href={`/meditate/${prev.slug}`} className="text-ink/60 hover:text-ink flex items-center gap-2">
            <ArrowLeft size={14} /> {prev.title}
          </Link>
        ) : <span />}
        {next ? (
          <Link href={`/meditate/${next.slug}`} className="text-ink/60 hover:text-ink flex items-center gap-2">
            {next.title} <ArrowRight size={14} />
          </Link>
        ) : <span />}
      </nav>
    </article>
  );
}
