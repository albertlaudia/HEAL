'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { formatDuration, cdnUrl } from '@/lib/utils';
import { ThemeBadge } from '@/components/content/ThemeBadge';
import { Search } from 'lucide-react';

type Meditation = {
  id: string;
  slug: string;
  title: string;
  theme?: string;
  season?: string;
  duration_seconds?: number;
  illustration_url?: string;
  reflection?: string;
};

export function MeditationFilters({
  meditations,
  themes,
  seasons,
}: {
  meditations: Meditation[];
  themes: string[];
  seasons: string[];
}) {
  const [theme, setTheme] = useState<string | null>(null);
  const [season, setSeason] = useState<string | null>(null);
  const [query, setQuery] = useState('');

  const filtered = useMemo(() => {
    return meditations.filter(m => {
      if (theme && m.theme !== theme) return false;
      if (season && m.season !== season) return false;
      if (query && !`${m.title} ${m.reflection || ''}`.toLowerCase().includes(query.toLowerCase())) return false;
      return true;
    });
  }, [meditations, theme, season, query]);

  return (
    <div>
      {/* Search */}
      <div className="relative max-w-md mb-8">
        <Search size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-ink/40" />
        <input
          type="text"
          placeholder="Search meditations…"
          value={query}
          onChange={e => setQuery(e.target.value)}
          className="w-full pl-11 pr-4 py-3 rounded-full bg-paper border border-ink/10 focus:border-sage-400 focus:outline-none text-sm"
        />
      </div>

      {/* Theme filters */}
      <div className="flex flex-wrap gap-2 mb-3">
        <FilterPill active={!theme} onClick={() => setTheme(null)}>All themes</FilterPill>
        {themes.map(t => (
          <FilterPill key={t} active={theme === t} onClick={() => setTheme(theme === t ? null : t)}>
            {t.replace('-', ' ')}
          </FilterPill>
        ))}
      </div>

      {/* Season filters */}
      <div className="flex flex-wrap gap-2 mb-10">
        <FilterPill active={!season} onClick={() => setSeason(null)}>All seasons</FilterPill>
        {seasons.map(s => (
          <FilterPill key={s} active={season === s} onClick={() => setSeason(season === s ? null : s)}>
            {s}
          </FilterPill>
        ))}
      </div>

      <p className="text-sm text-ink/50 mb-4">{filtered.length} meditation{filtered.length === 1 ? '' : 's'}</p>

      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {filtered.map(m => (
          <Link key={m.id} href={`/meditate/${m.slug}`} className="card-quiet group flex flex-col">
            {m.illustration_url ? (
              <div className="relative aspect-[4/3] bg-sage-100 overflow-hidden">
                <Image
                  src={cdnUrl(m.illustration_url) || ''}
                  alt={m.title}
                  fill
                  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                  className="object-cover group-hover:scale-105 transition-transform duration-700"
                />
              </div>
            ) : (
              <div className="aspect-[4/3] bg-gradient-to-br from-sage-100 to-bone" />
            )}
            <div className="p-6 flex-1 flex flex-col">
              <div className="flex items-center gap-2 mb-3">
                <ThemeBadge theme={m.theme} />
                {m.duration_seconds ? <span className="text-xs text-ink/50">· {formatDuration(m.duration_seconds)}</span> : null}
              </div>
              <h3 className="serif text-2xl mb-2 group-hover:text-sage-700 transition-colors">{m.title}</h3>
              {m.reflection && (
                <p className="text-ink/60 text-sm leading-relaxed line-clamp-3">{m.reflection}</p>
              )}
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}

function FilterPill({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={`px-3.5 py-1.5 rounded-full text-sm transition-all duration-300 ${
        active ? 'bg-ink text-bone' : 'bg-paper border border-ink/10 text-ink/70 hover:border-ink/30'
      }`}
    >
      {children}
    </button>
  );
}
