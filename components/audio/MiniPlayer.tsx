'use client';

import Link from 'next/link';
import { Play, Pause, X, Volume2, Volume1, VolumeX, VolumeOff } from 'lucide-react';
import { useAudio } from '@/lib/audio-context';
import { usePathname } from 'next/navigation';

function formatTime(s: number) {
  if (!s) return '0:00';
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60).toString().padStart(2, '0');
  return `${m}:${sec}`;
}

export function MiniPlayer() {
  const {
    currentTrack, isPlaying, progress, duration,
    toggle, stopAll, voiceVolume, setVoiceVolume,
    masterVolume, setMasterVolume, muted, toggleMute,
    effectiveAmbientGain, effectiveRoomToneGain,
  } = useAudio();
  const pathname = usePathname();

  // Hide mini player on the meditation page itself (where the full player is)
  if (!currentTrack) return null;
  if (pathname?.startsWith('/meditate/') && pathname !== '/meditate') return null;

  const VolIcon = muted ? VolumeOff : voiceVolume === 0 ? VolumeX : voiceVolume < 0.5 ? Volume1 : Volume2;
  const progressPct = duration > 0 ? (progress / duration) * 100 : 0;

  return (
    <div
      className="fixed bottom-4 left-1/2 -translate-x-1/2 z-50 w-[min(720px,calc(100vw-2rem))] animate-fade-in"
      role="region"
      aria-label="Mini audio player"
    >
      <div className="relative card-quiet p-4 backdrop-blur-md bg-bone/90 shadow-2xl">
        {/* Progress line at the top */}
        <div className="absolute top-0 left-0 right-0 h-0.5 bg-ink/5 rounded-t-2xl overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-sage-400 to-sage-600 transition-all duration-300"
            style={{ width: `${progressPct}%` }}
          />
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={toggle}
            className="w-10 h-10 rounded-full bg-ink text-bone flex items-center justify-center hover:scale-105 active:scale-95 transition-transform shrink-0"
            aria-label={isPlaying ? 'Pause' : 'Play'}
          >
            {isPlaying ? <Pause size={16} /> : <Play size={16} className="ml-0.5" />}
          </button>

          <div className="flex-1 min-w-0">
            <Link href="/meditate" className="block">
              <p className="text-[10px] tracking-widest uppercase text-ink/40 truncate">Now playing</p>
              <p className="serif text-sm truncate">{currentTrack.title}</p>
            </Link>
          </div>

          <span className="text-[11px] text-ink/50 tabular-nums shrink-0">
            {formatTime(progress)} / {formatTime(duration)}
          </span>

          {/* Voice volume slider */}
          <div className="hidden sm:flex items-center gap-2 shrink-0">
            <button
              onClick={() => setVoiceVolume(voiceVolume === 0 ? 0.9 : 0)}
              className="text-ink/50 hover:text-ink transition-colors"
              aria-label="Toggle voice"
              title={`Voice: ${Math.round(voiceVolume * 100)}%`}
            >
              <VolIcon size={16} />
            </button>
            <input
              type="range"
              min="0"
              max="1"
              step="0.05"
              value={voiceVolume}
              onChange={e => setVoiceVolume(parseFloat(e.target.value))}
              className="w-20 h-0.5 appearance-none bg-ink/10 rounded-full accent-sage-600"
              aria-label="Voice volume"
              title={`Voice: ${Math.round(voiceVolume * 100)}%`}
            />
          </div>

          {/* Master volume slider (controls everything) */}
          <div className="hidden md:flex items-center gap-2 shrink-0">
            <span className="text-[9px] text-ink/40 uppercase tracking-wider">Master</span>
            <input
              type="range"
              min="0"
              max="1"
              step="0.05"
              value={masterVolume}
              onChange={e => setMasterVolume(parseFloat(e.target.value))}
              className="w-20 h-0.5 appearance-none bg-ink/10 rounded-full accent-sage-600"
              aria-label="Master volume"
              title={`Master: ${Math.round(masterVolume * 100)}%`}
            />
          </div>

          {/* Mute */}
          <button
            onClick={toggleMute}
            className="text-ink/50 hover:text-ink transition-colors shrink-0"
            aria-label={muted ? 'Unmute' : 'Mute'}
            title={muted ? 'Click to unmute' : 'Click to mute'}
          >
            {muted ? <VolumeX size={16} /> : <span className="text-[10px] tabular-nums">{Math.round(masterVolume * 100)}</span>}
          </button>

          <button
            onClick={stopAll}
            className="text-ink/40 hover:text-ink transition-colors shrink-0"
            aria-label="Close player"
          >
            <X size={16} />
          </button>
        </div>

        {/* Active ambient indicators (tiny chips) */}
        {(effectiveAmbientGain > 0.01 || effectiveRoomToneGain > 0.01) && (
          <div className="mt-2 pt-2 border-t border-ink/5 flex items-center gap-2 text-[10px] text-ink/50">
            <span className="uppercase tracking-wider">Mixing:</span>
            {effectiveRoomToneGain > 0.01 && <span className="px-1.5 py-0.5 rounded bg-sage-50 text-sage-700">Room · {Math.round(effectiveRoomToneGain * 100)}%</span>}
            {effectiveAmbientGain > 0.01 && <span className="px-1.5 py-0.5 rounded bg-sage-50 text-sage-700">Ambient · {Math.round(effectiveAmbientGain * 100)}%</span>}
          </div>
        )}
      </div>
    </div>
  );
}
