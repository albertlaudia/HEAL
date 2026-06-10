'use client';

import { useAudio, AMBIENT_LABELS, type AmbientTrack } from '@/lib/audio-context';
import { CloudRain, Waves, Trees, AudioLines, Piano, Sparkles, Flame, Droplets, Wind, Home } from 'lucide-react';

const AMBIENT_ICONS: Record<AmbientTrack, React.ComponentType<{ size?: number; className?: string }>> = {
  rain: CloudRain,
  ocean: Waves,
  forest: Trees,
  drone: AudioLines,
  piano: Piano,
  whitenoise: Sparkles,
  fire: Flame,
  river: Droplets,
  wind: Wind,
  room: Home,
};

const AMBIENT_GRADIENTS: Record<AmbientTrack, string> = {
  rain: 'from-slate-300/40 to-slate-200/20',
  ocean: 'from-cyan-300/40 to-blue-200/20',
  forest: 'from-emerald-300/40 to-green-200/20',
  drone: 'from-purple-300/40 to-violet-200/20',
  piano: 'from-amber-300/40 to-yellow-200/20',
  whitenoise: 'from-gray-300/40 to-stone-200/20',
  fire: 'from-orange-300/40 to-red-200/20',
  river: 'from-teal-300/40 to-cyan-200/20',
  wind: 'from-sky-300/40 to-indigo-200/20',
  room: 'from-stone-300/40 to-neutral-200/20',
};

export function AmbientMixer() {
  const { ambient, toggleAmbient, setAmbientVolume, roomToneVolume, setRoomToneVolume } = useAudio();

  const anyActive = (Object.keys(AMBIENT_LABELS) as AmbientTrack[]).some(t => ambient[t].active);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-xs tracking-widest uppercase text-ink/40">Ambient background</p>
        {anyActive && (
          <span className="text-[10px] text-sage-700 uppercase tracking-wider">{anyActive ? 'Mixing' : ''}</span>
        )}
      </div>
      <div className="grid grid-cols-5 gap-2">
        {(Object.keys(AMBIENT_LABELS) as AmbientTrack[]).map(track => {
          const Icon = AMBIENT_ICONS[track];
          const isActive = ambient[track].active;
          const vol = ambient[track].volume;
          return (
            <button
              key={track}
              onClick={() => toggleAmbient(track)}
              className={`group relative flex flex-col items-center gap-1.5 p-2.5 rounded-2xl border transition-all duration-500 ${
                isActive
                  ? 'border-sage-400 bg-sage-50/60 scale-[1.03]'
                  : 'border-ink/10 bg-paper hover:border-ink/20'
              }`}
              aria-label={`Toggle ${AMBIENT_LABELS[track]}`}
            >
              <div className={`absolute inset-0 rounded-2xl bg-gradient-to-br ${AMBIENT_GRADIENTS[track]} transition-opacity duration-700 ${isActive ? 'opacity-100' : 'opacity-0'}`} />
              <div className="relative flex flex-col items-center gap-1.5">
                <Icon size={18} className={isActive ? 'text-sage-700' : 'text-ink/50'} />
                <span className={`text-[9px] tracking-wider uppercase ${isActive ? 'text-ink' : 'text-ink/50'}`}>
                  {AMBIENT_LABELS[track]}
                </span>
              </div>
              {isActive && (
                <div className="relative w-full px-1" onClick={e => e.stopPropagation()}>
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.05"
                    value={vol}
                    onChange={e => setAmbientVolume(track, parseFloat(e.target.value))}
                    className="w-full h-0.5 appearance-none bg-sage-200 rounded-full accent-sage-600"
                    aria-label={`${AMBIENT_LABELS[track]} volume`}
                  />
                </div>
              )}
            </button>
          );
        })}
      </div>
      <div className="flex items-center gap-3 pt-2 border-t border-ink/5">
        <p className="text-[10px] uppercase tracking-wider text-ink/50 shrink-0">Room tone</p>
        <input
          type="range"
          min="0"
          max="0.4"
          step="0.02"
          value={roomToneVolume}
          onChange={e => setRoomToneVolume(parseFloat(e.target.value))}
          className="flex-1 h-0.5 appearance-none bg-ink/10 rounded-full accent-sage-600"
          aria-label="Room tone volume"
        />
        <span className="text-[10px] text-ink/40 tabular-nums w-8">{Math.round(roomToneVolume * 100)}%</span>
      </div>
      <p className="text-xs text-ink/40 italic">Tap to layer under the voice. Room tone adds gentle texture to the silence.</p>
    </div>
  );
}
