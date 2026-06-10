'use client';

import { useState, useEffect, useRef } from 'react';
import { Wind } from 'lucide-react';

type Phase = 'in' | 'hold' | 'out' | 'rest';

const PHASES: Array<{ label: string; phase: Phase; duration: number }> = [
  { label: 'Breathe in', phase: 'in', duration: 4 },
  { label: 'Hold', phase: 'hold', duration: 4 },
  { label: 'Breathe out', phase: 'out', duration: 4 },
  { label: 'Rest', phase: 'rest', duration: 2 },
];

export function QuickBreath() {
  const [running, setRunning] = useState(false);
  const [step, setStep] = useState(0);
  const [cycles, setCycles] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (!running) {
      if (timerRef.current) clearInterval(timerRef.current);
      return;
    }
    let elapsed = 0;
    const tickMs = 50;
    timerRef.current = setInterval(() => {
      elapsed += tickMs / 1000;
      const cur = PHASES[step];
      if (elapsed >= cur.duration) {
        elapsed = 0;
        setStep(s => {
          const next = (s + 1) % PHASES.length;
          if (next === 0) setCycles(c => c + 1);
          return next;
        });
      }
    }, tickMs);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [running, step]);

  const cur = PHASES[step];
  const scale = cur.phase === 'in' || cur.phase === 'hold' ? 1.4 : 0.85;
  const isGlowing = running;

  return (
    <div className="card-quiet p-8 flex flex-col items-center text-center">
      <div className="flex items-center gap-2 mb-4 self-start">
        <Wind size={14} className="text-sage-600" />
        <p className="text-xs tracking-widest uppercase text-ink/40">Take a breath</p>
      </div>

      <div className="relative w-48 h-48 flex items-center justify-center my-4">
        {/* Outer soft ring */}
        <div
          className="absolute inset-0 rounded-full bg-gradient-to-br from-sage-200/30 to-sage-300/20 transition-transform ease-in-out"
          style={{ transform: `scale(${scale})`, transitionDuration: `${cur.duration}s` }}
        />
        {/* Middle ring */}
        <div
          className="absolute inset-6 rounded-full bg-gradient-to-br from-sage-300/40 to-sage-400/30 transition-transform ease-in-out"
          style={{ transform: `scale(${scale})`, transitionDuration: `${cur.duration}s` }}
        />
        {/* Core */}
        <div
          className="absolute inset-12 rounded-full bg-gradient-to-br from-sage-400/60 to-sage-600/50 transition-transform ease-in-out"
          style={{ transform: `scale(${scale})`, transitionDuration: `${cur.duration}s` }}
        />
        <span className="relative serif text-lg text-ink/80 z-10 transition-opacity duration-700" style={{ opacity: isGlowing ? 1 : 0.5 }}>
          {running ? cur.label : 'Box Breath'}
        </span>
      </div>

      <p className="text-sm text-ink/60 mb-4">
        {running
          ? `${cycles} cycle${cycles === 1 ? '' : 's'} so far`
          : 'Inhale 4 · Hold 4 · Exhale 4 · Rest 2'}
      </p>

      <button
        onClick={() => setRunning(r => !r)}
        className={`text-sm px-5 py-2 rounded-full transition-colors ${
          running
            ? 'bg-paper border border-ink/10 text-ink/70 hover:border-ink/30'
            : 'bg-ink text-bone hover:bg-ink/85'
        }`}
      >
        {running ? 'Stop' : 'Begin'}
      </button>
    </div>
  );
}
