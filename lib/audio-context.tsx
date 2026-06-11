'use client';

import { createContext, useContext, useState, useRef, useEffect, useCallback, ReactNode } from 'react';

export type AmbientTrack = 'rain' | 'ocean' | 'forest' | 'drone' | 'piano' | 'whitenoise' | 'fire' | 'river' | 'wind' | 'room';

type AudioState = {
  // Voice / meditation audio
  currentTrack: { title: string; audioUrl: string; duration?: number; illustrationUrl?: string } | null;
  isPlaying: boolean;
  progress: number;
  duration: number;
  voiceVolume: number;        // 0..1 — separate from ambient
  setVoiceVolume: (v: number) => void;

  // Master output gain (safety limiter)
  masterGain: number;
  setMasterGain: (v: number) => void;

  loadTrack: (t: { title: string; audioUrl: string; duration?: number; illustrationUrl?: string }) => void;
  play: () => void;
  pause: () => void;
  toggle: () => void;
  seek: (time: number) => void;

  // Ambient mixer — user-controlled slider values
  ambient: Record<AmbientTrack, { active: boolean; slider: number }>;
  toggleAmbient: (track: AmbientTrack) => void;
  setAmbientSlider: (track: AmbientTrack, vol: number) => void;
  stopAll: () => void;

  // Room tone — always plays under voice for intimacy
  roomToneVolume: number;    // slider 0..1
  setRoomToneVolume: (v: number) => void;

  // Ducking: when voice plays, ambient is reduced to this fraction
  duckRatio: number;          // 0..1 — typically 0.35
  setDuckRatio: (v: number) => void;
};

const AudioContext = createContext<AudioState | null>(null);

const AMBIENT_URLS: Record<AmbientTrack, string> = {
  rain: '/audio/ambient-rain.mp3',
  ocean: '/audio/ambient-ocean.mp3',
  forest: '/audio/ambient-forest.mp3',
  drone: '/audio/ambient-drone.mp3',
  piano: '/audio/ambient-piano.mp3',
  whitenoise: '/audio/ambient-whitenoise.mp3',
  fire: '/audio/ambient-fire.mp3',
  river: '/audio/ambient-river.mp3',
  wind: '/audio/ambient-wind.mp3',
  room: '/audio/ambient-room.mp3',
};

const AMBIENT_LABELS: Record<AmbientTrack, string> = {
  rain: 'Rain',
  ocean: 'Ocean',
  forest: 'Forest',
  drone: 'Drone',
  piano: 'Piano',
  whitenoise: 'White',
  fire: 'Fire',
  river: 'River',
  wind: 'Wind',
  room: 'Room',
};

// ─────────────────────────────────────────────────────────────────────
// Audio mixing rules (the heart of why voice now stays clear)
// ─────────────────────────────────────────────────────────────────────
//   • Voice is the lead. It always plays at voiceVolume (0.85 default).
//   • Room tone is a quiet floor under the voice (0.06 default, hard cap 0.12).
//   • Each ambient track has a slider 0..1, but the *applied* gain is:
//         applied = slider * perTrackCap * (isPlaying ? duckRatio : 1)
//   • perTrackCap = 0.25 (max one track can contribute) — strict
//   • duckRatio = 0.20 (when voice is playing, ambient drops to 20% of slider)
//   • Effective mix headroom when voice + 1 ambient at slider 0.5:
//         voice 0.85 + roomTone 0.06 + ambient 0.5 * 0.25 * 0.20 = 0.885 → safe
//   • If multiple ambient tracks are active, they *share* the headroom so
//     the total ambient sum is capped (no additive clipping).
// ─────────────────────────────────────────────────────────────────────

const PER_TRACK_CAP = 0.5;          // max slider contribution to a single track
const ROOM_TONE_MAX = 0.12;          // hard ceiling for the always-on room tone
const AMBIENT_TOTAL_HEADROOM = 0.40; // total sum of active ambient when voice is playing
const AMBIENT_TOTAL_HEADROOM_NOVOICE = 0.85; // when no voice, ambient can be louder

