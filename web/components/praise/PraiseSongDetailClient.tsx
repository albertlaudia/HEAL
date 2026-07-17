// HEAL — Praise song detail client view.
// Renders a single song with its lyrics, scripture refs, reflection,
// and a play button. Also lists 5 more songs in the same category
// (or the full library if no category).

'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Music, Play, Heart, Tag } from 'lucide-react';
import { useAudio } from '@/lib/audio-context';

interface Song {
  id: string;
  title: string;
  subtitle?: string;
  slug: string;
  description?: string;
  lyrics?: string;
  reflection?: string;
  audio_url?: string;
  illustration_url?: string;
  category?: string;
  emotion?: string;
  tempo_bpm?: number;
  meter?: string;
  key_signature?: string;
  scripture_refs?: string[];
  best_for?: string[];
  tags?: string[];
}

export function PraiseSongDetailClient({
  song,
  more,
}: {
  song: Song;
  more: Song[];
}) {
  const audio = useAudio();
  const [faved, setFaved] = useState(false);

  const audioUrl =
    song.audio_url ||
    (song.slug ? `https://resources.positiveness.club/heal/audio/praise/orig-${song.slug}.mp3` : '');

  const onPlay = () => {
    if (!audioUrl) return;
    audio.loadTrack({
      title: song.title,
      audioUrl,
      illustrationUrl: song.illustration_url || '',
    });
    audio.play();
  };

  return (
    <article className="container-quiet py-12 md:py-16">
      <Link
        href="/praise"
        className="inline-flex items-center gap-1.5 text-sm text-ink/50 hover:text-ink/80 mb-10"
      >
        <ArrowLeft size={14} /> All praise
      </Link>

      <header className="mb-10">
        {song.category && (
          <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">
            {song.category}
          </p>
        )}
        <h1 className="serif text-4xl md:text-5xl mb-3 leading-tight">
          {song.title}
        </h1>
        {song.subtitle && (
          <p className="text-lg text-ink/60 italic">{song.subtitle}</p>
        )}

        <div className="mt-6 flex items-center gap-3 flex-wrap">
          {audioUrl && (
            <button onClick={onPlay} className="btn-pill bg-ink text-bone">
              <Play size={14} /> Play
            </button>
          )}
          <button
            onClick={() => setFaved((v) => !v)}
            className="btn-pill"
            aria-label="Favorite"
          >
            <Heart size={14} className={faved ? 'fill-current' : ''} />{' '}
            {faved ? 'Saved' : 'Save'}
          </button>
          {song.scripture_refs && song.scripture_refs.length > 0 && (
            <div className="flex flex-wrap gap-1.5 text-xs">
              {song.scripture_refs.map((r) => (
                <Link
                  key={r}
                  href="/scripture"
                  className="px-2.5 py-1 rounded-full bg-ink/5 text-ink/60 hover:bg-ink/10"
                >
                  {r}
                </Link>
              ))}
            </div>
          )}
        </div>
      </header>

      {song.illustration_url && (
        <div className="mb-10 rounded-2xl overflow-hidden bg-ink/5 aspect-[3/1]">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={song.illustration_url}
            alt=""
            className="w-full h-full object-cover"
          />
        </div>
      )}

      {song.lyrics && (
        <section className="mb-12">
          <h2 className="serif text-2xl mb-4">Lyrics</h2>
          <div className="whitespace-pre-line text-lg leading-relaxed text-ink/85 font-serif">
            {song.lyrics}
          </div>
        </section>
      )}

      {song.reflection && (
        <section className="mb-12 p-8 rounded-2xl bg-sage-50/40 border border-sage-200/30">
          <p className="text-xs tracking-[0.3em] uppercase text-sage-700 mb-3">
            On this song
          </p>
          <p className="text-lg leading-relaxed text-ink/85">{song.reflection}</p>
        </section>
      )}

      {(song.tempo_bpm || song.meter || song.key_signature) && (
        <section className="mb-12 flex flex-wrap gap-x-8 gap-y-2 text-sm text-ink/60">
          {song.tempo_bpm ? <div>♩ {song.tempo_bpm} bpm</div> : null}
          {song.meter ? <div>Meter: {song.meter}</div> : null}
          {song.key_signature ? <div>Key: {song.key_signature}</div> : null}
          {song.emotion ? <div>Mood: {song.emotion}</div> : null}
        </section>
      )}

      {more.length > 0 && (
        <section>
          <h2 className="serif text-2xl mb-6">More like this</h2>
          <div className="grid sm:grid-cols-2 gap-4">
            {more.map((m) => (
              <Link
                key={m.slug}
                href={`/praise/${m.slug}`}
                className="card-quiet p-4 flex items-start gap-4 hover:bg-ink/[0.02]"
              >
                <div className="w-12 h-12 rounded-xl bg-ink/5 flex items-center justify-center flex-shrink-0">
                  <Music size={18} className="text-ink/50" />
                </div>
                <div className="min-w-0">
                  <p className="font-medium truncate">{m.title}</p>
                  {m.subtitle && (
                    <p className="text-sm text-ink/60 truncate">{m.subtitle}</p>
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
