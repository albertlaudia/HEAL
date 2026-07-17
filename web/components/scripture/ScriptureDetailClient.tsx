// HEAL — Scripture detail client view.
// Renders a single scripture verse with its text, translation, and
// 5 related meditations to sit with.

'use client';

import Link from 'next/link';
import { ArrowLeft, BookOpen, Share2 } from 'lucide-react';

interface Verse {
  id: string;
  slug: string;
  reference?: string;
  title?: string;
  text?: string;
  translation?: string;
  reflection?: string;
  context?: string;
  theme?: string;
}

export function ScriptureDetailClient({
  verse,
  related,
}: {
  verse: Verse;
  related: any[];
}) {
  const onShare = () => {
    if (typeof navigator === 'undefined' || !navigator.share) return;
    navigator.share({
      title: verse.title || verse.reference || 'Scripture',
      text: verse.text,
      url: typeof window !== 'undefined' ? window.location.href : '',
    }).catch(() => {});
  };

  return (
    <article className="container-quiet py-12 md:py-16">
      <Link
        href="/scripture"
        className="inline-flex items-center gap-1.5 text-sm text-ink/50 hover:text-ink/80 mb-10"
      >
        <ArrowLeft size={14} /> All scripture
      </Link>

      <header className="mb-10">
        {verse.theme && (
          <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">
            {verse.theme}
          </p>
        )}
        <h1 className="serif text-4xl md:text-5xl mb-3 leading-tight">
          {verse.reference || verse.title || 'Scripture'}
        </h1>
        {verse.translation && (
          <p className="text-sm text-ink/50">{verse.translation}</p>
        )}

        <div className="mt-6 flex items-center gap-3">
          <button
            onClick={onShare}
            className="btn-pill"
            aria-label="Share"
          >
            <Share2 size={14} /> Share
          </button>
        </div>
      </header>

      {verse.text && (
        <section className="mb-12 p-8 md:p-12 rounded-2xl bg-ink/[0.02] border border-ink/5">
          <p className="font-serif text-2xl md:text-3xl leading-relaxed text-ink whitespace-pre-line">
            {verse.text}
          </p>
        </section>
      )}

      {verse.context && (
        <section className="mb-12">
          <h2 className="serif text-2xl mb-4">Context</h2>
          <p className="text-lg leading-relaxed text-ink/80">{verse.context}</p>
        </section>
      )}

      {verse.reflection && (
        <section className="mb-12 p-8 rounded-2xl bg-sage-50/40 border border-sage-200/30">
          <p className="text-xs tracking-[0.3em] uppercase text-sage-700 mb-3">
            Sit with this
          </p>
          <p className="text-lg leading-relaxed text-ink/85">{verse.reflection}</p>
        </section>
      )}

      {related.length > 0 && (
        <section>
          <h2 className="serif text-2xl mb-6">Meditations on this verse</h2>
          <div className="grid sm:grid-cols-2 gap-4">
            {related.map((m) => (
              <Link
                key={m.slug}
                href={`/meditate/${m.slug}`}
                className="card-quiet p-4 flex items-start gap-4 hover:bg-ink/[0.02]"
              >
                <div className="w-12 h-12 rounded-xl bg-ink/5 flex items-center justify-center flex-shrink-0">
                  <BookOpen size={18} className="text-ink/50" />
                </div>
                <div className="min-w-0">
                  <p className="font-medium truncate">{m.title}</p>
                  {m.scripture_ref && (
                    <p className="text-sm text-ink/60 truncate">{m.scripture_ref}</p>
                  )}
                </div>
              </Link>
            ))}
          </div>
        </section>
      )}
    </article>
  );
}
