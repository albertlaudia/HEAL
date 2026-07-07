'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { Sparkles, Wind, X, BookOpen, Music, BookHeart, ArrowDown } from 'lucide-react';

const STORAGE_KEY = 'heal:welcome-dismissed';
const SEEN_VERSION = 'v3-mobile-first';

export function WelcomeOverlay() {
  const [visible, setVisible] = useState(false);
  const [autoClosed, setAutoClosed] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const seen = localStorage.getItem(STORAGE_KEY);
    if (seen === SEEN_VERSION) return;
    // Show almost immediately — mobile users scroll fast, 1.8s is too late
    const t = setTimeout(() => setVisible(true), 350);
    // Auto-dismiss after 14s if user did nothing — gives them time to read it
    const auto = setTimeout(() => {
      setVisible(false);
      setAutoClosed(true);
      localStorage.setItem(STORAGE_KEY, SEEN_VERSION);
    }, 14000);
    return () => {
      clearTimeout(t);
      clearTimeout(auto);
    };
  }, []);

  // Lock background scroll when modal is open (mobile)
  useEffect(() => {
    if (!visible) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => { document.body.style.overflow = prev; };
  }, [visible]);

  const dismiss = () => {
    localStorage.setItem(STORAGE_KEY, SEEN_VERSION);
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <>
      {/* Mobile-friendly top banner — sticky, compact, doesn't block the page */}
      <div
        ref={containerRef}
        role="dialog"
        aria-label="Welcome to HEAL"
        aria-modal="true"
        onClick={(e) => {
          // Click on backdrop (outside the card) closes the welcome
          if (e.target === e.currentTarget) dismiss();
        }}
        className="fixed inset-x-0 top-0 z-50 md:inset-0 md:flex md:items-center md:justify-center md:p-6 md:bg-bone/90 md:backdrop-blur-md bg-bone md:bg-transparent"
        style={{ animation: 'fade-in 350ms ease-out both' }}
      >
        <div
          className="card-quiet w-full md:max-w-lg p-5 md:p-10 relative shadow-2xl md:my-8 rounded-b-3xl md:rounded-3xl border-b-4 md:border-b border-amber-300/60 max-h-[90vh] overflow-y-auto"
        >
          <button
            onClick={dismiss}
            className="absolute top-3 right-3 md:top-4 md:right-4 p-2 text-ink/40 hover:text-ink/70"
            aria-label="Close welcome"
          >
            <X size={18} />
          </button>

          <div className="text-center mb-4 md:mb-6 pt-2 md:pt-0">
            <p className="text-[10px] md:text-xs tracking-[0.3em] uppercase text-sage-700 mb-2 md:mb-3">A small welcome</p>
            <h2 className="serif text-2xl md:text-4xl mb-2 md:mb-3">Welcome to HEAL</h2>
            <p className="serif italic text-sm md:text-base text-ink/65 leading-relaxed">
              A small rhythm called H.E.A.L. Pause. Exhale. Align. Listen.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-2 mb-4 md:mb-6">
            <Link
              href="/now"
              onClick={dismiss}
              className="flex flex-col items-center gap-1.5 md:gap-2 p-3 md:p-4 rounded-2xl border border-amber-200/50 bg-amber-50/40 hover:scale-[1.03] transition-transform"
            >
              <Sparkles size={18} className="text-amber-700" />
              <p className="text-xs font-medium">A quick reset</p>
              <p className="text-[10px] text-ink/50">90 sec</p>
            </Link>
            <Link
              href="/meditate"
              onClick={dismiss}
              className="flex flex-col items-center gap-1.5 md:gap-2 p-3 md:p-4 rounded-2xl border border-sage-200/50 bg-sage-50/40 hover:scale-[1.03] transition-transform"
            >
              <BookOpen size={18} className="text-sage-700" />
              <p className="text-xs font-medium">Today's meditation</p>
              <p className="text-[10px] text-ink/50">5-8 min</p>
            </Link>
            <Link
              href="/breathe"
              onClick={dismiss}
              className="flex flex-col items-center gap-1.5 md:gap-2 p-3 md:p-4 rounded-2xl border border-cyan-200/50 bg-cyan-50/40 hover:scale-[1.03] transition-transform"
            >
              <Wind size={18} className="text-cyan-700" />
              <p className="text-xs font-medium">A breath</p>
              <p className="text-[10px] text-ink/50">1-3 min</p>
            </Link>
            <Link
              href="/praise"
              onClick={dismiss}
              className="flex flex-col items-center gap-1.5 md:gap-2 p-3 md:p-4 rounded-2xl border border-indigo-200/50 bg-indigo-50/40 hover:scale-[1.03] transition-transform"
            >
              <Music size={18} className="text-indigo-700" />
              <p className="text-xs font-medium">A song</p>
              <p className="text-[10px] text-ink/50">sing along</p>
            </Link>
          </div>

          <p className="text-center text-[10px] tracking-widest uppercase text-ink/40 mb-2 md:mb-3">
            Or take your time
          </p>
          <div className="flex flex-wrap items-center justify-center gap-1.5 md:gap-2 text-xs">
            <Link href="/scripture" onClick={dismiss} className="px-2.5 py-1.5 md:px-3 rounded-full border border-ink/10 hover:border-ink/30 text-ink/60 hover:text-ink">
              <BookOpen size={11} className="inline mr-1" /> Read
            </Link>
            <Link href="/prayers" onClick={dismiss} className="px-2.5 py-1.5 md:px-3 rounded-full border border-ink/10 hover:border-ink/30 text-ink/60 hover:text-ink">
              <BookHeart size={11} className="inline mr-1" /> Pray
            </Link>
            <Link href="/essays" onClick={dismiss} className="px-2.5 py-1.5 md:px-3 rounded-full border border-ink/10 hover:border-ink/30 text-ink/60 hover:text-ink">
              Read a reflection
            </Link>
            <Link href="/about" onClick={dismiss} className="px-2.5 py-1.5 md:px-3 rounded-full border border-ink/10 hover:border-ink/30 text-ink/60 hover:text-ink">
              Why HEAL
            </Link>
          </div>

          <div className="text-center mt-4 md:mt-6">
            <button
              onClick={dismiss}
              className="text-xs text-ink/40 hover:text-ink/60 underline underline-offset-4"
            >
              I'll explore on my own
            </button>
          </div>

          {/* Mobile-only: subtle hint that the user can scroll to dismiss or read the rest */}
          <p className="md:hidden text-center mt-3 text-[10px] text-ink/30 flex items-center justify-center gap-1">
            <ArrowDown size={10} />
            tap outside or use X to close
          </p>
        </div>
      </div>

      {/* Auto-close notification (only if it auto-closed) */}
      {autoClosed && null}
    </>
  );
}

