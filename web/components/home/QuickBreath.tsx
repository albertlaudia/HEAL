'use client';

import Link from 'next/link';

import { useState, useEffect, useRef } from 'react';
import { Wind, Pause, Play } from 'lucide-react';

type Phase = 'in' | 'hold' | 'out' | 'rest';

const PHASES: Array<{ key: Phase; label: string; hint: string; duration: number }> = [
  { key: 'in',   label: 'Breathe in',  hint: 'Fill the belly, not the chest', duration: 4 },
  { key: 'hold', label: 'Hold',        hint: 'Stillness at the top',          duration: 4 },
  { key: 'out',  label: 'Breathe out', hint: 'Release what you are carrying',  duration: 4 },
  { key: 'rest', label: 'Rest',        hint: 'A small holy pause',              duration: 2 },
];

const PHASE_INDEX: Record<Phase, number> = { in: 0, hold: 1, out: 2, rest: 3 };

export function QuickBreath() {
  const [running, setRunning] = useState(false);
  const [step, setStep] = useState(0);
  const [cycles, setCycles] = useState(0);
  const [phaseElapsed, setPhaseElapsed] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (!running) {
      if (timerRef.current) clearInterval(timerRef.current);
      return;
    }
    setPhaseElapsed(0);
    const start = Date.now();
    const i = setInterval(() => {
      const e = (Date.now() - start) / 1000;
      const cur = PHASES[step];
      if (e >= cur.duration) {
        setStep(s => {
          const next = (s + 1) % PHASES.length;
          if (next === 0) setCycles(c => c + 1);
          return next;
        });
        setPhaseElapsed(0);
      } else {
        setPhaseElapsed(e);
      }
    }, 80);
    timerRef.current = i;
    return () => clearInterval(i);
  }, [running, step]);

  const cur = PHASES[step];
  const phaseProgress = Math.min(1, phaseElapsed / cur.duration);
  const isInhaling = cur.key === 'in';
  const isExhaling = cur.key === 'out';

  // 4-segment ring around the circle
  const ringSegments = PHASES.map((p, i) => {
    const segStart = (i / PHASES.length) * 2 * Math.PI - Math.PI / 2;
    const segEnd = ((i + 1) / PHASES.length) * 2 * Math.PI - Math.PI / 2;
    const active = i === step;
    const filled = active ? phaseProgress : (i < step || (running && false) ? 1 : 0);
    const largeArc = 2 * Math.PI / PHASES.length > Math.PI ? 1 : 0;
    const r = 46;
    const cx = 50, cy = 50;
    const x1 = cx + r * Math.cos(segStart);
    const y1 = cy + r * Math.sin(segStart);
    const x2 = cx + r * Math.cos(segEnd);
    const y2 = cy + r * Math.sin(segEnd);
    const x3 = cx + (r - 4) * Math.cos(segEnd);
    const y3 = cy + (r - 4) * Math.sin(segEnd);
    const x4 = cx + (r - 4) * Math.cos(segStart);
    const y4 = cy + (r - 4) * Math.sin(segStart);
    return { x1, y1, x2, y2, x3, y3, x4, y4, active, filled, largeArc };
  });

  return (
    <div className="card-quiet p-6 md:p-8 relative overflow-hidden">
      {/* Subtle background glow that pulses with breath */}
      <div
        className="absolute -inset-1 pointer-events-none transition-opacity duration-1000"
        style={{
          opacity: running ? 0.6 : 0.2,
          background: isInhaling
            ? 'radial-gradient(circle at 50% 50%, rgba(168, 197, 160, 0.15) 0%, transparent 70%)'
            : isExhaling
            ? 'radial-gradient(circle at 50% 50%, rgba(168, 197, 160, 0.08) 0%, transparent 70%)'
            : 'radial-gradient(circle at 50% 50%, rgba(168, 197, 160, 0.10) 0%, transparent 70%)',
        }}
      />

      <div className="relative">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Wind size={14} className="text-sage-600" />
            <p className="text-xs tracking-widest uppercase text-ink/40">Box breath</p>
          </div>
          {cycles > 0 && (
            <span className="text-[10px] tracking-widest uppercase text-sage-700 bg-sage-50 px-2 py-0.5 rounded-full">
              {cycles} {cycles === 1 ? 'cycle' : 'cycles'}
            </span>
          )}
        </div>

        {/* Breathing visual */}
        <div className="relative w-44 h-44 md:w-52 md:h-52 mx-auto my-2">
          {/* Progress ring (4 segments) */}
          <svg className="absolute inset-0 w-full h-full -rotate-90" viewBox="0 0 100 100">
            {/* Track ring */}
            <circle cx="50" cy="50" r="46" fill="none" stroke="rgba(168, 197, 160, 0.15)" strokeWidth="1.5" />
            {/* Active segment fill */}
            {running && (
              <circle
                cx="50" cy="50" r="46"
                fill="none"
                stroke="rgba(95, 130, 95, 0.85)"
                strokeWidth="2"
                strokeLinecap="round"
                strokeDasharray={`${2 * Math.PI * 46}`}
                strokeDashoffset={`${2 * Math.PI * 46 * (1 - phaseProgress / PHASES.length)}`}
                style={{ transition: 'stroke-dashoffset 80ms linear' }}
              />
            )}
          </svg>

          {/* Breathing core — 3 layered circles + scale */}
          <div className="absolute inset-0 flex items-center justify-center">
            <div
              className="absolute rounded-full transition-transform ease-in-out"
              style={{
                width: '88%',
                height: '88%',
                background: 'radial-gradient(circle at 35% 35%, rgba(200, 220, 195, 0.4), rgba(168, 197, 160, 0.15) 60%, transparent)',
                transform: `scale(${isInhaling || cur.key === 'hold' ? 1.18 : cur.key === 'out' ? 0.82 : 0.95})`,
                transitionDuration: `${cur.duration}s`,
              }}
            />
            <div
              className="absolute rounded-full transition-transform ease-in-out"
              style={{
                width: '68%',
                height: '68%',
                background: 'radial-gradient(circle at 35% 35%, rgba(168, 197, 160, 0.55), rgba(120, 160, 120, 0.3))',
                transform: `scale(${isInhaling || cur.key === 'hold' ? 1.18 : cur.key === 'out' ? 0.82 : 0.95})`,
                transitionDuration: `${cur.duration}s`,
              }}
            />
            <div
              className="absolute rounded-full transition-transform ease-in-out flex items-center justify-center"
              style={{
                width: '48%',
                height: '48%',
                background: 'radial-gradient(circle at 30% 30%, rgba(95, 130, 95, 0.8), rgba(60, 95, 70, 0.6))',
                transform: `scale(${isInhaling || cur.key === 'hold' ? 1.18 : cur.key === 'out' ? 0.82 : 0.95})`,
                transitionDuration: `${cur.duration}s`,
              }}
            >
              <span
                key={step}
                className="serif text-base md:text-lg text-bone font-light tracking-wide animate-fade-in"
                style={{ animationDuration: '500ms' }}
              >
                {running ? cur.label : 'Begin'}
              </span>
            </div>
          </div>
        </div>

        {/* Phase hint */}
        <p
          key={`hint-${step}`}
          className="serif italic text-sm text-ink/55 text-center mt-4 mb-3 h-5 animate-fade-in"
          style={{ animationDuration: '500ms' }}
        >
          {running ? cur.hint : 'Inhale 4 · Hold 4 · Exhale 4 · Rest 2'}
        </p>

        {/* Phase chips (4 dots) */}
        <div className="flex items-center justify-center gap-1.5 mb-5">
          {PHASES.map((p, i) => (
            <div
              key={p.key}
              className={`h-1 rounded-full transition-all duration-700 ${
                i === step
                  ? 'w-8 bg-sage-500'
                  : i < step && running
                  ? 'w-4 bg-sage-300'
                  : 'w-4 bg-ink/15'
              }`}
            />
          ))}
        </div>

        {/* Control button */}
        <div className="flex items-center justify-center gap-3">
          <button
            onClick={() => setRunning(r => !r)}
            className={`inline-flex items-center gap-2 px-5 py-2.5 rounded-full text-sm transition-all ${
              running
                ? 'bg-paper border border-ink/15 text-ink/80 hover:border-ink/30'
                : 'bg-ink text-bone hover:bg-ink/85 hover:scale-[1.02]'
            }`}
            aria-label={running ? 'Pause breath' : 'Begin breath'}
          >
            {running ? <Pause size={14} /> : <Play size={14} className="ml-0.5" />}
            <span>{running ? 'Pause' : 'Begin'}</span>
          </button>
          <Link
            href="/breathe"
            className="text-xs text-ink/50 hover:text-ink underline underline-offset-4"
          >
            Try other patterns
          </Link>
        </div>
      </div>
    </div>
  );
}