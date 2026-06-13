'use client';

import { createContext, useContext, useState, useRef, useEffect, useCallback, ReactNode } from 'react';

export type AmbientTrack = 'rain' | 'ocean' | 'forest' | 'drone' | 'piano' | 'whitenoise' | 'fire' | 'river' | 'wind' | 'room';

type AudioState = {
  // Voice / meditation audio
  currentTrack: { title: string; audioUrl: string; duration?: number; illustrationUrl?: string } | null;
  isPlaying: boolean;
  progress: number;
  duration: number;

  // Loading state — true when audio is being fetched/decoded
  audioLoading: boolean;
  audioLoadProgress: number; // 0-100

  // Voice volume (0..1) — separate from master
  voiceVolume: number;
  setVoiceVolume: (v: number) => void;

  // Master output gain (0..1) — final stage, applies to everything
  masterVolume: number;
  setMasterVolume: (v: number) => void;

  // Mute toggle
  muted: boolean;
  toggleMute: () => void;

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
  roomToneVolume: number;
  setRoomToneVolume: (v: number) => void;

  // Ducking: when voice plays, ambient is multiplied by this
  duckRatio: number;
  setDuckRatio: (v: number) => void;

  // Diagnostics for the user — what is actually being heard right now
  effectiveVoiceGain: number;
  effectiveAmbientGain: number;
  effectiveRoomToneGain: number;
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
// AUDIO MIXING DESIGN (v3 — Web Audio API, proper gain staging)
//
// Sources: voice ≈ -8 dBFS, ambient ≈ -15 dBFS, all normalized.
//
// Signal flow per source:
//
//   <audio>  ──►  MediaElementSource  ──►  GainNode  ──┐
//                                                     │
//   (master)  ─────────────────────────────────────────►  Compressor
//                                                            ──►  GainNode (master)
//                                                            ──►  destination
//
// All real-time mixing happens in Web Audio API so the user's gain
// changes are audibly instant and the compressor prevents any clipping.
// ─────────────────────────────────────────────────────────────────────

const ROOM_TONE_MAX = 0.12;          // hard ceiling for the always-on room tone slider
const AMBIENT_HEADROOM_WITH_VOICE = 0.30; // total ambient sum (after duck) when voice is on
const AMBIENT_HEADROOM_NO_VOICE = 0.70;   // when no voice, ambient can be louder
const DUCK_RATIO = 0.25;             // ambient is multiplied by 0.25 when voice is on
const PER_TRACK_CAP = 0.5;          // any single track can contribute at most this
const COMPRESSOR_THRESHOLD = -18;   // dB — soft knee starts here
const COMPRESSOR_RATIO = 6;          // 6:1 above threshold
const COMPRESSOR_ATTACK = 0.003;     // 3ms — fast enough to catch transients
const COMPRESSOR_RELEASE = 0.25;     // 250ms — smooth musical release
const COMPRESSOR_KNEE = 6;           // dB — soft knee

export function AudioProvider({ children }: { children: ReactNode }) {
  const [currentTrack, setCurrentTrack] = useState<AudioState['currentTrack']>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [audioLoading, setAudioLoading] = useState(false);
  const [audioLoadProgress, setAudioLoadProgress] = useState(0);

  // Volumes
  const [voiceVolume, setVoiceVolume] = useState(0.9);
  const [masterVolume, setMasterVolume] = useState(0.85);
  const [muted, setMuted] = useState(false);
  const [roomToneVolume, setRoomToneVolume] = useState(0.05);
  const [duckRatio, setDuckRatio] = useState(DUCK_RATIO);

  // Per-track slider 0..1. Defaults LOWER than before — first use should be subtle.
  const [ambient, setAmbient] = useState<Record<AmbientTrack, { active: boolean; slider: number }>>({
    rain: { active: false, slider: 0.4 },
    ocean: { active: false, slider: 0.4 },
    forest: { active: false, slider: 0.4 },
    drone: { active: false, slider: 0.4 },
    piano: { active: false, slider: 0.35 },
    whitenoise: { active: false, slider: 0.3 },
    fire: { active: false, slider: 0.4 },
    river: { active: false, slider: 0.4 },
    wind: { active: false, slider: 0.4 },
    room: { active: false, slider: 0.3 },
  });

  // ── Refs to audio infrastructure ──────────────────────────────────
  const voiceRef = useRef<HTMLAudioElement | null>(null);
  const roomToneRef = useRef<HTMLAudioElement | null>(null);
  const ambientRefs = useRef<Record<AmbientTrack, HTMLAudioElement | null>>({
    rain: null, ocean: null, forest: null, drone: null, piano: null,
    whitenoise: null, fire: null, river: null, wind: null, room: null,
  });

  // Web Audio API graph
  const audioCtxRef = useRef<AudioContext | null>(null);
  const masterGainRef = useRef<GainNode | null>(null);
  const compressorRef = useRef<DynamicsCompressorNode | null>(null);
  const voiceGainRef = useRef<GainNode | null>(null);
  const roomToneGainRef = useRef<GainNode | null>(null);
  const ambientGainsRef = useRef<Record<AmbientTrack, GainNode | null>>({
    rain: null, ocean: null, forest: null, drone: null, piano: null,
    whitenoise: null, fire: null, river: null, wind: null, room: null,
  });

  // Diagnostics — what is actually being heard?
  const [effectiveVoiceGain, setEffectiveVoiceGain] = useState(0);
  const [effectiveAmbientGain, setEffectiveAmbientGain] = useState(0);
  const [effectiveRoomToneGain, setEffectiveRoomToneGain] = useState(0);

  // ── Initialize Web Audio API once ──────────────────────────────────
  useEffect(() => {
    if (typeof window === 'undefined') return;
    try {
      const AudioCtor = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioCtor) return;
      const ctx = new AudioCtor();
      audioCtxRef.current = ctx;

      // Master chain: compressor → master gain → destination
      const compressor = ctx.createDynamicsCompressor();
      compressor.threshold.value = COMPRESSOR_THRESHOLD;
      compressor.ratio.value = COMPRESSOR_RATIO;
      compressor.attack.value = COMPRESSOR_ATTACK;
      compressor.release.value = COMPRESSOR_RELEASE;
      compressor.knee.value = COMPRESSOR_KNEE;
      compressorRef.current = compressor;

      const masterGain = ctx.createGain();
      masterGain.gain.value = masterVolume;
      masterGainRef.current = masterGain;

      compressor.connect(masterGain).connect(ctx.destination);
    } catch (e) {
      console.warn('Web Audio API init failed; falling back to element volume', e);
    }
    return () => {
      try { audioCtxRef.current?.close(); } catch {}
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Voice audio element (MediaElementSource) ─────────────────────
  useEffect(() => {
    const a = new Audio();
    a.preload = 'metadata';
    a.loop = false;
    a.addEventListener('timeupdate', () => setProgress(a.currentTime));
    a.addEventListener('loadedmetadata', () => {
      setDuration(a.duration || 0);
      setAudioLoading(false);
      setAudioLoadProgress(100);
    });
    a.addEventListener('durationchange', () => {
      if (a.duration && !isNaN(a.duration)) setDuration(a.duration);
    });
    a.addEventListener('canplay', () => {
      setAudioLoading(false);
      setAudioLoadProgress(100);
    });
    a.addEventListener('waiting', () => {
      setAudioLoading(true);
    });
    a.addEventListener('stalled', () => {
      setAudioLoading(true);
    });
    a.addEventListener('progress', () => {
      if (a.duration && !isNaN(a.duration) && a.buffered.length > 0) {
        const bufferedEnd = a.buffered.end(a.buffered.length - 1);
        const pct = (bufferedEnd / a.duration) * 100;
        setAudioLoadProgress(pct);
        if (pct >= 99) setAudioLoading(false);
      }
    });
    a.addEventListener('ended', () => {
      setIsPlaying(false);
      setProgress(0);
      setAudioLoading(false);
    });
    a.addEventListener('error', () => {
      console.warn('voice audio error', a.src);
      setIsPlaying(false);
      setAudioLoading(false);
    });
    a.addEventListener('loadstart', () => {
      setAudioLoading(true);
      setAudioLoadProgress(0);
    });
    voiceRef.current = a;

    // Wire into Web Audio API if available
    const ctx = audioCtxRef.current;
    if (ctx && compressorRef.current) {
      try {
        const src = ctx.createMediaElementSource(a);
        const gain = ctx.createGain();
        gain.gain.value = voiceVolume;
        voiceGainRef.current = gain;
        src.connect(gain).connect(compressorRef.current);
      } catch (e) {
        console.warn('voice MediaElementSource failed', e);
      }
    }

    return () => {
      a.pause();
      a.src = '';
    };
  }, []);

  // ── Ambient + room tone audio elements ───────────────────────────
  useEffect(() => {
    const ctx = audioCtxRef.current;
    const compressor = compressorRef.current;
    (Object.keys(AMBIENT_URLS) as AmbientTrack[]).forEach(track => {
      const a = new Audio(AMBIENT_URLS[track]);
      a.loop = true;
      a.volume = 1; // We control gain via Web Audio; element volume is 1 (full source)
      a.preload = 'auto';
      ambientRefs.current[track] = a;

      if (ctx && compressor) {
        try {
          const src = ctx.createMediaElementSource(a);
          const gain = ctx.createGain();
          gain.gain.value = 0;
          ambientGainsRef.current[track] = gain;
          src.connect(gain).connect(compressor);
        } catch (e) {
          console.warn(`ambient ${track} Web Audio failed`, e);
        }
      }
    });
    const rt = new Audio(AMBIENT_URLS.room);
    rt.loop = true;
    rt.volume = 1;
    rt.preload = 'auto';
    roomToneRef.current = rt;
    if (ctx && compressor) {
      try {
        const src = ctx.createMediaElementSource(rt);
        const gain = ctx.createGain();
        gain.gain.value = 0;
        roomToneGainRef.current = gain;
        src.connect(gain).connect(compressor);
      } catch (e) {
        console.warn('room tone Web Audio failed', e);
      }
    }

    return () => {
      (Object.keys(AMBIENT_URLS) as AmbientTrack[]).forEach(track => {
        const a = ambientRefs.current[track];
        if (a) { a.pause(); a.src = ''; }
      });
      rt.pause(); rt.src = '';
    };
  }, []);

  // ── Apply master volume ───────────────────────────────────────────
  useEffect(() => {
    if (masterGainRef.current) {
      const target = muted ? 0 : masterVolume;
      masterGainRef.current.gain.setTargetAtTime(target, audioCtxRef.current?.currentTime || 0, 0.05);
    } else {
      // Fallback: HTMLAudioElement.volume
      const factor = muted ? 0 : masterVolume;
      voiceRef.current && (voiceRef.current.volume = voiceVolume * factor);
      roomToneRef.current && (roomToneRef.current.volume = roomToneVolume * factor);
      (Object.keys(ambient) as AmbientTrack[]).forEach(t => {
        const a = ambientRefs.current[t];
        if (a) a.volume = (ambient[t].active ? ambient[t].slider * 0.4 : 0) * factor;
      });
    }
  }, [masterVolume, muted]);

  // ── Apply voice gain ──────────────────────────────────────────────
  useEffect(() => {
    if (voiceGainRef.current) {
      voiceGainRef.current.gain.setTargetAtTime(voiceVolume, audioCtxRef.current?.currentTime || 0, 0.05);
      setEffectiveVoiceGain(voiceVolume * (muted ? 0 : masterVolume));
    } else if (voiceRef.current) {
      voiceRef.current.volume = voiceVolume * (muted ? 0 : masterVolume);
    }
  }, [voiceVolume, masterVolume, muted]);

  // ── Compute and apply ambient mix ─────────────────────────────────
  useEffect(() => {
    const activeTracks = (Object.keys(ambient) as AmbientTrack[]).filter(t => ambient[t].active);
    const headroom = isPlaying ? AMBIENT_HEADROOM_WITH_VOICE : AMBIENT_HEADROOM_NO_VOICE;
    const totalSlider = activeTracks.reduce((sum, t) => sum + ambient[t].slider, 0);
    // Active tracks share the headroom proportionally — enabling 3 doesn't triple volume
    const share = totalSlider > 0 ? headroom / totalSlider : 0;

    let totalEffective = 0;
    (Object.keys(ambient) as AmbientTrack[]).forEach(track => {
      const gainNode = ambientGainsRef.current[track];
      const isActive = ambient[track].active;
      const slider = ambient[track].slider;

      // Computed target: slider × share-of-headroom × cap × duck
      const duck = isPlaying ? duckRatio : 1.0;
      const targetRaw = isActive ? Math.min(PER_TRACK_CAP, slider * share) * duck : 0;
      const finalTarget = muted ? 0 : targetRaw;

      if (gainNode) {
        // Web Audio API path
        const t = audioCtxRef.current?.currentTime || 0;
        gainNode.gain.setTargetAtTime(finalTarget, t, 0.08);
      } else {
        // HTMLAudioElement fallback
        const a = ambientRefs.current[track];
        if (a) a.volume = finalTarget;
      }
      if (isActive) totalEffective += finalTarget;
    });
    setEffectiveAmbientGain(totalEffective);

    // Room tone — always plays quietly under voice
    const roomTarget = Math.min(ROOM_TONE_MAX, roomToneVolume);
    const roomBase = isPlaying ? roomTarget : (roomTarget * 0.5);
    const roomFinal = muted ? 0 : (isPlaying || activeTracks.length > 0 ? roomBase : 0);
    if (roomToneGainRef.current) {
      const t = audioCtxRef.current?.currentTime || 0;
      roomToneGainRef.current.gain.setTargetAtTime(roomFinal, t, 0.12);
    } else if (roomToneRef.current) {
      roomToneRef.current.volume = roomFinal;
    }
    setEffectiveRoomToneGain(roomFinal);
  }, [ambient, isPlaying, duckRatio, roomToneVolume, muted]);

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
    setAudioLoading(true);
    setAudioLoadProgress(0);
  }, [currentTrack]);

  const play = useCallback(() => {
    if (!voiceRef.current || !currentTrack) return;
    voiceRef.current.play().then(() => setIsPlaying(true)).catch((e) => {
      console.warn('play failed', e);
      setIsPlaying(false);
    });
    // Resume Web Audio context (browser autoplay policy)
    if (audioCtxRef.current?.state === 'suspended') {
      audioCtxRef.current.resume().catch(() => {});
    }
  }, [currentTrack]);

  // Listen for the ritual "start meditation" event
  useEffect(() => {
    const onStart = (e: Event) => {
      const t = (e as CustomEvent).detail;
      if (t?.slug && currentTrack?.title) {
        // play() is on next tick so the audio element is ready
        setTimeout(() => play(), 50);
      }
    };
    window.addEventListener('heal:start-meditation', onStart as EventListener);
    return () => window.removeEventListener('heal:start-meditation', onStart as EventListener);
  }, [play, currentTrack]);

  // Dispatch a meditation-ended event when audio finishes
  useEffect(() => {
    const a = voiceRef.current;
    if (!a) return;
    const onEnded = () => {
      window.dispatchEvent(new CustomEvent('heal:meditation-ended', { detail: { title: currentTrack?.title } }));
    };
    a.addEventListener('ended', onEnded);
    return () => a.removeEventListener('ended', onEnded);
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

  const toggleMute = useCallback(() => {
    setMuted(m => !m);
  }, []);

  return (
    <AudioContext.Provider value={{
      currentTrack, isPlaying, progress, duration,
      audioLoading, audioLoadProgress,
      voiceVolume, setVoiceVolume,
      masterVolume, setMasterVolume,
      muted, toggleMute,
      loadTrack, play, pause, toggle, seek,
      ambient, toggleAmbient, setAmbientSlider, stopAll,
      roomToneVolume, setRoomToneVolume,
      duckRatio, setDuckRatio,
      effectiveVoiceGain, effectiveAmbientGain, effectiveRoomToneGain,
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
