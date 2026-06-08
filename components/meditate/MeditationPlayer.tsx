'use client';

import { useState, useRef, useEffect } from 'react';
import { Play, Pause, Volume2, VolumeX } from 'lucide-react';

export function MeditationPlayer({
  title,
  audioUrl,
  duration,
  body,
  prayer,
}: {
  title: string;
  audioUrl?: string;
  duration?: number;
  body: string;
  prayer?: string;
}) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [playing, setPlaying] = useState(false);
  const [muted, setMuted] = useState(false);
  const [progress, setProgress] = useState(0);
  const [actualDuration, setActualDuration] = useState(duration || 0);

  useEffect(() => {
    const a = audioRef.current;
    if (!a) return;
    const onTime = () => setProgress(a.currentTime);
    const onMeta = () => setActualDuration(a.duration);
    const onEnd = () => setPlaying(false);
    a.addEventListener('timeupdate', onTime);
    a.addEventListener('loadedmetadata', onMeta);
    a.addEventListener('ended', onEnd);
    return () => {
      a.removeEventListener('timeupdate', onTime);
      a.removeEventListener('loadedmetadata', onMeta);
      a.removeEventListener('ended', onEnd);
    };
  }, []);

  const toggle = () => {
    const a = audioRef.current;
    if (!a) return;
    if (playing) { a.pause(); setPlaying(false); }
    else { a.play().catch(() => {}); setPlaying(true); }
  };

  const seek = (e: React.MouseEvent<HTMLDivElement>) => {
    const a = audioRef.current;
    if (!a || !actualDuration) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width;
    a.currentTime = x * actualDuration;
    setProgress(a.currentTime);
  };

  const formatTime = (s: number) => {
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60).toString().padStart(2, '0');
    return `${m}:${sec}`;
  };

  return (
    <div className="max-w-2xl mx-auto">
      {/* Player card */}
      <div className="card-quiet p-8 md:p-10">
        <div className="flex items-center gap-6">
          <button
            onClick={toggle}
            className="w-16 h-16 rounded-full bg-ink text-bone flex items-center justify-center hover:scale-105 active:scale-95 transition-transform shrink-0"
            aria-label={playing ? 'Pause' : 'Play'}
          >
            {playing ? <Pause size={22} /> : <Play size={22} className="ml-1" />}
          </button>

          <div className="flex-1 min-w-0">
            <p className="text-xs text-ink/50 mb-2 uppercase tracking-wider">
              {audioUrl ? 'Guided audio' : 'Read at your own pace'}
            </p>
            <p className="serif text-lg truncate">{title}</p>
            {audioUrl && (
              <div className="mt-3 flex items-center gap-3">
                <div
                  className="flex-1 h-1 bg-ink/10 rounded-full cursor-pointer relative"
                  onClick={seek}
                >
                  <div
                    className="absolute inset-y-0 left-0 bg-sage-500 rounded-full transition-all"
                    style={{ width: `${(progress / actualDuration) * 100 || 0}%` }}
                  />
                </div>
                <span className="text-xs text-ink/50 tabular-nums w-20 text-right">
                  {formatTime(progress)} / {formatTime(actualDuration)}
                </span>
                <button
                  onClick={() => { if (audioRef.current) audioRef.current.muted = !audioRef.current.muted; setMuted(m => !m); }}
                  className="text-ink/50 hover:text-ink"
                  aria-label="Toggle mute"
                >
                  {muted ? <VolumeX size={16} /> : <Volume2 size={16} />}
                </button>
              </div>
            )}
          </div>
        </div>

        {audioUrl && <audio ref={audioRef} src={audioUrl} preload="metadata" />}
      </div>

      {/* Body */}
      <section className="prose-quiet mt-12 text-lg">
        {body.split('\n\n').map((p, i) => (
          <p key={i} className={i === 0 ? 'first-letter:text-3xl' : ''}>
            {p}
          </p>
        ))}
      </section>

      {prayer && (
        <section className="mt-12 p-8 bg-sage-50/50 border-l-2 border-sage-400 rounded-r-xl">
          <p className="text-xs tracking-widest uppercase text-sage-700 mb-3">A prayer</p>
          <p className="serif text-xl italic leading-relaxed text-ink/85">{prayer}</p>
        </section>
      )}
    </div>
  );
}
