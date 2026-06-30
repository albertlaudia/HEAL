'use client';

import { useState, useEffect } from 'react';
import { Music, ChevronDown, ChevronUp, Play, Pause, Headphones, Clock } from 'lucide-react';
import { useAudio } from '@/lib/audio-context';
import { AudioPreparing } from '@/components/audio/AudioPreparing';
import { cdnUrl } from '@/lib/utils';
import type { HEALPraise } from '@/lib/pb';

function formatTime(s: number) {
  if (!s || isNaN(s)) return '0:00';
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60).toString().padStart(2, '0');
  return `${m}:${sec}`;
}

const EMOTION_COLORS: Record<string, { bg: string; text: string; ring: string }> = {
  companioned:  { bg: 'bg-amber-50/60',   text: 'text-amber-800',   ring: 'ring-amber-200/60' },
  settled:      { bg: 'bg-sage-50/60',    text: 'text-sage-800',    ring: 'ring-sage-200/60' },
  lifted:       { bg: 'bg-cyan-50/60',    text: 'text-cyan-800',    ring: 'ring-cyan-200/60' },
  restored:     { bg: 'bg-indigo-50/60',  text: 'text-indigo-800',  ring: 'ring-indigo-200/60' },
  awestruck:    { bg: 'bg-purple-50/60',  text: 'text-purple-800',  ring: 'ring-purple-200/60' },
  honest:       { bg: 'bg-rose-50/60',    text: 'text-rose-800',    ring: 'ring-rose-200/60' },
  reverent:     { bg: 'bg-stone-100/60',  text: 'text-stone-800',   ring: 'ring-stone-200/60' },
};

const CATEGORY_COLORS: Record<string, string> = {
  comfort:    'bg-sage-100 text-sage-800',
  gratitude:  'bg-amber-100 text-amber-800',
  hope:       'bg-cyan-100 text-cyan-800',
  adoration:  'bg-indigo-100 text-indigo-800',
  celebration:'bg-rose-100 text-rose-800',
  lament:     'bg-stone-200 text-stone-800',
};

