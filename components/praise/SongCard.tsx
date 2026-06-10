'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Music, ChevronDown, ChevronUp } from 'lucide-react';

export function SongCard({ song }: { song: any }) {
  const [open, setOpen] = useState(false);

  return (
    <article className="card-quiet p-8 md:p-10 group">
      <div className="flex items-start gap-4 mb-4">
        <div className="w-12 h-12 rounded-full bg-sage-100 flex items-center justify-center shrink-0 group-hover:bg-sage-200 transition-colors">
          <Music size={20} className="text-sage-700" />
        </div>
        <div className="flex-1">
          <div className="flex flex-wrap items-center gap-2 text-xs text-ink/40 tracking-wider uppercase mb-2">
            {song.category && <span>{song.category}</span>}
            {song.key_signature && <span>· Key {song.key_signature}</span>}
            {song.tempo_bpm && <span>· {song.tempo_bpm} bpm</span>}
            {song.meter && <span>· {song.meter}</span>}
          </div>
          <h3 className="serif text-2xl md:text-3xl mb-1">{song.title}</h3>
          {song.subtitle && (
            <p className="serif italic text-ink/60 text-sm">{song.subtitle}</p>
          )}
        </div>
      </div>

      {song.scripture_refs && song.scripture_refs.length > 0 && (
        <p className="text-xs text-sage-700 mb-4 tracking-wide">
          ✦ {song.scripture_refs.join(' · ')}
        </p>
      )}

      <div className="prose prose-sm max-w-none">
        <pre className="serif text-ink/80 leading-relaxed whitespace-pre-wrap font-sans text-[15px] bg-sage-50/30 -mx-2 px-4 py-4 rounded-xl my-4">
{song.lyrics}
        </pre>
      </div>

      {(song.chords || song.reflection) && (
        <button
          onClick={() => setOpen(o => !o)}
          className="mt-4 inline-flex items-center gap-1 text-sm text-ink/60 hover:text-ink transition-colors"
        >
          {open ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
          {open ? 'Hide' : 'Show'} chords & reflection
        </button>
      )}

      {open && (
        <div className="mt-6 space-y-6 border-t border-ink/10 pt-6">
          {song.chords && (
            <div>
              <p className="text-xs tracking-widest uppercase text-ink/40 mb-2">Chords</p>
              <pre className="text-sm text-ink/70 leading-relaxed whitespace-pre-wrap font-mono bg-bone p-4 rounded-xl">
{song.chords}
              </pre>
            </div>
          )}
          {song.reflection && (
            <div>
              <p className="text-xs tracking-widest uppercase text-ink/40 mb-2">Reflection</p>
              <p className="serif italic text-ink/75 leading-relaxed">{song.reflection}</p>
            </div>
          )}
        </div>
      )}
    </article>
  );
}
