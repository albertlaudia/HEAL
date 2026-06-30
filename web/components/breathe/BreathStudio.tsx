'use client';

import { useState, useEffect, useRef } from 'react';
import { Play, Pause, RotateCcw } from 'lucide-react';

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

const PHASE_LABELS: Record<'in' | 'hold' | 'out' | 'pause', string> = {
  in: 'Breathe in',
  hold: 'Hold',
  out: 'Breathe out',
  pause: 'Rest',
};

const PHASE_HINTS: Record<'in' | 'hold' | 'out' | 'pause', string> = {
  in: 'Fill the belly, not the chest',
  hold: 'Stillness at the top',
  out: 'Release what you are carrying',
  pause: 'A small holy pause',
};

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

  // Compute current phase elapsed for progress ring
  const phaseDur =
    phase === 'in' ? inhale :
    phase === 'hold' ? hold :
    phase === 'out' ? exhale : 1;
  const phaseElapsed =
    phase === 'in' ? elapsed :
    phase === 'hold' ? elapsed - inhale :
    phase === 'out' ? elapsed - inhale - hold :
    elapsed - inhale - hold - exhale;
  const phaseProgress = Math.max(0, Math.min(1, phaseElapsed / phaseDur));

  // Scale for breath circle
  const isIn = phase === 'in';
  const isHold = phase === 'hold';
  const isOut = phase === 'out';
  const scale = isIn || isHold ? 1.18 : isOut ? 0.82 : 1;

  const phaseLabel = PHASE_LABELS[phase];
  const phaseHint = PHASE_HINTS[phase];

  return (
    <div className="grid lg:grid-cols-[1fr_360px] gap-8">
      {/* Active studio */}
      <div className="card-quiet p-8 md:p-12 flex flex-col items-center justify-center min-h-[480px] relative overflow-hidden">
        {/* Radial glow that pulses with breath */}
        <div
          className="absolute inset-0 pointer-events-none transition-opacity duration-1000"
          style={{
            opacity: running ? 0.5 : 0.2,
            background: 'radial-gradient(circle at 50% 50%, rgba(168, 197, 160, 0.18) 0%, transparent 60%)',
          }}
        />

        {/* Header: practice name + cycle count */}
        <div className="relative z-10 flex items-center justify-between w-full mb-6 px-2">
          <div>
            <p className="text-[10px] tracking-widest uppercase text-ink/40 mb-1">Now</p>
            <p className="serif text-lg text-ink/85">{active.name}</p>
          </div>
          {(running || cycleCount > 0) && (
            <span className="text-[10px] tracking-widest uppercase text-sage-700 bg-sage-50 px-2.5 py-1 rounded-full">
              {cycleCount}{active.cycles ? `/${active.cycles}` : ''} cycles
            </span>
          )}
        </div>

        {/* Breathing visual with phase ring */}
        <div className="relative w-64 h-64 md:w-72 md:h-72 mb-4">
          {/* Phase progress ring */}
          <svg className="absolute inset-0 w-full h-full -rotate-90" viewBox="0 0 100 100">
            <circle cx="50" cy="50" r="46" fill="none" stroke="rgba(168, 197, 160, 0.15)" strokeWidth="1.5" />
            {running && (
              <circle
                cx="50" cy="50" r="46"
                fill="none"
                stroke="rgba(95, 130, 95, 0.9)"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeDasharray={`${2 * Math.PI * 46}`}
                strokeDashoffset={`${2 * Math.PI * 46 * (1 - phaseProgress)}`}
                style={{ transition: 'stroke-dashoffset 100ms linear' }}
              />
            )}
            {/* Phase ticks (4 segments) */}
            {[0, 1, 2, 3].map(i => {
              const angle = (i / 4) * 2 * Math.PI;
              const x = 50 + 42 * Math.cos(angle - Math.PI / 2);
              const y = 50 + 42 * Math.sin(angle - Math.PI / 2);
              return (
                <circle
                  key={i}
                  cx={x}
                  cy={y}
                  r={1.5}
                  fill={i === ['in', 'hold', 'out', 'pause'].indexOf(phase) ? 'rgba(95, 130, 95, 0.9)' : 'rgba(168, 197, 160, 0.4)'}
                />
              );
            })}
          </svg>

          {/* Breathing core — 3 layered circles + scale */}
          <button
            onClick={() => setRunning(r => !r)}
            className="absolute inset-6 rounded-full flex items-center justify-center focus:outline-none"
            aria-label={running ? 'Pause' : 'Begin'}
          >
            <div className="absolute inset-0 rounded-full overflow-hidden">
              <div
                className="absolute inset-0 rounded-full transition-transform ease-in-out"
                style={{
                  background: 'radial-gradient(circle at 35% 35%, rgba(200, 220, 195, 0.45), rgba(168, 197, 160, 0.18) 60%, transparent)',
                  transform: `scale(${scale})`,
                  transitionDuration: `${(isIn ? inhale : isOut ? exhale : 0.5) * 1000}ms`,
                }}
              />
              <div
                className="absolute inset-[12%] rounded-full transition-transform ease-in-out"
                style={{
                  background: 'radial-gradient(circle at 35% 35%, rgba(168, 197, 160, 0.6), rgba(120, 160, 120, 0.35))',
                  transform: `scale(${scale})`,
                  transitionDuration: `${(isIn ? inhale : isOut ? exhale : 0.5) * 1000}ms`,
                }}
              />
              <div
                className="absolute inset-[28%] rounded-full transition-transform ease-in-out flex items-center justify-center"
                style={{
                  background: 'radial-gradient(circle at 30% 30%, rgba(95, 130, 95, 0.85), rgba(60, 95, 70, 0.65))',
                  transform: `scale(${scale})`,
                  transitionDuration: `${(isIn ? inhale : isOut ? exhale : 0.5) * 1000}ms`,
                }}
              >
                <span
                  key={phase + (running ? '-running' : '-idle')}
                  className="serif text-xl md:text-2xl text-bone font-light tracking-wide animate-fade-in"
                  style={{ animationDuration: '500ms' }}
                >
                  {running ? phaseLabel : 'Begin'}
                </span>
              </div>
            </div>
          </button>
        </div>

        {/* Phase hint */}
        <p
          key={`hint-${phase}-${running}`}
          className="serif italic text-sm text-ink/55 text-center mb-3 h-5 animate-fade-in"
          style={{ animationDuration: '500ms' }}
        >
          {running ? phaseHint : `${inhale}-${hold}-${exhale} · ${active.cycles ? active.cycles + ' cycles' : 'open ended'}`}
        </p>

        {/* Controls */}
        <div className="relative z-10 flex items-center gap-3">
          <button
            onClick={() => setRunning(r => !r)}
            className={`inline-flex items-center gap-2 px-6 py-3 rounded-full text-sm transition-all ${
              running
                ? 'bg-paper border border-ink/15 text-ink/80 hover:border-ink/30'
                : 'bg-ink text-bone hover:bg-ink/85 hover:scale-[1.02]'
            }`}
            aria-label={running ? 'Pause' : 'Begin'}
          >
            {running ? <Pause size={14} /> : <Play size={14} className="ml-0.5" />}
            <span>{running ? 'Pause' : 'Begin'}</span>
          </button>
          <button
            onClick={() => { setRunning(false); setElapsed(0); setCycleCount(0); }}
            className="inline-flex items-center gap-2 px-4 py-3 rounded-full text-sm bg-paper border border-ink/10 text-ink/60 hover:border-ink/30"
            aria-label="Reset"
            title="Reset"
          >
            <RotateCcw size={13} />
            <span>Reset</span>
          </button>
        </div>
      </div>

      {/* Practice list */}
      <aside className="space-y-3">
        <div className="flex items-center justify-between mb-2">
          <p className="text-xs tracking-widest uppercase text-ink/40">Practices</p>
          <span className="text-[10px] text-ink/40">{practices.length}</span>
        </div>
        {practices.map(p => (
          <button
            key={p.id}
            onClick={() => { setActive(p); setRunning(false); setElapsed(0); setCycleCount(0); }}
            className={`w-full text-left p-4 rounded-2xl border transition-all ${
              active.id === p.id
                ? 'bg-ink text-bone border-ink shadow-md'
                : 'bg-paper border-ink/10 hover:border-ink/30 hover:bg-cream-50'
            }`}
          >
            <div className="flex items-center justify-between mb-1">
              <p className="serif text-lg">{p.name}</p>
              <span className={`text-[10px] font-mono tracking-wide ${active.id === p.id ? 'text-bone/60' : 'text-ink/40'}`}>
                {p.pattern || `${p.inhale_seconds || 4}-${p.hold_seconds || 4}-${p.exhale_seconds || 4}`}
              </span>
            </div>
            {p.description && (
              <p className={`text-xs leading-relaxed ${active.id === p.id ? 'text-bone/70' : 'text-ink/60'}`}>
                {p.description}
              </p>
            )}
          </button>
        ))}

        {active.instructions && (
          <div className="mt-6 p-5 bg-sage-50/40 rounded-2xl border border-sage-100">
            <p className="text-xs tracking-widest uppercase text-sage-700 mb-2">How to do this</p>
            <p className="text-sm text-ink/70 leading-relaxed">{active.instructions}</p>
          </div>
        )}
      </aside>
    </div>
  );
}