export function SongCard({ song }: { song: HEALPraise }) {
  const [open, setOpen] = useState(false);
  const [audioError, setAudioError] = useState<string | null>(null);
  const { currentTrack, isPlaying, progress, duration, audioLoading, audioLoadProgress, loadTrack, toggle } = useAudio();

  // Build audio URL: prefer PB url, else fallback to local /audio/praise/song-{slug}.mp3
  // Always wrap through cdnUrl() so the resolution points to the CDN, not local /public.
  const audioUrl = cdnUrl(song.audio_url || (song.slug ? `/audio/praise/song-${song.slug}.mp3` : undefined));

  // Load this song into the audio context if it has audio
  useEffect(() => {
    if (audioUrl) {
      loadTrack({
        title: song.title,
        audioUrl,
        illustrationUrl: cdnUrl(song.illustration_url || `/images/praises/${song.slug}.png`),
      });
      setAudioError(null);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [song.id, audioUrl]);

  const isThisSong = currentTrack?.title === song.title && isPlaying;
  const isThisLoaded = currentTrack?.title === song.title;
  const isThisLoading = isThisLoaded && audioLoading;
  const progressPct = isThisLoaded && duration > 0 ? (progress / duration) * 100 : 0;
  const canPlay = !!audioUrl;

  const handlePlay = () => {
    if (!audioUrl) {
      setAudioError('Audio file not yet uploaded.');
      return;
    }
    setAudioError(null);
    if (!isThisLoaded) {
      loadTrack({ title: song.title, audioUrl });
      setTimeout(() => toggle(), 60);
    } else {
      toggle();
    }
  };

  const emotionColors = song.emotion ? EMOTION_COLORS[song.emotion] || EMOTION_COLORS.companioned : EMOTION_COLORS.companioned;
  const categoryColors = song.category ? CATEGORY_COLORS[song.category] || 'bg-paper text-ink/60' : 'bg-paper text-ink/60';

  return (
    <article
      id={`song-${song.slug}`}
      className={`card-quiet overflow-hidden group relative scroll-mt-24 transition-all duration-500 ${
        isThisSong ? 'ring-2 ring-sage-400 shadow-lg' : ''
      }`}
    >
      {/* Hero band with title + emotion badge */}
      <div className={`relative px-6 md:px-8 pt-6 md:pt-8 pb-5 border-b border-ink/5 ${emotionColors.bg}`}>
        {/* Now-playing ribbon */}
        {isThisSong && (
          <div className="absolute top-3 right-3 inline-flex items-center gap-1.5 text-[10px] tracking-widest uppercase text-sage-700 bg-paper px-2 py-1 rounded-full shadow-sm">
            <span className="flex items-center gap-0.5">
              <span className="w-0.5 h-2.5 bg-sage-600 rounded-full animate-pulse" style={{ animationDelay: '0ms' }} />
              <span className="w-0.5 h-2.5 bg-sage-600 rounded-full animate-pulse" style={{ animationDelay: '150ms' }} />
              <span className="w-0.5 h-2.5 bg-sage-600 rounded-full animate-pulse" style={{ animationDelay: '300ms' }} />
            </span>
            Playing
          </div>
        )}

        <div className="flex items-start gap-4">
          <div className="flex-1 min-w-0">
            {/* Top row: badges */}
            <div className="flex flex-wrap items-center gap-1.5 mb-2.5">
              {song.category && (
                <span className={`text-[10px] tracking-widest uppercase px-2 py-0.5 rounded-full ${categoryColors}`}>
                  {song.category}
                </span>
              )}
              {song.emotion && (
                <span className={`text-[10px] tracking-widest uppercase px-2 py-0.5 rounded-full ${emotionColors.bg} ${emotionColors.text} ring-1 ring-inset ${emotionColors.ring}`}>
                  {song.emotion}
                </span>
              )}
              {song.mood && !song.emotion && (
                <span className="text-[10px] tracking-widest uppercase text-ink/45 bg-paper/70 px-2 py-0.5 rounded-full">
                  {song.mood}
                </span>
              )}
              {(song.key_signature || song.tempo_bpm || song.meter) && (
                <span className="text-[10px] tracking-widest uppercase text-ink/40 hidden sm:inline">
                  · {[song.key_signature, song.tempo_bpm && `${song.tempo_bpm}bpm`, song.meter].filter(Boolean).join(' · ')}
                </span>
              )}
            </div>
            <h3 className="serif text-2xl md:text-3xl mb-1.5 leading-tight">{song.title}</h3>
            {song.subtitle && (
              <p className="serif italic text-ink/55 text-sm">{song.subtitle}</p>
            )}
          </div>

          {canPlay && (
            <button
              onClick={handlePlay}
              className={`shrink-0 w-14 h-14 md:w-16 md:h-16 rounded-full flex items-center justify-center transition-all duration-500 ${
                isThisSong
                  ? 'bg-ink text-bone scale-105 shadow-lg'
                  : 'border border-ink/20 text-ink/75 hover:border-ink/50 hover:text-ink hover:scale-105 bg-bone/70'
              }`}
              aria-label={isThisSong ? `Pause ${song.title}` : `Play ${song.title}`}
              title={isThisSong ? 'Pause' : 'Play song'}
            >
              {isThisSong ? <Pause size={20} /> : <Play size={20} className="ml-0.5" />}
            </button>
          )}
        </div>
      </div>

      {/* Description block */}
      {song.description && (
        <div className="px-6 md:px-8 pt-5 pb-2">
          <p className="serif text-base md:text-lg leading-relaxed text-ink/75">
            {song.description}
          </p>
        </div>
      )}

      {/* Best-for chips (right after description — more prominent than tags) */}
      {song.best_for && song.best_for.length > 0 && (
        <div className="px-6 md:px-8 pt-3 flex flex-wrap items-center gap-1.5">
          <span className="text-[10px] tracking-widest uppercase text-ink/40 mr-1">Best for</span>
          {song.best_for.slice(0, 4).map(ctx => (
            <span
              key={ctx}
              className="text-[10px] text-sage-700 bg-sage-50/80 px-2 py-0.5 rounded-full border border-sage-200/40"
            >
              {ctx.replace(/_/g, ' ')}
            </span>
          ))}
        </div>
      )}

      {/* Tags row (secondary, smaller) */}
      {song.tags && song.tags.length > 0 && (
        <div className="px-6 md:px-8 pt-2 pb-3 flex flex-wrap items-center gap-1.5">
          {song.tags.slice(0, 6).map(tag => (
            <span
              key={tag}
              className="text-[10px] tracking-wide text-ink/50 bg-ink/5 px-1.5 py-0.5 rounded-full"
            >
              #{tag.replace(/_/g, ' ')}
            </span>
          ))}
          {song.tags.length > 6 && (
            <span className="text-[10px] text-ink/35">+{song.tags.length - 6}</span>
          )}
        </div>
      )}

      {/* Progress + audio state — visible bar */}
      {isThisLoaded && canPlay && (
        <div className="px-6 md:px-8 pb-4">
          <div className="h-1.5 bg-ink/8 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-sage-400 to-sage-600 transition-all duration-300"
              style={{ width: `${progressPct}%` }}
            />
          </div>
        </div>
      )}

      {isThisLoading && !isPlaying && (
        <div className="px-6 md:px-8 pb-3">
          <AudioPreparing progress={audioLoadProgress} visible kind="praise" />
        </div>
      )}

      {/* Voice info + duration */}
      {isThisLoaded && canPlay && duration > 0 && (
        <div className="px-6 md:px-8 pb-3 flex items-center gap-3 text-[10px] tracking-widest uppercase text-ink/40">
          {song.voice && (
            <span className="flex items-center gap-1">
              <Headphones size={10} /> Voice: {song.voice}
            </span>
          )}
          <span className="flex items-center gap-1">
            <Clock size={10} /> {formatTime(duration)}
          </span>
        </div>
      )}

      {/* Audio error */}
      {audioError && (
        <div className="px-6 md:px-8 pb-3 text-xs text-rose-700 bg-rose-50/60 border-l-2 border-rose-400 mx-6 md:mx-8 px-3 py-2 rounded-r">
          {audioError}
        </div>
      )}

      {/* Lyrics */}
      {song.lyrics && (
        <div className="px-6 md:px-8 pt-2 pb-4">
          <pre className="serif text-[15px] leading-relaxed whitespace-pre-wrap font-sans text-ink/75 bg-ink/[0.02] -mx-2 px-4 py-4 rounded-xl my-2">
{song.lyrics}
          </pre>
        </div>
      )}

      {/* Scripture refs */}
      {song.scripture_refs && song.scripture_refs.length > 0 && (
        <div className="px-6 md:px-8 pb-4">
          <p className="text-xs text-sage-700 tracking-wide">
            ✦ {song.scripture_refs.join(' · ')}
          </p>
        </div>
      )}

      {/* Expand chords + reflection */}
      {(song.chords || song.reflection) && (
        <>
          <button
            onClick={() => setOpen(o => !o)}
            className="mx-6 md:mx-8 mb-4 inline-flex items-center gap-1 text-sm text-ink/55 hover:text-ink transition-colors"
          >
            {open ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            {open ? 'Hide' : 'Show'} chords & reflection
          </button>
        </>
      )}

      {open && (
        <div className="px-6 md:px-8 pb-6 space-y-6 border-t border-ink/5 pt-4 mx-6 md:mx-8">
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
