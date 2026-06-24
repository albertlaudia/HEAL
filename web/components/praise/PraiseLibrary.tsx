'use client';

import { useState, useMemo } from 'react';
import { Search } from 'lucide-react';
import type { HEALPraise } from '@/lib/pb';
import { SongCard } from './SongCard';

type SortKey = 'sort_order' | 'title' | 'newest';

const EMOTION_DESCRIPTIONS: Record<string, string> = {
  companioned: 'feels held',
  settled:     'feels steady',
  lifted:       'feels glad',
  restored:     'feels made whole',
  awestruck:    'feels wonder',
  honest:       'feels honest',
  reverent:     'feels holy',
};

const EMOTION_COLORS: Record<string, string> = {
  companioned: 'border-amber-300/60 bg-amber-50/40 text-amber-800',
  settled:     'border-sage-300/60 bg-sage-50/40 text-sage-800',
  lifted:      'border-cyan-300/60 bg-cyan-50/40 text-cyan-800',
  restored:    'border-indigo-300/60 bg-indigo-50/40 text-indigo-800',
  awestruck:   'border-purple-300/60 bg-purple-50/40 text-purple-800',
  honest:      'border-rose-300/60 bg-rose-50/40 text-rose-800',
  reverent:    'border-stone-300/60 bg-stone-50/40 text-stone-800',
};

