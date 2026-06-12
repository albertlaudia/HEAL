'use client';

import { useState, useEffect } from 'react';
import { Music, ChevronDown, ChevronUp, Play, Pause } from 'lucide-react';
import { useAudio } from '@/lib/audio-context';

function formatTime(s: number) {
  if (!s || isNaN(s)) return '0:00';
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60).toString().padStart(2, '0');
  return `${m}:${sec}`;
}

export function SongCard({ song }: { song: any }) {
  const [open, setOpen] = useState(false);
  const { currentTrack, isPlaying, progress, duration, loadTrack, toggle } = useAudio();

  // Build audio URL: prefer B2 if set, else fallback to local /audio/praise/<filename>.mp3
  const audioUrl = song.audio_url
    || (song.slug ? `/audio/praise/${song.slug}.mp3` : undefined);

  // Load this song into the audio context if it has audio
  useEffect(() => {
    if (audioUrl) {
      loadTrack({
        title: song.title,
        audioUrl,
        illustrationUrl: song.illustration_url || `/images/praises/${song.slug}.png`,
      });
    }
    // Only run when the song id changes
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [song.id, audioUrl]);

  // Is THIS song the one currently loaded AND playing?
  const isThisSong = currentTrack?.title === song.title && isPlaying;
  const isThisLoaded = currentTrack?.title === song.title;
  const progressPct = isThisLoaded && duration > 0 ? (progress / duration) * 100 : 0;

  const handlePlay = () => {
    if (!audioUrl) return;
    if (!isThisLoaded) {
      loadTrack({ title: song.title, audioUrl });
      // The toggle() won't autoplay a freshly-loaded track in some browsers,
      // so we explicitly call play() after a microtask
      setTimeout(() => toggle(), 60);
    } else {
      toggle();
    }
  };

  const canPlay = !!audioUrl;

  return (
    <article className="card-quiet p-8 md:p-10 group relative">
      <div className="flex items-start gap-4 mb-4">
        <div className={`w-12 h-12 rounded-full flex items-center justify-center shrink-0 transition-colors ${
          isThisSong ? 'bg-sage-300 text-bone scale-110' : 'bg-sage-100 text-sage-700 group-hover:bg-sage-200'
        }`}>
          {isThisSong ? (
            <span className="flex items-center gap-0.5">
              <span className="w-0.5 h-3 bg-bone rounded-full animate-pulse" style={{ animationDelay: '0ms' }} />
              <span className="w-0.5 h-3 bg-bone rounded-full animate-pulse" style={{ animationDelay: '150ms' }} />
              <span className="w-0.5 h-3 bg-bone rounded-full animate-pulse" style={{ animationDelay: '300ms' }} />
            </span>
          ) : (
            <Music size={20} className="text-sage-700" />
          )}
        </div>
        <div className="flex-1">
          <div className="flex flex-wrap items-center gap-2 text-xs text-ink/40 tracking-wider uppercase mb-2">
            {song.category && <span>{song.category}</span>}
            {song.key_signature && <span>· Key {song.key_signature}</span>}
            {song.tempo_bpm && <span>· {song.tempo_bpm} bpm</span>}
            {song.meter && <span>· {song.meter}</span>}
            {canPlay && <span className="text-sage-700">· instrumental ready</span>}
          </div>
          <h3 className="serif text-2xl md:text-3xl mb-1">{song.title}</h3>
          {song.subtitle && (
            <p className="serif italic text-ink/60 text-sm">{song.subtitle}</p>
          )}
        </div>

        {canPlay && (
          <button
            onClick={handlePlay}
            className={`shrink-0 w-12 h-12 rounded-full flex items-center justify-center transition-all duration-500 ${
              isThisSong
                ? 'bg-ink text-bone scale-105'
                : 'border border-ink/15 text-ink/70 hover:border-ink/40 hover:text-ink hover:scale-105'
            }`}
            aria-label={isThisSong ? 'Pause' : `Play ${song.title}`}
            title={isThisSong ? 'Pause instrumental' : 'Play instrumental'}
          >
            {isThisSong ? <Pause size={16} /> : <Play size={16} className="ml-0.5" />}
          </button>
        )}
      </div>

      {song.scripture_refs && song.scripture_refs.length > 0 && (
        <p className="text-xs text-sage-700 mb-4 tracking-wide">
          ✦ {song.scripture_refs.join(' · ')}
        </p>
      )}

      {/* Progress bar (visible only when this song is playing) */}
      {isThisLoaded && (
        <div className="mb-4 -mx-1">
          <div className="h-0.5 bg-ink/8 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-sage-400 to-sage-600 transition-all duration-300"
              style={{ width: `${progressPct}%` }}
            />
          </div>
        </div>
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
