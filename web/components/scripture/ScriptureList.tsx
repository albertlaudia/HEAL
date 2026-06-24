'use client';

import { useState, useMemo } from 'react';

type Scripture = {
  id: string;
  reference: string;
  text: string;
  translation?: string;
  theme?: string;
  reflection_prompt?: string;
  day_of_year?: number;
};

const THEMES = ['calm', 'gratitude', 'let-go', 'love', 'focus', 'stillness', 'courage', 'rest', 'hope', 'wisdom'];

export function ScriptureList({ scriptures }: { scriptures: Scripture[] }) {
  const [theme, setTheme] = useState<string | null>(null);
  const [open, setOpen] = useState<string | null>(scriptures[0]?.id || null);

  const filtered = useMemo(() => {
    return scriptures.filter(s => !theme || s.theme === theme);
  }, [scriptures, theme]);

  return (
    <div>
      <div className="flex flex-wrap gap-2 mb-10">
        <Pill active={!theme} onClick={() => setTheme(null)}>All</Pill>
        {THEMES.map(t => (
          <Pill key={t} active={theme === t} onClick={() => setTheme(theme === t ? null : t)}>
            {t.replace('-', ' ')}
          </Pill>
        ))}
      </div>

      <div className="space-y-4">
        {filtered.map(s => {
          const isOpen = open === s.id;
          return (
            <div key={s.id} className="card-quiet overflow-hidden">
              <button
                onClick={() => setOpen(isOpen ? null : s.id)}
                className="w-full text-left p-6 md:p-8 flex items-center justify-between gap-4 hover:bg-ink/[0.02] transition-colors"
              >
                <div>
                  <p className="serif italic text-ink/50 text-sm mb-1">{s.reference}</p>
                  <p className="serif text-xl md:text-2xl text-ink/85 line-clamp-2">"{s.text}"</p>
                </div>
                <span className={`text-ink/40 transition-transform text-2xl shrink-0 ${isOpen ? 'rotate-45' : ''}`}>+</span>
              </button>
              {isOpen && (
                <div className="px-6 md:px-8 pb-8 pt-2 border-t border-ink/5">
                  <p className="serif text-2xl leading-relaxed text-ink/90 my-4">"{s.text}"</p>
                  {s.reflection_prompt && (
                    <div className="mt-6 p-5 bg-sage-50/40 rounded-xl">
                      <p className="text-xs tracking-widest uppercase text-sage-700 mb-2">Reflect</p>
                      <p className="serif text-lg italic text-ink/80">{s.reflection_prompt}</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
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
