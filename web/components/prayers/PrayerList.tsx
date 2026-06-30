'use client';

import { useState, useMemo } from 'react';

type Prayer = {
  id: string;
  title: string;
  slug: string;
  body: string;
  category?: string;
  attribution?: string;
};

const CATEGORIES = ['morning', 'evening', 'anxiety', 'gratitude', 'forgiveness', 'strength', 'rest', 'other'];

export function PrayerList({ prayers }: { prayers: Prayer[] }) {
  const [category, setCategory] = useState<string | null>(null);

  const filtered = useMemo(() => prayers.filter(p => !category || p.category === category), [prayers, category]);

  return (
    <div>
      <div className="flex flex-wrap gap-2 mb-10">
        <Pill active={!category} onClick={() => setCategory(null)}>All</Pill>
        {CATEGORIES.map(c => (
          <Pill key={c} active={category === c} onClick={() => setCategory(category === c ? null : c)}>
            {c}
          </Pill>
        ))}
      </div>

      <div className="grid md:grid-cols-2 gap-5">
        {filtered.map(p => (
          <article key={p.id} className="card-quiet p-8">
            <p className="text-xs tracking-widest uppercase text-sage-700 mb-3">{p.category || 'prayer'}</p>
            <h3 className="serif text-2xl mb-4">{p.title}</h3>
            <p className="serif text-lg leading-relaxed text-ink/85 whitespace-pre-line">{p.body}</p>
            {p.attribution && (
              <p className="mt-4 text-xs text-ink/50 serif italic">— {p.attribution}</p>
            )}
          </article>
        ))}
      </div>
    </div>
  );
}

function Pill({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={`px-3.5 py-1.5 rounded-full text-sm transition-all ${
        active ? 'bg-ink text-bone' : 'bg-paper border border-ink/10 text-ink/70 hover:border-ink/30'
      }`}
    >
      {children}
    </button>
  );
}
