'use client';
// HEAL — Global search modal (Cmd/Ctrl+K).
//
// Searches across all HEAL content types: meditations, praise, prayers,
// scriptures, reflections, breathwork, quotes, and Bible books.

import { useEffect, useState, useRef, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

type SearchHit = {
  type: string;
  id: string;
  slug: string;
  title: string;
  subtitle: string;
  excerpt: string;
  illustrationUrl: string;
  url: string;
  score: number;
};

const TYPE_ICONS: Record<string, string> = {
  meditation: '🪷',
  praise: '🎵',
  prayer: '✦',
  scripture: '📖',
  essay: '☙',
  breathwork: '💨',
  quote: '❝',
  bible: '✦',
};

const TYPE_LABELS: Record<string, string> = {
  meditation: 'Meditation',
  praise: 'Praise',
  prayer: 'Prayer',
  scripture: 'Scripture',
  essay: 'Reflection',
  breathwork: 'Breathwork',
  quote: 'Quote',
  bible: 'Bible',
};

const TYPE_COLORS: Record<string, string> = {
  meditation: 'text-amber-700',
  praise: 'text-indigo-700',
  prayer: 'text-rose-700',
  scripture: 'text-sage-700',
  essay: 'text-clay-700',
  breathwork: 'text-cyan-700',
  quote: 'text-ink/80',
  bible: 'text-amber-800',
};

export default function HeaderSearch() {
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');
  const [hits, setHits] = useState<SearchHit[]>([]);
  const [loading, setLoading] = useState(false);
  const [activeIdx, setActiveIdx] = useState(0);
  const [totalHits, setTotalHits] = useState(0);
  const [took, setTook] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  // Cmd/Ctrl+K opens
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setOpen((v) => !v);
      } else if (e.key === 'Escape' && open) {
        setOpen(false);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open]);

  // Focus input when modal opens
  useEffect(() => {
    if (open) {
      setTimeout(() => inputRef.current?.focus(), 50);
    } else {
      setQ('');
      setHits([]);
      setActiveIdx(0);
    }
  }, [open]);

  // Debounced search
  useEffect(() => {
    if (q.length < 2) {
      setHits([]);
      setTotalHits(0);
      return;
    }
    setLoading(true);
    const t = setTimeout(async () => {
      try {
        const r = await fetch(`/api/search?q=${encodeURIComponent(q)}&limit=30`, {
          headers: { 'User-Agent': 'HealApp/1.0' },
        });
        const data = await r.json();
        setHits(data.hits || []);
        setTotalHits(data.totalHits || 0);
        setTook(data.took || 0);
        setActiveIdx(0);
      } catch {
        setHits([]);
      } finally {
        setLoading(false);
      }
    }, 200);
    return () => clearTimeout(t);
  }, [q]);

  const navigate = useCallback(
    (url: string) => {
      setOpen(false);
      router.push(url);
    },
    [router]
  );

  // Keyboard navigation
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setActiveIdx((i) => Math.min(i + 1, hits.length - 1));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        setActiveIdx((i) => Math.max(i - 1, 0));
      } else if (e.key === 'Enter' && hits[activeIdx]) {
        e.preventDefault();
        navigate(hits[activeIdx].url);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, hits, activeIdx, navigate]);

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        aria-label="Search"
        className="hidden md:flex items-center gap-2 text-xs text-ink/45 hover:text-ink/70 px-3 py-1.5 rounded-full border border-ink/10 hover:border-ink/20 transition-colors"
      >
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.3-4.3" />
        </svg>
        <span>Search</span>
        <kbd className="ml-2 text-[10px] font-mono text-ink/30 border border-ink/10 rounded px-1">⌘K</kbd>
      </button>
    );
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center pt-12 md:pt-24 px-4 animate-fade-in"
      onClick={() => setOpen(false)}
    >
      <div className="absolute inset-0 bg-ink/40 backdrop-blur-sm" />
      <div
        className="relative w-full max-w-2xl bg-bone rounded-2xl shadow-2xl border border-ink/10 overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Search input */}
        <div className="flex items-center gap-3 px-5 py-4 border-b border-ink/8">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-ink/40">
            <circle cx="11" cy="11" r="8" />
            <path d="m21 21-4.3-4.3" />
          </svg>
          <input
            ref={inputRef}
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search meditations, praise, prayers, scripture, Bible…"
            className="flex-1 bg-transparent outline-none text-base placeholder:text-ink/30"
          />
          {loading && (
            <div className="w-4 h-4 border-2 border-ink/20 border-t-ink/60 rounded-full animate-spin" />
          )}
          <kbd className="text-[10px] font-mono text-ink/30 border border-ink/10 rounded px-1.5 py-0.5">ESC</kbd>
        </div>

        {/* Results */}
        <div className="max-h-[60vh] overflow-y-auto">
          {q.length < 2 && (
            <div className="px-5 py-8 text-center">
              <p className="text-ink/40 text-sm">Type to search across all HEAL content.</p>
              <div className="mt-4 flex flex-wrap gap-2 justify-center">
                {['peace', 'psalm', 'forgiveness', 'gratitude', 'matthew', 'morning'].map((s) => (
                  <button
                    key={s}
                    onClick={() => setQ(s)}
                    className="text-xs text-ink/55 px-2.5 py-1 rounded-full bg-ink/5 hover:bg-ink/10 transition-colors"
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>
          )}

          {q.length >= 2 && hits.length === 0 && !loading && (
            <div className="px-5 py-8 text-center">
              <p className="text-ink/40 text-sm">No results for &ldquo;{q}&rdquo;</p>
              <p className="text-ink/30 text-xs mt-1">Try a Bible book name (Matthew, Psalm) or a topic (peace, prayer).</p>
            </div>
          )}

          {hits.length > 0 && (
            <ul className="py-2">
              {hits.map((hit, i) => (
                <li key={hit.id}>
                  <button
                    onClick={() => navigate(hit.url)}
                    onMouseEnter={() => setActiveIdx(i)}
                    className={`w-full flex items-start gap-3 px-5 py-3 text-left transition-colors ${
                      i === activeIdx ? 'bg-sage-50' : 'hover:bg-ink/3'
                    }`}
                  >
                    <div className="text-xl mt-0.5 flex-shrink-0">
                      {TYPE_ICONS[hit.type] || '✦'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className={`text-[10px] tracking-widest uppercase font-semibold ${TYPE_COLORS[hit.type]}`}>
                          {TYPE_LABELS[hit.type] || hit.type}
                        </span>
                      </div>
                      <p className="text-sm text-ink/90 font-medium truncate">{hit.title}</p>
                      {hit.subtitle && (
                        <p className="text-xs text-ink/50 italic truncate mt-0.5">{hit.subtitle}</p>
                      )}
                      {hit.excerpt && (
                        <p className="text-xs text-ink/60 mt-1 line-clamp-2 leading-relaxed">{hit.excerpt}</p>
                      )}
                    </div>
                    {i === activeIdx && (
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-sage-600 mt-1 flex-shrink-0">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    )}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Footer */}
        {hits.length > 0 && (
          <div className="px-5 py-2.5 border-t border-ink/8 flex items-center justify-between text-[11px] text-ink/40">
            <div className="flex items-center gap-3">
              <span><kbd className="font-mono">↑</kbd> <kbd className="font-mono">↓</kbd> navigate</span>
              <span><kbd className="font-mono">↵</kbd> open</span>
            </div>
            <span>{totalHits} result{totalHits === 1 ? '' : 's'} · {took}ms</span>
          </div>
        )}
      </div>
    </div>
  );
}
