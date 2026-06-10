'use client';

import { createContext, useContext, useState, useRef, useEffect, useCallback, ReactNode } from 'react';

export type AmbientTrack = 'rain' | 'ocean' | 'forest' | 'drone' | 'piano';

type AudioState = {
  // Voice / meditation audio
  currentTrack: { title: string; audioUrl: string; duration?: number; illustrationUrl?: string } | null;
  isPlaying: boolean;
  progress: number;
  duration: number;
  volume: number;
  setVolume: (v: number) => void;
  loadTrack: (t: { title: string; audioUrl: string; duration?: number; illustrationUrl?: string }) => void;
  play: () => void;
  pause: () => void;
  toggle: () => void;
  seek: (time: number) => void;
  // Ambient mixer
  ambient: Record<AmbientTrack, { active: boolean; volume: number }>;
  toggleAmbient: (track: AmbientTrack) => void;
  setAmbientVolume: (track: AmbientTrack, vol: number) => void;
  stopAll: () => void;
};

const AudioContext = createContext<AudioState | null>(null);

const AMBIENT_URLS: Record<AmbientTrack, string> = {
  rain: '/audio/ambient-rain.mp3',
  ocean: '/audio/ambient-ocean.mp3',
  forest: '/audio/ambient-forest.mp3',
  drone: '/audio/ambient-drone.mp3',
  piano: '/audio/ambient-piano.mp3',
};

const AMBIENT_LABELS: Record<AmbientTrack, string> = {
  rain: 'Rain',
  ocean: 'Ocean',
  forest: 'Forest',
  drone: 'Drone',
  piano: 'Piano',
};

export function AudioProvider({ children }: { children: ReactNode }) {
  const [currentTrack, setCurrentTrack] = useState<AudioState['currentTrack']>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(0.85);

  const [ambient, setAmbient] = useState<Record<AmbientTrack, { active: boolean; volume: number }>>({
    rain: { active: false, volume: 0.4 },
    ocean: { active: false, volume: 0.4 },
    forest: { active: false, volume: 0.4 },
    drone: { active: false, volume: 0.4 },
    piano: { active: false, volume: 0.3 },
  });

  const voiceRef = useRef<HTMLAudioElement | null>(null);
  const ambientRefs = useRef<Record<AmbientTrack, HTMLAudioElement | null>>({
    rain: null, ocean: null, forest: null, drone: null, piano: null,
  });

  // Initialize voice audio element
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

  // Initialize ambient audio elements
  useEffect(() => {
    (Object.keys(AMBIENT_URLS) as AmbientTrack[]).forEach(track => {
      const a = new Audio(AMBIENT_URLS[track]);
      a.loop = true;
      a.volume = 0;
      a.preload = 'auto';
      ambientRefs.current[track] = a;
    });
    return () => {
      (Object.keys(AMBIENT_URLS) as AmbientTrack[]).forEach(track => {
        const a = ambientRefs.current[track];
        if (a) { a.pause(); a.src = ''; }
      });
    };
  }, []);

  // Apply voice volume
  useEffect(() => {
    if (voiceRef.current) voiceRef.current.volume = volume;
  }, [volume]);

  // Apply ambient volumes
  useEffect(() => {
    (Object.keys(ambient) as AmbientTrack[]).forEach(track => {
      const a = ambientRefs.current[track];
      if (a) a.volume = ambient[track].active ? ambient[track].volume : 0;
    });
  }, [ambient]);

  // Sync ambient play/pause with active state
  useEffect(() => {
    (Object.keys(ambient) as AmbientTrack[]).forEach(track => {
      const a = ambientRefs.current[track];
      if (!a) return;
      if (ambient[track].active && a.paused) a.play().catch(() => {});
      if (!ambient[track].active && !a.paused) a.pause();
    });
  }, [ambient]);

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

  const setAmbientVolume = useCallback((track: AmbientTrack, vol: number) => {
    setAmbient(prev => ({ ...prev, [track]: { ...prev[track], volume: vol } }));
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
      currentTrack, isPlaying, progress, duration, volume, setVolume,
      loadTrack, play, pause, toggle, seek,
      ambient, toggleAmbient, setAmbientVolume, stopAll,
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

export { AMBIENT_LABELS };
