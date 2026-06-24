'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Pause, Wind, BookOpen, Sparkles, ArrowRight, X } from 'lucide-react';

const PRINCIPLES = [
  {
    letter: 'H',
    word: 'Halt',
    body: 'Pause your busy day, step away from distractions, and intentionally stop striving.',
    icon: Pause,
    accent: 'text-amber-700',
    bg: 'bg-amber-50/60',
    border: 'border-amber-200/60',
  },
  {
    letter: 'E',
    word: 'Exhale',
    body: 'Breathe out anxiety and release your daily burdens to God.',
    icon: Wind,
    accent: 'text-cyan-700',
    bg: 'bg-cyan-50/60',
    border: 'border-cyan-200/60',
  },
  {
    letter: 'A',
    word: 'Align',
    body: 'Bring your racing thoughts back into alignment with God\'s Word and the present moment.',
    icon: BookOpen,
    accent: 'text-sage-700',
    bg: 'bg-sage-50/60',
    border: 'border-sage-200/60',
  },
  {
    letter: 'L',
    word: 'Listen',
    body: 'Be still in the silence and listen for the gentle guidance of the Holy Spirit.',
    icon: Sparkles,
    accent: 'text-indigo-700',
    bg: 'bg-indigo-50/60',
    border: 'border-indigo-200/60',
  },
];

export function HealPrinciples({ compact = false }: { compact?: boolean }) {
  const [dismissed, setDismissed] = useState(false);
  if (dismissed) return null;

  return (
    <section className="container-wide py-12 relative">
      {!compact && (
        <div className="flex items-center justify-between mb-8 max-w-4xl mx-auto">
          <div>
            <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-2">The practice</p>
            <h2 className="serif text-3xl md:text-4xl">A quiet rhythm called H.E.A.L.</h2>
          </div>
          <button
            onClick={() => setDismissed(true)}
            className="text-ink/30 hover:text-ink/60 p-2"
            aria-label="Dismiss"
          >
            <X size={16} />
          </button>
        </div>
      )}

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 md:gap-4 max-w-4xl mx-auto">
        {PRINCIPLES.map((p, i) => {
          const Icon = p.icon;
          // Map principle to a quick action
          const actionHref = i === 0 ? '/meditate' : i === 1 ? '/breathe' : i === 2 ? '/scripture' : '/journal';
          return (
            <Link
              key={p.letter}
              href={actionHref}
              className={`group relative card-quiet p-5 md:p-6 hover:scale-[1.02] transition-transform duration-500 ${p.bg} ${p.border} border`}
            >
              <div className="flex items-baseline gap-2 mb-2">
                <span className={`serif text-3xl md:text-4xl ${p.accent} leading-none`}>
                  {p.letter}
                </span>
                <span className="text-xs tracking-widest uppercase text-ink/50">
                  {p.word}
                </span>
              </div>
              <p className="text-xs md:text-sm text-ink/65 leading-relaxed line-clamp-3 md:line-clamp-4">
                {p.body}
              </p>
              <div className="mt-3 flex items-center justify-between">
                <Icon size={14} className={p.accent} />
                <ArrowRight size={12} className="text-ink/30 group-hover:text-ink/70 group-hover:translate-x-1 transition-all" />
              </div>
            </Link>
          );
        })}
      </div>

      {!compact && (
        <p className="text-center mt-6 text-xs text-ink/40 max-w-xl mx-auto">
          Each step is small. Together they make a practice that returns you to the present and to God.
        </p>
      )}
    </section>
  );
}