// Smooth log-scale fade — used for all gain transitions
function fadeGain(audio: HTMLAudioElement, target: number, durationMs = 600) {
  const start = audio.volume;
  const steps = Math.max(8, Math.floor(durationMs / 30));
  const delta = (target - start) / steps;
  let i = 0;
  const tick = () => {
    i++;
    if (i >= steps) {
      audio.volume = target;
      return;
    }
    audio.volume = Math.max(0, Math.min(1, start + delta * i));
    requestAnimationFrame(tick);
  };
  // Cancel any prior in-flight fades by jumping to start
  audio.volume = start;
  requestAnimationFrame(tick);
}

export function AudioProvider({ children }: { children: ReactNode }) {
  const [currentTrack, setCurrentTrack] = useState<AudioState['currentTrack']>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);

  // Master volumes
  const [voiceVolume, setVoiceVolume] = useState(0.9);
  const [masterGain, setMasterGain] = useState(0.9);
  const [roomToneVolume, setRoomToneVolume] = useState(0.06);
  const [duckRatio, setDuckRatio] = useState(0.30);

  // Per-track slider 0..1. Defaults are LOWER now (0.3-0.4) so first-use isn't loud.
  // Most users want ambient as a subtle bed, not a wall of sound.
  const [ambient, setAmbient] = useState<Record<AmbientTrack, { active: boolean; slider: number }>>({
    rain: { active: false, slider: 0.35 },
    ocean: { active: false, slider: 0.35 },
    forest: { active: false, slider: 0.35 },
    drone: { active: false, slider: 0.35 },
    piano: { active: false, slider: 0.3 },
    whitenoise: { active: false, slider: 0.25 },
    fire: { active: false, slider: 0.35 },
    river: { active: false, slider: 0.35 },
    wind: { active: false, slider: 0.35 },
    room: { active: false, slider: 0.3 },
  });

  // Refs to live HTMLAudioElement instances (we never re-render audio elements)
  const voiceRef = useRef<HTMLAudioElement | null>(null);
  const roomToneRef = useRef<HTMLAudioElement | null>(null);
  const ambientRefs = useRef<Record<AmbientTrack, HTMLAudioElement | null>>({
    rain: null, ocean: null, forest: null, drone: null, piano: null,
    whitenoise: null, fire: null, river: null, wind: null, room: null,
  });

  // ── Voice audio element ────────────────────────────────────────────
  useEffect(() => {
    const a = new Audio();
    a.preload = 'metadata';
    a.loop = false;
    a.addEventListener('timeupdate', () => setProgress(a.currentTime));
    a.addEventListener('loadedmetadata', () => setDuration(a.duration || 0));
    a.addEventListener('ended', () => {
      setIsPlaying(false);
      setProgress(0);
    });
    a.addEventListener('error', () => {
      console.warn('voice audio error', a.src);
      setIsPlaying(false);
    });
    voiceRef.current = a;
    return () => {
      a.pause();
      a.src = '';
    };
  }, []);

  // ── Ambient + room tone audio elements (created once) ──────────────
  useEffect(() => {
    (Object.keys(AMBIENT_URLS) as AmbientTrack[]).forEach(track => {
      const a = new Audio(AMBIENT_URLS[track]);
      a.loop = true;
      a.volume = 0;
      a.preload = 'auto';
      ambientRefs.current[track] = a;
    });
    const rt = new Audio(AMBIENT_URLS.room);
    rt.loop = true;
    rt.volume = 0;
    rt.preload = 'auto';
    roomToneRef.current = rt;

    return () => {
      (Object.keys(AMBIENT_URLS) as AmbientTrack[]).forEach(track => {
        const a = ambientRefs.current[track];
        if (a) { a.pause(); a.src = ''; }
      });
      rt.pause();
      rt.src = '';
    };
  }, []);

  // ── Compute and apply mix gains whenever any input changes ─────────
  // This is the central mixer. Single source of truth.
  useEffect(() => {
    // 1. Compute room tone (always, but only audible when voice is playing or room is in active list)
    const rt = roomToneRef.current;
    if (rt) {
      const roomTarget = Math.min(ROOM_TONE_MAX, roomToneVolume);
      // Room tone plays quietly whenever ANY audio is active, but extra-subtle when voice is on
      const baseTarget = isPlaying ? roomTarget : (roomTarget * 0.4);
      fadeGain(rt, baseTarget, 1200);
      if (baseTarget > 0.001 && rt.paused) rt.play().catch(() => {});
      if (baseTarget < 0.001 && !rt.paused) rt.pause();
    }

    // 2. Compute ambient mix
    const activeTracks = (Object.keys(ambient) as AmbientTrack[]).filter(t => ambient[t].active);
    const headroom = isPlaying ? AMBIENT_TOTAL_HEADROOM : AMBIENT_TOTAL_HEADROOM_NOVOICE;
    // Sum of slider values for active tracks
    const totalSlider = activeTracks.reduce((sum, t) => sum + ambient[t].slider, 0);
    // Normalize so the active set shares the headroom proportionally to slider
    // (so enabling 3 tracks doesn't triple the volume — it redistributes)
    const share = totalSlider > 0 ? headroom / totalSlider : 0;

    (Object.keys(ambient) as AmbientTrack[]).forEach(track => {
      const a = ambientRefs.current[track];
      if (!a) return;
      const isActive = ambient[track].active;
      if (!isActive) {
        fadeGain(a, 0, 600);
        // Pause after fade
        setTimeout(() => { if (a.paused === false && a.volume < 0.01) a.pause(); }, 700);
        return;
      }
      // Per-track applied gain: slider × per-track cap × share-of-headroom × duck-ratio
      const duck = isPlaying ? duckRatio : 1.0;
      const target = Math.min(PER_TRACK_CAP, ambient[track].slider * share * duck);
      fadeGain(a, target, 800);
      if (a.paused) a.play().catch(() => {});
    });
  }, [ambient, roomToneVolume, isPlaying, duckRatio]);

  // ── Voice volume ───────────────────────────────────────────────────
  useEffect(() => {
    if (voiceRef.current) voiceRef.current.volume = Math.min(1, voiceVolume * masterGain);
  }, [voiceVolume, masterGain]);

  // ── Track controls ────────────────────────────────────────────────
  const loadTrack: AudioState['loadTrack'] = useCallback((t) => {
    if (!voiceRef.current) return;
    if (currentTrack?.audioUrl === t.audioUrl && currentTrack?.title === t.title) return;
    voiceRef.current.src = t.audioUrl;
    voiceRef.current.load();
    setCurrentTrack(t);
    setProgress(0);
    setDuration(t.duration || 0);
    setIsPlaying(false);
  }, [currentTrack]);

  const play = useCallback(() => {
    if (!voiceRef.current || !currentTrack) return;
    voiceRef.current.play().then(() => setIsPlaying(true)).catch((e) => {
      console.warn('play failed', e);
      setIsPlaying(false);
    });
  }, [currentTrack]);

  const pause = useCallback(() => {
    if (!voiceRef.current) return;
    voiceRef.current.pause();
    setIsPlaying(false);
  }, []);

  const toggle = useCallback(() => {
    if (isPlaying) pause(); else play();
  }, [isPlaying, play, pause]);

  const seek = useCallback((time: number) => {
    if (voiceRef.current) {
      voiceRef.current.currentTime = time;
      setProgress(time);
    }
  }, []);

  const toggleAmbient = useCallback((track: AmbientTrack) => {
    setAmbient(prev => ({ ...prev, [track]: { ...prev[track], active: !prev[track].active } }));
  }, []);

  const setAmbientSlider = useCallback((track: AmbientTrack, vol: number) => {
    setAmbient(prev => ({ ...prev, [track]: { ...prev[track], slider: Math.max(0, Math.min(1, vol)) } }));
  }, []);

  const stopAll = useCallback(() => {
    pause();
    setAmbient(prev => {
      const next = { ...prev };
      (Object.keys(next) as AmbientTrack[]).forEach(t => { next[t] = { ...next[t], active: false }; });
      return next;
    });
  }, [pause]);

  return (
    <AudioContext.Provider value={{
      currentTrack, isPlaying, progress, duration,
      voiceVolume, setVoiceVolume,
      masterGain, setMasterGain,
      loadTrack, play, pause, toggle, seek,
      ambient, toggleAmbient, setAmbientSlider, stopAll,
      roomToneVolume, setRoomToneVolume,
      duckRatio, setDuckRatio,
    }}>
      {children}
    </AudioContext.Provider>
  );
}

export function useAudio() {
  const ctx = useContext(AudioContext);
  if (!ctx) throw new Error('useAudio must be used within AudioProvider');
  return ctx;
}

// Re-export the labels for AmbientMixer / etc.
export { AMBIENT_LABELS };
