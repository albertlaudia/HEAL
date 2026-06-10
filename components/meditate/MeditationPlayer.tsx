'use client';

import { useEffect } from 'react';
import { Play, Pause, Volume2, VolumeX, Headphones } from 'lucide-react';
import { useAudio } from '@/lib/audio-context';
import { AudioVisualizer } from '@/components/audio/AudioVisualizer';
import { AmbientMixer } from '@/components/audio/AmbientMixer';

function formatTime(s: number) {
  if (!s || isNaN(s)) return '0:00';
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60).toString().padStart(2, '0');
  return `${m}:${sec}`;
}

export function MeditationPlayer({
  title,
  audioUrl,
  fallbackSlug,
  duration,
  body,
  prayer,
  scriptureRef,
  scriptureText,
  reflection,
  illustrationUrl,
}: {
  title: string;
  audioUrl?: string;
  fallbackSlug?: string;
  duration?: number;
  body: string;
  prayer?: string;
  scriptureRef?: string;
  scriptureText?: string;
  reflection?: string;
  illustrationUrl?: string;
}) {
  const { currentTrack, isPlaying, progress, duration: actualDuration, volume, setVolume, loadTrack, toggle, seek } = useAudio();

  // Resolve audio URL: prefer B2 URL, fall back to local /audio/meditations/
  const resolvedAudioUrl = audioUrl
    ? audioUrl
    : fallbackSlug
      ? `/audio/meditations/audio-${fallbackSlug}.mp3`
      : undefined;

  useEffect(() => {
    if (resolvedAudioUrl) {
      loadTrack({
        title,
        audioUrl: resolvedAudioUrl,
        duration: duration,
        illustrationUrl: illustrationUrl,
      });
    }
  }, [resolvedAudioUrl, title, duration, illustrationUrl, loadTrack]);

  const hasAudio = !!resolvedAudioUrl;
  const effectiveDuration = actualDuration || duration || 0;
  const progressPct = effectiveDuration > 0 ? (progress / effectiveDuration) * 100 : 0;
  const playing = hasAudio && isPlaying && currentTrack?.title === title;

  const handleSeek = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!hasAudio || !effectiveDuration) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width;
    seek(Math.max(0, Math.min(1, x)) * effectiveDuration);
  };

  return (
    <div className="relative max-w-2xl mx-auto">
      {/* Hero player */}
      <div className="relative card-quiet p-8 md:p-12 overflow-hidden min-h-[440px] flex flex-col items-center justify-center">
        {/* Audio-reactive background */}
        <AudioVisualizer />

        {/* Soft tone gradient that intensifies when playing */}
        <div
          className={`absolute inset-0 transition-opacity duration-1000 ${
            playing ? 'opacity-100' : 'opacity-40'
          }`}
          style={{
            background: 'radial-gradient(circle at 50% 40%, rgba(210, 200, 175, 0.25) 0%, rgba(255, 250, 240, 0) 60%)',
          }}
        />

        {/* Play button — the breath of the whole experience */}
        <div className="relative">
          {/* Pulse rings while playing */}
          {playing && (
            <>
              <div className="absolute inset-0 -m-8 rounded-full bg-sage-300/20 animate-ping" style={{ animationDuration: '4s' }} />
              <div className="absolute inset-0 -m-4 rounded-full bg-sage-300/15 animate-pulse" style={{ animationDuration: '6s' }} />
            </>
          )}

          <button
            onClick={toggle}
            disabled={!hasAudio}
            className={`relative w-32 h-32 rounded-full flex items-center justify-center transition-all duration-500 group ${
              hasAudio
                ? 'bg-ink text-bone hover:scale-105 active:scale-95 cursor-pointer'
                : 'bg-ink/30 text-bone/60 cursor-not-allowed'
            }`}
            aria-label={playing ? 'Pause' : 'Begin meditation'}
          >
            {/* Circular progress ring */}
            {hasAudio && effectiveDuration > 0 && (
              <svg className="absolute inset-0 -m-1 w-[calc(100%+8px)] h-[calc(100%+8px)] -rotate-90" viewBox="0 0 132 132">
                <circle cx="66" cy="66" r="64" fill="none" stroke="rgba(180, 195, 175, 0.2)" strokeWidth="1.5" />
                <circle
                  cx="66" cy="66" r="64" fill="none"
                  stroke="rgba(180, 195, 175, 0.9)"
                  strokeWidth="2"
                  strokeDasharray={`${(progressPct / 100) * 402.12} 402.12`}
                  strokeLinecap="round"
                  className="transition-all duration-300"
                />
              </svg>
            )}
            {playing ? <Pause size={36} /> : <Play size={36} className="ml-1.5" />}
          </button>
        </div>

        <p className="relative mt-8 text-xs tracking-[0.3em] uppercase text-ink/50">
          {hasAudio
            ? playing
              ? 'Listen. Breathe.'
              : 'Press play to begin'
            : 'Read at your own pace'}
        </p>

        {/* Progress bar (smaller, below) */}
        {hasAudio && effectiveDuration > 0 && (
          <div className="relative w-full max-w-md mt-6">
            <div
              className="h-1 bg-ink/10 rounded-full cursor-pointer"
              onClick={handleSeek}
            >
              <div
                className="h-full bg-gradient-to-r from-sage-400 to-sage-600 rounded-full transition-all"
                style={{ width: `${progressPct}%` }}
              />
            </div>
            <div className="flex justify-between mt-2 text-[11px] text-ink/50 tabular-nums">
              <span>{formatTime(progress)}</span>
              <span>{formatTime(effectiveDuration)}</span>
            </div>
          </div>
        )}

        {/* Volume */}
        {hasAudio && (
          <div className="relative mt-4 flex items-center gap-2">
            <button
              onClick={() => setVolume(volume === 0 ? 0.85 : 0)}
              className="text-ink/50 hover:text-ink"
              aria-label="Toggle volume"
            >
              {volume === 0 ? <VolumeX size={16} /> : <Volume2 size={16} />}
            </button>
            <input
              type="range"
              min="0"
              max="1"
              step="0.05"
              value={volume}
              onChange={e => setVolume(parseFloat(e.target.value))}
              className="w-24 h-0.5 appearance-none bg-ink/10 rounded-full accent-sage-600"
              aria-label="Volume"
            />
          </div>
        )}
      </div>

      {/* Ambient mixer */}
      {hasAudio && (
        <div className="mt-8 card-quiet p-6 md:p-8">
          <AmbientMixer />
        </div>
      )}

      {/* Body — slow reveal */}
      <section className="prose-quiet mt-16 text-lg">
        {body.split('\n\n').map((p, i) => (
          <p key={i} className={`mb-6 ${i === 0 ? 'first-letter:serif first-letter:text-4xl first-letter:font-light first-letter:mr-2 first-letter:float-left first-letter:leading-none' : ''}`}>
            {p}
          </p>
        ))}
      </section>

      {scriptureText && (
        <section className="mt-16 p-8 md:p-12 bg-paper border border-ink/5 rounded-2xl">
          <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">Scripture</p>
          <blockquote className="serif text-2xl leading-relaxed text-ink/85">
            "{scriptureText}"
          </blockquote>
          {scriptureRef && <p className="mt-4 serif italic text-ink/60">— {scriptureRef}</p>}
        </section>
      )}

      {reflection && (
        <section className="mt-12">
          <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">For reflection</p>
          <p className="serif text-xl leading-relaxed text-ink/80 italic">{reflection}</p>
        </section>
      )}

      {prayer && (
        <section className="mt-12 p-8 bg-sage-50/50 border-l-2 border-sage-400 rounded-r-xl">
          <p className="text-xs tracking-widest uppercase text-sage-700 mb-3">A prayer</p>
          <p className="serif text-xl italic leading-relaxed text-ink/85">{prayer}</p>
        </section>
      )}
    </div>
  );
}
