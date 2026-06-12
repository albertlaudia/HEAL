'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import Link from 'next/link';
import { Pause, Wind, BookOpen, Sparkles, X, ChevronRight, ChevronLeft } from 'lucide-react';

type Step = 'halt' | 'exhale' | 'align' | 'listen';
const STEPS: { key: Step; letter: string; word: string; body: string; icon: any; color: string; duration: number; }[] = [
  { key: 'halt',   letter: 'H', word: 'Halt',   body: 'Stop. Set the phone face-down. Close the eyes if you can. Let the room be still for a moment.', icon: Pause, color: 'text-amber-700', duration: 8 },
  { key: 'exhale', letter: 'E', word: 'Exhale', body: 'Breathe in 4. Hold 4. Out 4. Hold 2. Once is enough. Twice is grace.', icon: Wind, color: 'text-cyan-700', duration: 14 },
  { key: 'align',  letter: 'A', word: 'Align',  body: 'Read the word. Let it find the place it is meant for. There is no rush.', icon: BookOpen, color: 'text-sage-700', duration: 8 },
  { key: 'listen', letter: 'L', word: 'Listen', body: 'Sit in the silence for a few breaths. Notice what is there. When you are ready, return to the day.', icon: Sparkles, color: 'text-indigo-700', duration: 12 },
];

const SCRIPTURE = 'Be still, and know that I am God.';
const SCRIPTURE_REF = 'Psalm 46:10';

