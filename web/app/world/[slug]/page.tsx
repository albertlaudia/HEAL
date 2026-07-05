import { notFound } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft, BookOpen, Sparkles } from 'lucide-react';
import { getBySlug, getPublished } from '@/lib/pb';
import type { HEALWorld } from '@/lib/pb';

export const revalidate = 3600;
export const dynamicParams = true;

export async function generateStaticParams() {
  // Skip PB fetch during build; render on-demand per request.
  return [];
}

const KIND_COPY: Record<string, { eyebrow: string; tone: string }> = {
  challenge: { eyebrow: 'A weight to pray into',  tone: 'We do not look away from this. We pray into it.' },
  grace:     { eyebrow: 'Good, already happening', tone: 'There is something here that God is doing. We pause to see it.' },
  gratitude: { eyebrow: 'Worth pausing for',        tone: 'We thank God out loud for this.' },
};

const TONE_HUE: Record<string, string> = {
  tender:    'border-amber-200/40 bg-amber-50/30',
  honest:    'border-stone-200/60 bg-stone-50/40',
  awestruck: 'border-indigo-200/40 bg-indigo-50/30',
  hopeful:   'border-sage-200/40 bg-sage-50/30',
  rejoicing: 'border-cyan-200/40 bg-cyan-50/30',
  steady:    'border-stone-200/50 bg-bone/40',
};

export default async function WorldDayPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const item: HEALWorld | null = await getBySlug('HEAL_world', slug);
  if (!item) notFound();

  const kind = KIND_COPY[item.prompt_kind || 'grace'];
  const toneClass = TONE_HUE[item.tone || 'tender'] || TONE_HUE.tender;

  // Fetch the previous 3 world records for a soft "recently" rail
  const recent: any[] = (await getPublished('HEAL_world', '-published_at', 'is_published = true', 4)) || [];
  const others = recent.filter(r => r.slug !== slug).slice(0, 3);

  return (
    <article className="container-quiet py-16">
      <Link href="/" className="inline-flex items-center gap-2 text-sm text-ink/60 hover:text-ink mb-10">
        <ArrowLeft size={14} /> Today
      </Link>

      <header className="mb-12">
        <div className="flex items-center gap-2 mb-4">
          <span className="text-[10px] tracking-[0.3em] uppercase text-ink/45">The world, today</span>
          <span className={`text-[10px] tracking-[0.2em] uppercase px-2 py-0.5 rounded-full border ${toneClass}`}>
            {item.prompt_kind}
          </span>
        </div>
        <h1 className="serif text-4xl md:text-5xl mb-3 leading-tight">{item.title}</h1>
        {item.published_at && (
          <p className="text-sm text-ink/45 serif italic">
            {new Date(item.published_at).toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
          </p>
        )}
        <p className="mt-4 text-ink/65 serif italic text-lg">{kind.tone}</p>
      </header>

      {/* PROMPT — the situation */}
      <section className="mb-10">
        <p className="text-[10px] tracking-[0.3em] uppercase text-ink/40 mb-2">In the world today</p>
        <p className="serif text-lg md:text-xl text-ink/85 leading-relaxed">
          {item.prompt}
        </p>
      </section>

      {/* SCRIPTURE — what the Bible says */}
      {item.scripture_ref && (
        <section className="mb-10 card-quiet p-6 md:p-8">
          <p className="text-[10px] tracking-[0.3em] uppercase text-ink/40 mb-3 flex items-center gap-2">
            <BookOpen size={11} /> What the Bible says
          </p>
          {item.scripture_text && (
            <blockquote className="serif text-lg md:text-xl text-ink/85 leading-relaxed mb-3">
              &ldquo;{item.scripture_text}&rdquo;
            </blockquote>
          )}
          <p className="text-sm text-ink/45 serif italic">— {item.scripture_ref}</p>
        </section>
      )}

      {/* REFLECTION */}
      <section className="mb-10">
        <p className="text-[10px] tracking-[0.3em] uppercase text-ink/40 mb-2">A reflection</p>
        <div className="prose-quiet text-lg max-w-none">
          {item.reflection.split('\n\n').map((p, i) => <p key={i} className="mb-4">{p}</p>)}
        </div>
      </section>

      {/* PRAYER */}
      <section className="mb-10 card-quiet p-6 md:p-8 bg-paper/60">
        <p className="text-[10px] tracking-[0.3em] uppercase text-ink/40 mb-3">A prayer</p>
        <div className="prose-quiet text-lg max-w-none italic text-ink/85">
          {item.prayer.split('\n\n').map((p, i) => <p key={i} className="mb-3">{p}</p>)}
        </div>
      </section>

      {/* EXPECTATION */}
      {item.expectation && (
        <section className="mb-16">
          <p className="text-[10px] tracking-[0.3em] uppercase text-ink/40 mb-2 flex items-center gap-2">
            <Sparkles size={11} /> What we could expect today
          </p>
          <p className="serif text-lg md:text-xl text-ink/85 leading-relaxed">
            {item.expectation}
          </p>
        </section>
      )}

      {/* RECENT RAIL */}
      {others.length > 0 && (
        <section className="border-t border-ink/8 pt-10">
          <p className="text-[10px] tracking-[0.3em] uppercase text-ink/40 mb-4">Recent days</p>
          <div className="grid sm:grid-cols-3 gap-4">
            {others.map((o: any) => (
              <Link key={o.id} href={`/world/${o.slug}`} className="block card-quiet p-4 hover:scale-[1.01] transition-all">
                <p className="text-[10px] tracking-[0.2em] uppercase text-ink/40 mb-1">
                  {o.published_at && new Date(o.published_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                </p>
                <p className="serif text-base leading-snug">{o.title}</p>
              </Link>
            ))}
          </div>
        </section>
      )}
    </article>
  );
}