export function PraiseLibrary({
  songs,
  allEmotions,
  allTags,
  allContexts,
}: {
  songs: HEALPraise[];
  allEmotions: string[];
  allTags: string[];
  allContexts: string[];
}) {
  const [query, setQuery] = useState('');
  const [activeEmotion, setActiveEmotion] = useState<string | null>(null);
  const [activeTag, setActiveTag] = useState<string | null>(null);
  const [activeContext, setActiveContext] = useState<string | null>(null);
  const [sortKey, setSortKey] = useState<SortKey>('sort_order');

  const filtered = useMemo(() => {
    let list = songs;
    if (activeEmotion) list = list.filter(s => s.emotion === activeEmotion);
    if (activeTag) list = list.filter(s => (s.tags || []).includes(activeTag));
    if (activeContext) list = list.filter(s => (s.best_for || []).includes(activeContext));
    if (query.trim()) {
      const q = query.trim().toLowerCase();
      list = list.filter(s => {
        const haystack = [
          s.title, s.subtitle, s.description, s.category,
          ...(s.tags || []),
          ...(s.best_for || []),
          s.scripture_refs?.join(' '),
          s.emotion, s.mood,
        ].filter(Boolean).join(' ').toLowerCase();
        return haystack.includes(q);
      });
    }
    if (sortKey === 'title') {
      list = [...list].sort((a, b) => a.title.localeCompare(b.title));
    } else if (sortKey === 'newest') {
      list = [...list].sort((a, b) => (b.day_of_year || 0) - (a.day_of_year || 0));
    } else {
      list = [...list].sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0));
    }
    return list;
  }, [songs, query, activeEmotion, activeTag, activeContext, sortKey]);

  const clearFilters = () => {
    setQuery('');
    setActiveEmotion(null);
    setActiveTag(null);
    setActiveContext(null);
  };

  const hasFilter = query.trim() || activeEmotion || activeTag || activeContext;

  return (
    <div>
      {/* Search + sort bar */}
      <div className="mb-6 flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <div className="relative flex-1">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink/40 pointer-events-none" />
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by title, scripture, mood, tag..."
            className="w-full pl-9 pr-3 py-2.5 rounded-full bg-paper border border-ink/10 focus:border-sage-400 focus:outline-none text-sm"
            aria-label="Search songs"
          />
        </div>
        <select
          value={sortKey}
          onChange={(e) => setSortKey(e.target.value as SortKey)}
          className="px-3 py-2.5 rounded-full bg-paper border border-ink/10 text-sm focus:border-sage-400 focus:outline-none"
          aria-label="Sort songs"
        >
          <option value="sort_order">Curated order</option>
          <option value="title">Title (A-Z)</option>
          <option value="newest">By day of year</option>
        </select>
      </div>

      {/* Emotion filter — the headline UX (emotion-driven discovery) */}
      <div className="mb-6">
        <p className="text-[10px] tracking-widest uppercase text-ink/40 mb-2.5">
          How do you want to feel?
        </p>
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setActiveEmotion(null)}
            className={`px-3 py-1.5 rounded-full text-xs transition-colors border ${
              activeEmotion === null
                ? 'border-ink bg-ink text-bone'
                : 'border-ink/10 text-ink/60 hover:border-ink/30 hover:text-ink'
            }`}
          >
            All
          </button>
          {allEmotions.map(emotion => {
            const active = activeEmotion === emotion;
            const colors = EMOTION_COLORS[emotion] || 'border-ink/10 text-ink/60';
            return (
              <button
                key={emotion}
                onClick={() => setActiveEmotion(active ? null : emotion)}
                className={`px-3 py-1.5 rounded-full text-xs transition-all border ${
                  active
                    ? colors + ' ring-1 ring-inset ring-ink/20 scale-[1.02]'
                    : 'border-ink/10 text-ink/55 hover:border-ink/30'
                }`}
                title={EMOTION_DESCRIPTIONS[emotion] || emotion}
              >
                {EMOTION_DESCRIPTIONS[emotion] || emotion}
              </button>
            );
          })}
        </div>
      </div>

      {/* Context filter */}
      {allContexts.length > 0 && (
        <div className="mb-6">
          <p className="text-[10px] tracking-widest uppercase text-ink/40 mb-2.5">
            For when
          </p>
          <div className="flex flex-wrap gap-1.5">
            <button
              onClick={() => setActiveContext(null)}
              className={`text-[10px] tracking-wide px-2.5 py-1 rounded-full transition-colors ${
                activeContext === null
                  ? 'bg-ink text-bone'
                  : 'text-ink/55 bg-paper border border-ink/10 hover:border-ink/30'
              }`}
            >
              Any time
            </button>
            {allContexts.map(ctx => (
              <button
                key={ctx}
                onClick={() => setActiveContext(activeContext === ctx ? null : ctx)}
                className={`text-[10px] tracking-wide px-2.5 py-1 rounded-full transition-colors ${
                  activeContext === ctx
                    ? 'bg-sage-600 text-bone'
                    : 'text-ink/55 bg-sage-50/60 border border-sage-200/40 hover:bg-sage-100/60'
                }`}
              >
                {ctx.replace(/_/g, ' ')}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Tag filter (compact, overflow scroll on mobile) */}
      {allTags.length > 0 && (
        <div className="mb-8">
          <p className="text-[10px] tracking-widest uppercase text-ink/40 mb-2.5">
            By theme
          </p>
          <div className="flex flex-wrap gap-1 max-h-24 overflow-y-auto pr-2">
            <button
              onClick={() => setActiveTag(null)}
              className={`text-[10px] tracking-wide px-2 py-0.5 rounded-full transition-colors shrink-0 ${
                activeTag === null
                  ? 'bg-ink text-bone'
                  : 'text-ink/55 bg-ink/5 border border-ink/5 hover:border-ink/20'
              }`}
            >
              all
            </button>
            {allTags.map(tag => (
              <button
                key={tag}
                onClick={() => setActiveTag(activeTag === tag ? null : tag)}
                className={`text-[10px] tracking-wide px-2 py-0.5 rounded-full transition-colors shrink-0 ${
                  activeTag === tag
                    ? 'bg-ink text-bone'
                    : 'text-ink/55 bg-ink/5 border border-ink/5 hover:border-ink/20'
                }`}
              >
                #{tag.replace(/_/g, ' ')}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Results meta + active-filter chips */}
      <div className="mb-6">
        <div className="flex items-center justify-between text-xs text-ink/55 mb-3">
          <p>
            <span className="tabular-nums text-ink/85 font-medium">{filtered.length}</span> of{' '}
            <span className="tabular-nums">{songs.length}</span> {songs.length === 1 ? 'song' : 'songs'}
            {hasFilter && <span className="ml-2 text-ink/40">(filtered)</span>}
          </p>
        </div>
        {/* Active filter summary chips — show what's applied, easy to remove */}
        {hasFilter && (
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-[10px] tracking-widest uppercase text-ink/45">Active:</span>
            {activeEmotion && (
              <button
                onClick={() => setActiveEmotion(null)}
                className="inline-flex items-center gap-1 text-[10px] tracking-wide px-2 py-1 rounded-full bg-amber-100 text-amber-800 hover:bg-amber-200 transition-colors"
              >
                feels: {EMOTION_DESCRIPTIONS[activeEmotion] || activeEmotion} ✕
              </button>
            )}
            {activeContext && (
              <button
                onClick={() => setActiveContext(null)}
                className="inline-flex items-center gap-1 text-[10px] tracking-wide px-2 py-1 rounded-full bg-sage-100 text-sage-800 hover:bg-sage-200 transition-colors"
              >
                when: {activeContext.replace(/_/g, ' ')} ✕
              </button>
            )}
            {activeTag && (
              <button
                onClick={() => setActiveTag(null)}
                className="inline-flex items-center gap-1 text-[10px] tracking-wide px-2 py-1 rounded-full bg-ink/10 text-ink/80 hover:bg-ink/20 transition-colors"
              >
                #{activeTag.replace(/_/g, ' ')} ✕
              </button>
            )}
            {query.trim() && (
              <button
                onClick={() => setQuery('')}
                className="inline-flex items-center gap-1 text-[10px] tracking-wide px-2 py-1 rounded-full bg-ink/10 text-ink/80 hover:bg-ink/20 transition-colors"
              >
                “{query.trim()}” ✕
              </button>
            )}
            <button
              onClick={clearFilters}
              className="ml-1 text-[10px] tracking-wide text-sage-700 hover:text-sage-900 underline underline-offset-4"
            >
              clear all
            </button>
          </div>
        )}
      </div>

      {/* Song list */}
      {filtered.length === 0 ? (
        <div className="card-quiet p-12 text-center">
          <p className="serif italic text-ink/55">
            Nothing here yet for that combination — try clearing a filter, or check back soon as the library grows.
          </p>
        </div>
      ) : (
        <div className="space-y-6">
          {filtered.map(song => (
            <SongCard key={song.id} song={song} />
          ))}
        </div>
      )}
    </div>
  );
}