export default function NowPage() {
  const [stepIdx, setStepIdx] = useState(0);
  const [elapsed, setElapsed] = useState(0);
  const [breathPhase, setBreathPhase] = useState<'in' | 'hold' | 'out' | 'pause'>('in');
  const breathElapsed = useRef(0);
  const cur = STEPS[stepIdx];
  const Icon = cur.icon;
  const totalDuration = STEPS.reduce((s, x) => s + x.duration, 0);
  const totalElapsed = STEPS.slice(0, stepIdx).reduce((s, x) => s + x.duration, 0) + elapsed;

  useEffect(() => {
    if (cur.duration === 0) return;
    const start = Date.now();
    const i = setInterval(() => {
      const e = (Date.now() - start) / 1000;
      setElapsed(e);
      if (e >= cur.duration) {
        clearInterval(i);
        if (stepIdx < STEPS.length - 1) {
          setStepIdx(s => s + 1);
          setElapsed(0);
        }
      }
    }, 100);
    return () => clearInterval(i);
  }, [stepIdx, cur.duration]);

  useEffect(() => {
    if (cur.key !== 'exhale') return;
    const phases = [
      { p: 'in' as const, d: 4 },
      { p: 'hold' as const, d: 4 },
      { p: 'out' as const, d: 4 },
      { p: 'pause' as const, d: 2 },
    ];
    const cycleLen = phases.reduce((s, x) => s + x.d, 0);
    breathElapsed.current = 0;
    const i = setInterval(() => {
      breathElapsed.current += 0.1;
      const inCycle = breathElapsed.current % cycleLen;
      let acc = 0;
      for (const ph of phases) {
        if (inCycle < acc + ph.d) {
          setBreathPhase(ph.p);
          break;
        }
        acc += ph.d;
      }
    }, 100);
    return () => clearInterval(i);
  }, [cur.key]);

  const next = useCallback(() => {
    if (stepIdx < STEPS.length - 1) {
      setStepIdx(s => s + 1);
      setElapsed(0);
    }
  }, [stepIdx]);

  const prev = useCallback(() => {
    if (stepIdx > 0) {
      setStepIdx(s => s - 1);
      setElapsed(0);
    }
  }, [stepIdx]);

  const isFinal = stepIdx === STEPS.length - 1 && elapsed >= cur.duration;
  const stepPct = (elapsed / cur.duration) * 100;
  const totalPct = (totalElapsed / totalDuration) * 100;

  return (
    <div className="min-h-screen bg-bone flex flex-col">
      {/* Header */}
      <div className="container-wide pt-8 pb-2 flex items-center justify-between">
        <Link href="/" className="text-xs tracking-[0.3em] uppercase text-ink/50 hover:text-ink/80">
          ← Exit
        </Link>
        <p className="text-xs tracking-[0.3em] uppercase text-ink/40">
          H.E.A.L. · ~{totalDuration} sec
        </p>
        <div className="w-12" />
      </div>

      {/* Progress bar across all steps */}
      <div className="px-6">
        <div className="max-w-2xl mx-auto h-0.5 bg-ink/8 rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-amber-400 via-cyan-400 via-sage-500 to-indigo-500 transition-all duration-300"
            style={{ width: `${totalPct}%` }}
          />
        </div>
      </div>

      {/* Step dots */}
      <div className="flex items-center justify-center gap-2 pt-4">
        {STEPS.map((s, i) => (
          <div
            key={s.key}
            className={`flex items-center gap-1.5 px-2 py-1 rounded-full transition-all duration-500 ${
              i === stepIdx ? `${s.color} bg-ink/5` : i < stepIdx ? 'text-ink/40' : 'text-ink/25'
            }`}
          >
            <span className={`serif text-base ${i === stepIdx ? s.color : ''}`}>{s.letter}</span>
            <span className="text-[10px] tracking-widest uppercase hidden sm:inline">{s.word}</span>
          </div>
        ))}
      </div>

      {/* Main content */}
      <main className="flex-1 flex items-center justify-center px-6 py-8">
        <div className="max-w-xl w-full text-center">
          <div key={cur.key} className="animate-fade-in">
            <div className="flex items-center justify-center gap-3 mb-6">
              <Icon size={20} className={cur.color} />
              <p className="text-xs tracking-[0.4em] uppercase text-ink/50">
                {cur.word}
              </p>
            </div>
            <p className={`serif text-7xl md:text-8xl leading-none font-light mb-8 ${cur.color}`}>
              {cur.letter}
            </p>
          </div>

          <div className="min-h-[180px] flex items-center justify-center">
            {cur.key === 'exhale' ? (
              <div className="space-y-6">
                <div className="relative w-40 h-40 mx-auto">
                  <div
                    className="absolute inset-0 rounded-full bg-gradient-to-br from-cyan-200 to-cyan-400 transition-transform ease-in-out"
                    style={{
                      transform: `scale(${breathPhase === 'in' || breathPhase === 'hold' ? 1.4 : 0.8})`,
                      transitionDuration: `${breathPhase === 'in' || breathPhase === 'out' ? 4 : 0.5}s`,
                      opacity: 0.35,
                    }}
                  />
                  <div
                    className="absolute inset-6 rounded-full bg-gradient-to-br from-cyan-300 to-cyan-500 transition-transform ease-in-out"
                    style={{
                      transform: `scale(${breathPhase === 'in' || breathPhase === 'hold' ? 1.4 : 0.8})`,
                      transitionDuration: `${breathPhase === 'in' || breathPhase === 'out' ? 4 : 0.5}s`,
                      opacity: 0.5,
                    }}
                  />
                  <div
                    className="absolute inset-12 rounded-full bg-gradient-to-br from-cyan-400 to-cyan-600 transition-transform ease-in-out flex items-center justify-center"
                    style={{
                      transform: `scale(${breathPhase === 'in' || breathPhase === 'hold' ? 1.4 : 0.8})`,
                      transitionDuration: `${breathPhase === 'in' || breathPhase === 'out' ? 4 : 0.5}s`,
                    }}
                  >
                    <span className="serif text-bone text-base font-light">
                      {breathPhase === 'in' ? 'In' : breathPhase === 'hold' ? 'Hold' : breathPhase === 'out' ? 'Out' : 'Rest'}
                    </span>
                  </div>
                </div>
                <p className="text-xs text-ink/50">
                  {breathPhase === 'in' && 'Breathe in...'}
                  {breathPhase === 'hold' && 'Hold...'}
                  {breathPhase === 'out' && 'Breathe out...'}
                  {breathPhase === 'pause' && 'Rest...'}
                </p>
              </div>
            ) : cur.key === 'align' ? (
              <div className="space-y-3 max-w-md mx-auto">
                <blockquote className="serif italic text-2xl leading-relaxed text-ink/85">
                  "{SCRIPTURE}"
                </blockquote>
                <p className="text-xs tracking-widest uppercase text-ink/40">— {SCRIPTURE_REF}</p>
              </div>
            ) : cur.key === 'listen' ? (
              <div className="space-y-4">
                <p className="serif italic text-lg text-ink/65 max-w-md mx-auto leading-relaxed">
                  {cur.body}
                </p>
                {isFinal && (
                  <div className="pt-6 animate-fade-in">
                    <p className="text-xs tracking-widest uppercase text-sage-700 mb-3">You have returned.</p>
                    <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
                      <Link href="/" className="btn-primary">
                        Back to today
                        <ChevronRight size={16} />
                      </Link>
                      <Link href="/journal" className="btn-ghost text-sm">
                        Write it down
                      </Link>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <p className="serif italic text-lg text-ink/65 max-w-sm mx-auto leading-relaxed">
                {cur.body}
              </p>
            )}
          </div>

          {/* Step progress */}
          {cur.duration > 0 && !isFinal && (
            <div className="mt-8 max-w-xs mx-auto">
              <div className="h-0.5 bg-ink/8 rounded-full overflow-hidden">
                <div
                  className={`h-full transition-all duration-100 ${cur.color.replace('text', 'bg')}`}
                  style={{ width: `${stepPct}%` }}
                />
              </div>
              <p className="text-[10px] tracking-widest uppercase text-ink/40 mt-2 tabular-nums">
                {Math.max(0, Math.ceil(cur.duration - elapsed))} sec
              </p>
            </div>
          )}

          {/* Step controls */}
          <div className="mt-10 flex items-center justify-center gap-3">
            {stepIdx > 0 && (
              <button
                onClick={prev}
                className="text-sm text-ink/50 hover:text-ink underline underline-offset-4 inline-flex items-center gap-1"
              >
                <ChevronLeft size={12} />
                Previous
              </button>
            )}
            {stepIdx < STEPS.length - 1 && (
              <button
                onClick={next}
                className="text-sm text-ink/50 hover:text-ink underline underline-offset-4 inline-flex items-center gap-1"
              >
                Skip step
                <ChevronRight size={12} />
              </button>
            )}
          </div>
        </div>
      </main>

      {/* Footer note */}
      <div className="container-wide py-6 text-center text-[10px] tracking-widest uppercase text-ink/30">
        A small practice · Be still. Breathe. Begin again.
      </div>
    </div>
  );
}
