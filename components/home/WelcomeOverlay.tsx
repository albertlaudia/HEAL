'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Sparkles, Wind, X, BookOpen, Music, BookHeart } from 'lucide-react';

const STORAGE_KEY = 'heal:welcome-dismissed';
const SEEN_VERSION = 'v2-h-e-a-l';

export function WelcomeOverlay() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const seen = localStorage.getItem(STORAGE_KEY);
    if (seen === SEEN_VERSION) return;
    // Show after 1.5s so the home page has a chance to paint
    const t = setTimeout(() => setVisible(true), 1800);
    return () => clearTimeout(t);
  }, []);

  const dismiss = () => {
    localStorage.setItem(STORAGE_KEY, SEEN_VERSION);
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-bone/90 backdrop-blur-md animate-fade-in">
      <div className="card-quiet max-w-lg w-full p-8 md:p-10 relative shadow-2xl">
        <button
          onClick={dismiss}
          className="absolute top-4 right-4 p-2 text-ink/40 hover:text-ink/70"
          aria-label="Close"
        >
          <X size={18} />
        </button>

        <div className="text-center mb-6">
          <p className="text-xs tracking-[0.3em] uppercase text-sage-700 mb-3">A small welcome</p>
          <h2 className="serif text-3xl md:text-4xl mb-3">Welcome to HEAL</h2>
          <p className="serif italic text-ink/65 leading-relaxed">
            A small rhythm called H.E.A.L. Pause. Exhale. Align. Listen.
          </p>
        </div>

        <div className="grid grid-cols-2 gap-2 mb-6">
          <Link
            href="/now"
            onClick={dismiss}
            className="flex flex-col items-center gap-2 p-4 rounded-2xl border border-amber-200/50 bg-amber-50/40 hover:scale-[1.03] transition-transform"
          >
            <Sparkles size={18} className="text-amber-700" />
            <p className="text-xs font-medium">A quick reset</p>
            <p className="text-[10px] text-ink/50">90 sec</p>
          </Link>
          <Link
            href="/meditate"
            onClick={dismiss}
            className="flex flex-col items-center gap-2 p-4 rounded-2xl border border-sage-200/50 bg-sage-50/40 hover:scale-[1.03] transition-transform"
          >
            <BookOpen size={18} className="text-sage-700" />
            <p className="text-xs font-medium">Today's meditation</p>
            <p className="text-[10px] text-ink/50">5-8 min</p>
          </Link>
          <Link
            href="/breathe"
            onClick={dismiss}
            className="flex flex-col items-center gap-2 p-4 rounded-2xl border border-cyan-200/50 bg-cyan-50/40 hover:scale-[1.03] transition-transform"
          >
            <Wind size={18} className="text-cyan-700" />
            <p className="text-xs font-medium">A breath</p>
            <p className="text-[10px] text-ink/50">1-3 min</p>
          </Link>
          <Link
            href="/praise"
            onClick={dismiss}
            className="flex flex-col items-center gap-2 p-4 rounded-2xl border border-indigo-200/50 bg-indigo-50/40 hover:scale-[1.03] transition-transform"
          >
            <Music size={18} className="text-indigo-700" />
            <p className="text-xs font-medium">A song</p>
            <p className="text-[10px] text-ink/50">sing along</p>
          </Link>
        </div>

        <p className="text-center text-[10px] tracking-widest uppercase text-ink/40 mb-3">
          Or take your time
        </p>
        <div className="flex flex-wrap items-center justify-center gap-2 text-xs">
          <Link href="/scripture" onClick={dismiss} className="px-3 py-1.5 rounded-full border border-ink/10 hover:border-ink/30 text-ink/60 hover:text-ink">
            <BookOpen size={11} className="inline mr-1" /> Read
          </Link>
          <Link href="/prayers" onClick={dismiss} className="px-3 py-1.5 rounded-full border border-ink/10 hover:border-ink/30 text-ink/60 hover:text-ink">
            <BookHeart size={11} className="inline mr-1" /> Pray
          </Link>
          <Link href="/essays" onClick={dismiss} className="px-3 py-1.5 rounded-full border border-ink/10 hover:border-ink/30 text-ink/60 hover:text-ink">
            Read an essay
          </Link>
          <Link href="/about" onClick={dismiss} className="px-3 py-1.5 rounded-full border border-ink/10 hover:border-ink/30 text-ink/60 hover:text-ink">
            Why HEAL
          </Link>
        </div>

        <div className="text-center mt-6">
          <button
            onClick={dismiss}
            className="text-xs text-ink/40 hover:text-ink/60 underline underline-offset-4"
          >
            I'll explore on my own
          </button>
        </div>
      </div>
    </div>
  );
}