// A persistent, low-emphasis "First time here?" pill that lives in the page
// after the welcome has been dismissed. Replaces the big modal for users
// who scrolled past it.
export function WelcomePill() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    const seen = localStorage.getItem(STORAGE_KEY);
    if (seen === SEEN_VERSION) return;
    // Only show pill if the welcome was dismissed without choosing an action
    // — give the user a way to come back to the H.E.A.L. framework.
    const t = setTimeout(() => {
      const stillUnseen = localStorage.getItem(STORAGE_KEY) !== SEEN_VERSION;
      if (stillUnseen) setShow(true);
    }, 8000);
    return () => clearTimeout(t);
  }, []);

  const open = () => {
    setShow(false);
    // Re-open the welcome by clearing the storage
    localStorage.removeItem(STORAGE_KEY);
    // Force a one-time reload to trigger the welcome again
    window.location.reload();
  };

  if (!show) return null;

  return (
    <button
      onClick={open}
      className="fixed bottom-20 right-4 z-40 px-4 py-2.5 rounded-full bg-ink/90 text-bone text-xs shadow-xl hover:scale-105 active:scale-95 transition-transform flex items-center gap-2"
      aria-label="Reopen welcome"
    >
      <Sparkles size={12} className="text-amber-300" />
      <span>First time here?</span>
    </button>
  );
}
