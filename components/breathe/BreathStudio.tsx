'use client';

import { useState, useEffect, useRef } from 'react';

type Practice = {
  id: string;
  name: string;
  slug: string;
  description?: string;
  instructions?: string;
  pattern?: string;
  inhale_seconds?: number;
  hold_seconds?: number;
  exhale_seconds?: number;
  cycles?: number;
  theme?: string;
};

const PHASES: Array<'in' | 'hold' | 'out' | 'pause'> = ['in', 'hold', 'out', 'pause'];

export function BreathStudio({ practices }: { practices: Practice[] }) {
  const [active, setActive] = useState<Practice | null>(practices[0] || null);
  const [running, setRunning] = useState(false);
  const [phase, setPhase] = useState<'in' | 'hold' | 'out' | 'pause'>('in');
  const [elapsed, setElapsed] = useState(0);
  const [cycleCount, setCycleCount] = useState(0);

  const cycle = useRef(0);

  useEffect(() => {
    if (!active) return;
    const inhale = active.inhale_seconds ?? 4;
    const hold = active.hold_seconds ?? 4;
    const exhale = active.exhale_seconds ?? 4;
    const total = inhale + hold + exhale;
    cycle.current = total;
  }, [active]);

  useEffect(() => {
    if (!running || !active) return;
    const id = setInterval(() => setElapsed(e => e + 0.1), 100);
    return () => clearInterval(id);
  }, [running, active]);

  useEffect(() => {
    if (!running || !active) return;
    const inhale = active.inhale_seconds ?? 4;
    const hold = active.hold_seconds ?? 4;
    const exhale = active.exhale_seconds ?? 4;
    const total = cycle.current;

    let p: 'in' | 'hold' | 'out' | 'pause' = 'in';
    if (elapsed < inhale) p = 'in';
    else if (elapsed < inhale + hold) p = 'hold';
    else if (elapsed < total) p = 'out';
    else p = 'pause';
    setPhase(p);

    if (elapsed >= total) {
      setElapsed(0);
      setCycleCount(c => c + 1);
      if (active.cycles && cycleCount + 1 >= active.cycles) {
        setRunning(false);
      }
    }
  }, [elapsed, running, active, cycleCount]);

  if (!active) {
    return <p className="text-ink/50 serif italic">No breath practices yet.</p>;
  }

  const inhale = active.inhale_seconds ?? 4;
  const hold = active.hold_seconds ?? 4;
  const exhale = active.exhale_seconds ?? 4;
  const scale = phase === 'in' ? 1.4 : phase === 'hold' ? 1.4 : 1;
  const phaseLabel = phase === 'in' ? 'Breathe in' : phase === 'hold' ? 'Hold' : phase === 'out' ? 'Breathe out' : 'Rest';

  return (
    <div className="grid lg:grid-cols-[1fr_360px] gap-8">
      {/* Active studio */}
      <div className="card-quiet p-12 flex flex-col items-center justify-center min-h-[480px] relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-sage-50/40 to-bone pointer-events-none" />

        <button
          onClick={() => setRunning(r => !r)}
          className="relative w-72 h-72 rounded-full flex items-center justify-center group focus:outline-none mb-8"
          aria-label={running ? 'Pause' : 'Begin'}
        >
          <span
            className="absolute inset-0 rounded-full bg-gradient-to-br from-sage-200 to-sage-400 transition-transform ease-in-out"
            style={{ transform: `scale(${scale})`, opacity: 0.3, transitionDuration: `${(phase === 'in' ? inhale : phase === 'out' ? exhale : 0.5) * 1000}ms` }}
          />
          <span
            className="absolute inset-8 rounded-full bg-gradient-to-br from-sage-300 to-sage-500 transition-transform ease-in-out"
            style={{ transform: `scale(${scale})`, opacity: 0.45, transitionDuration: `${(phase === 'in' ? inhale : phase === 'out' ? exhale : 0.5) * 1000}ms` }}
          />
          <span
            className="absolute inset-16 rounded-full bg-gradient-to-br from-sage-400 to-sage-600 transition-transform ease-in-out"
            style={{ transform: `scale(${scale})`, opacity: 0.7, transitionDuration: `${(phase === 'in' ? inhale : phase === 'out' ? exhale : 0.5) * 1000}ms` }}
          />
          <span className="relative serif text-2xl text-bone z-10 font-light tracking-wide">
            {phaseLabel}
          </span>
        </button>

        <p className="text-sm text-ink/50 tracking-wider">
          {active.pattern || `${inhale}-${hold}-${exhale}`}
          {active.cycles ? ` · ${cycleCount}/${active.cycles} cycles` : ''}
        </p>
      </div>

      {/* Practice list */}
      <aside className="space-y-3">
        <p className="text-xs tracking-widest uppercase text-ink/40 mb-2">Practices</p>
        {practices.map(p => (
          <button
            key={p.id}
            onClick={() => { setActive(p); setRunning(false); setElapsed(0); setCycleCount(0); }}
            className={`w-full text-left p-4 rounded-2xl border transition-all ${
              active.id === p.id
                ? 'bg-ink text-bone border-ink'
                : 'bg-paper border-ink/10 hover:border-ink/30'
            }`}
          >
            <p className="serif text-lg">{p.name}</p>
            <p className={`text-sm mt-1 ${active.id === p.id ? 'text-bone/70' : 'text-ink/60'}`}>
              {p.pattern || `${p.inhale_seconds || 4}-${p.hold_seconds || 4}-${p.exhale_seconds || 4}`}
              {p.cycles ? ` · ${p.cycles} cycles` : ''}
            </p>
            {p.description && (
              <p className={`text-xs mt-2 ${active.id === p.id ? 'text-bone/60' : 'text-ink/50'}`}>
                {p.description}
              </p>
            )}
          </button>
        ))}

        {active.instructions && (
          <div className="mt-6 p-5 bg-sage-50/40 rounded-2xl border border-sage-100">
            <p className="text-xs tracking-widest uppercase text-sage-700 mb-2">Instructions</p>
            <p className="text-sm text-ink/70 leading-relaxed">{active.instructions}</p>
          </div>
        )}
      </aside>
    </div>
  );
}
