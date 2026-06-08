'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { Wind } from 'lucide-react';

export function BreathWidget({ practice }: { practice: any }) {
  const inhale = practice?.inhale_seconds ?? 4;
  const hold = practice?.hold_seconds ?? 7;
  const exhale = practice?.exhale_seconds ?? 8;
  const cycle = inhale + hold + exhale;

  const [phase, setPhase] = useState<'in' | 'hold' | 'out' | 'rest'>('in');
  const [elapsed, setElapsed] = useState(0);
  const [running, setRunning] = useState(false);

  useEffect(() => {
    if (!running) return;
    const id = setInterval(() => setElapsed(e => e + 0.1), 100);
    return () => clearInterval(id);
  }, [running]);

  useEffect(() => {
    if (!running) return;
    let p: 'in' | 'hold' | 'out' | 'rest' = 'in';
    let acc = 0;
    if (elapsed < inhale) p = 'in';
    else if (elapsed < inhale + hold) p = 'hold';
    else if (elapsed < cycle) p = 'out';
    else p = 'rest';
    setPhase(p);
    if (elapsed >= cycle) setElapsed(0);
  }, [elapsed, running, inhale, hold, exhale, cycle]);

  const scale = phase === 'in' ? 1.4 : phase === 'out' ? 1 : phase === 'hold' ? 1.4 : 1;
  const label = phase === 'in' ? 'Breathe in' : phase === 'hold' ? 'Hold' : phase === 'out' ? 'Breathe out' : 'Rest';

  return (
    <div className="card-quiet p-8 flex flex-col h-full">
      <p className="text-xs tracking-widest uppercase text-ink/40 mb-6">Breath</p>

      <div className="flex-1 flex items-center justify-center my-4">
        <button
          onClick={() => setRunning(r => !r)}
          className="relative w-32 h-32 rounded-full flex items-center justify-center group focus:outline-none"
          aria-label={running ? 'Pause breath' : 'Begin breath'}
        >
          <span
            className="absolute inset-0 rounded-full bg-gradient-to-br from-sage-200 to-sage-400 transition-transform duration-1000 ease-in-out"
            style={{ transform: `scale(${scale})`, opacity: 0.35 }}
          />
          <span
            className="absolute inset-4 rounded-full bg-gradient-to-br from-sage-300 to-sage-500 transition-transform duration-1000 ease-in-out"
            style={{ transform: `scale(${scale})`, opacity: 0.5 }}
          />
          <span className="relative serif text-lg text-ink/80 z-10">{label}</span>
        </button>
      </div>

      <p className="text-center text-sm text-ink/50 serif italic">
        {practice?.name || '4-7-8 Breath'} · {inhale}-{hold}-{exhale}
      </p>

      <Link
        href="/breathe"
        className="mt-6 inline-flex items-center justify-center gap-2 text-sm text-ink/60 hover:text-ink transition-colors"
      >
        <Wind size={14} /> More breath practices
      </Link>
    </div>
  );
}
