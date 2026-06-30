'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import Link from 'next/link';
import { Pause, Wind, BookOpen, Sparkles, X, ChevronRight, ChevronLeft, Check } from 'lucide-react';

type Step = 'halt' | 'exhale' | 'align' | 'listen';
const STEPS: { key: Step; letter: string; word: string; body: string; icon: any; color: string; bgGradient: string; ringColor: string; duration: number; }[] = [
  { key: 'halt',   letter: 'H', word: 'Halt',   body: 'Stop. Set the phone face-down. Close the eyes if you can. Let the room be still for a moment.', icon: Pause, color: 'text-amber-700', bgGradient: 'from-amber-50 to-amber-100/40', ringColor: 'bg-amber-500', duration: 8 },
  { key: 'exhale', letter: 'E', word: 'Exhale', body: 'Breathe in 4. Hold 4. Out 4. Hold 2. Once is enough. Twice is grace.', icon: Wind, color: 'text-cyan-700', bgGradient: 'from-cyan-50 to-cyan-100/40', ringColor: 'bg-cyan-500', duration: 14 },
  { key: 'align',  letter: 'A', word: 'Align',  body: 'Read the word. Let it find the place it is meant for. There is no rush.', icon: BookOpen, color: 'text-sage-700', bgGradient: 'from-sage-50 to-sage-100/40', ringColor: 'bg-sage-500', duration: 8 },
  { key: 'listen', letter: 'L', word: 'Listen', body: 'Sit in the silence for a few breaths. Notice what is there. When you are ready, return to the day.', icon: Sparkles, color: 'text-indigo-700', bgGradient: 'from-indigo-50 to-indigo-100/40', ringColor: 'bg-indigo-500', duration: 12 },
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
  const remainingInStep = Math.max(0, Math.ceil(cur.duration - elapsed));
  const totalRemaining = Math.max(0, Math.ceil(totalDuration - totalElapsed));

  return (
    <div className={`min-h-screen bg-gradient-to-b ${cur.bgGradient} flex flex-col transition-colors duration-1000`}>
      {/* Header */}
      <div className="container-wide pt-6 md:pt-8 pb-2 flex items-center justify-between">
        <Link href="/" className="text-xs tracking-[0.3em] uppercase text-ink/50 hover:text-ink/80 inline-flex items-center gap-1.5">
          <X size={14} />
          Exit
        </Link>
        <p className="text-[10px] md:text-xs tracking-[0.3em] uppercase text-ink/40">
          H.E.A.L. · ~<span className="tabular-nums">{totalDuration}</span> sec
        </p>
        <div className="w-12" />
      </div>

      {/* Step breadcrumb — 4 connected segments with labels */}
      <div className="px-6 pt-3">
        <div className="max-w-xl mx-auto">
          <div className="flex items-center gap-1.5 md:gap-2">
            {STEPS.map((s, i) => (
              <div key={s.key} className="flex-1 flex flex-col items-center">
                {/* segment dot + connector */}
                <div className="flex items-center w-full">
                  {i > 0 && (
                    <div className={`flex-1 h-px transition-colors duration-500 ${i <= stepIdx ? cur.ringColor.replace('bg-', 'bg-').replace('-500', '-300') : 'bg-ink/10'}`} />
                  )}
                  <div
                    className={`relative w-7 h-7 md:w-8 md:h-8 rounded-full flex items-center justify-center serif text-sm md:text-base transition-all duration-500 ${
                      i === stepIdx
                        ? `${s.color} bg-paper ring-2 ${s.ringColor.replace('bg-', 'ring-')} ring-offset-2 ring-offset-bone scale-110`
                        : i < stepIdx
                        ? `${s.color} bg-paper`
                        : 'text-ink/30 bg-ink/5'
                    }`}
                  >
                    {i < stepIdx ? <Check size={12} strokeWidth={3} /> : s.letter}
                  </div>
                  {i < STEPS.length - 1 && (
                    <div className={`flex-1 h-px transition-colors duration-500 ${i < stepIdx ? cur.ringColor.replace('bg-', 'bg-').replace('-500', '-300') : 'bg-ink/10'}`} />
                  )}
                </div>
                {/* label */}
                <span
                  className={`text-[9px] md:text-[10px] tracking-[0.2em] uppercase mt-1.5 transition-colors duration-500 ${
                    i === stepIdx ? 'text-ink/80 font-medium' : 'text-ink/35'
                  }`}
                >
                  {s.word}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Main content */}
      <main className="flex-1 flex items-center justify-center px-6 py-6 md:py-8">
        <div className="max-w-xl w-full text-center">
          <div key={cur.key} className="animate-fade-in">
            {/* Step label + icon */}
            <div className="flex items-center justify-center gap-2 mb-4 md:mb-6">
              <Icon size={16} className={cur.color} strokeWidth={1.5} />
              <p className={`text-[10px] md:text-xs tracking-[0.4em] uppercase ${cur.color}`}>
                Step {stepIdx + 1} of {STEPS.length} · {cur.word}
              </p>
            </div>

            {/* BIG H letter with breathing pulse ring */}
            <div className="relative w-40 h-40 md:w-52 md:h-52 mx-auto mb-6 md:mb-8">
              {/* soft outer halo */}
              <div
                className={`absolute inset-0 rounded-full opacity-25 blur-2xl ${cur.ringColor}`}
                style={{ animation: 'breathe-halo 6s ease-in-out infinite' }}
              />
              {/* the letter itself */}
              <div className="absolute inset-0 flex items-center justify-center">
                <span className={`serif text-7xl md:text-8xl leading-none font-light ${cur.color}`}>
                  {cur.letter}
                </span>
              </div>
            </div>

            {/* BIG countdown — the main UI element */}
            <div className="mb-2">
              <span className={`serif text-6xl md:text-7xl tabular-nums leading-none font-light ${cur.color}`}>
                {remainingInStep}
              </span>
              <span className="text-sm md:text-base text-ink/40 tracking-widest uppercase ml-2">
                sec
              </span>
            </div>
            {/* total remaining whisper */}
            <p className="text-[10px] tracking-[0.2em] uppercase text-ink/35 mb-6">
              ~{totalRemaining}s total left
            </p>
          </div>

          {/* Step-specific body */}
          <div className="min-h-[200px] md:min-h-[220px] flex items-center justify-center mb-4">
            {cur.key === 'exhale' ? (
              <div className="space-y-5">
                <div className="relative w-32 h-32 mx-auto">
                  <div
                    className="absolute inset-0 rounded-full bg-gradient-to-br from-cyan-200 to-cyan-400 transition-transform ease-in-out"
                    style={{
                      transform: `scale(${breathPhase === 'in' || breathPhase === 'hold' ? 1.5 : 0.7})`,
                      transitionDuration: `${breathPhase === 'in' || breathPhase === 'out' ? 4 : 0.5}s`,
                      opacity: 0.35,
                    }}
                  />
                  <div
                    className="absolute inset-3 rounded-full bg-gradient-to-br from-cyan-300 to-cyan-500 transition-transform ease-in-out flex items-center justify-center"
                    style={{
                      transform: `scale(${breathPhase === 'in' || breathPhase === 'hold' ? 1.5 : 0.7})`,
                      transitionDuration: `${breathPhase === 'in' || breathPhase === 'out' ? 4 : 0.5}s`,
                      opacity: 0.7,
                    }}
                  >
                    <span className="serif text-bone text-lg font-light">
                      {breathPhase === 'in' ? 'In' : breathPhase === 'hold' ? 'Hold' : breathPhase === 'out' ? 'Out' : 'Rest'}
                    </span>
                  </div>
                </div>
                <p className="text-sm text-ink/55 serif italic">
                  {breathPhase === 'in' && 'Breathe in...'}
                  {breathPhase === 'hold' && 'Hold...'}
                  {breathPhase === 'out' && 'Breathe out...'}
                  {breathPhase === 'pause' && 'Rest...'}
                </p>
              </div>
            ) : cur.key === 'align' ? (
              <div className="space-y-3 max-w-md mx-auto">
                <blockquote className="serif italic text-2xl md:text-3xl leading-snug text-ink/85">
                  "{SCRIPTURE}"
                </blockquote>
                <p className="text-xs tracking-widest uppercase text-ink/40">— {SCRIPTURE_REF}</p>
              </div>
            ) : cur.key === 'listen' ? (
              <div className="space-y-4">
                <p className="serif italic text-lg md:text-xl text-ink/70 max-w-md mx-auto leading-relaxed">
                  {cur.body}
                </p>
                {isFinal && (
                  <div className="pt-4 animate-fade-in">
                    <p className="text-xs tracking-widest uppercase text-sage-700 mb-4">You have returned.</p>
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
              <p className="serif italic text-lg md:text-xl text-ink/70 max-w-sm mx-auto leading-relaxed">
                {cur.body}
              </p>
            )}
          </div>

          {/* Step progress bar — visible */}
          {cur.duration > 0 && !isFinal && (
            <div className="mt-4 max-w-sm mx-auto">
              <div className="h-1.5 bg-ink/8 rounded-full overflow-hidden">
                <div
                  className={`h-full transition-all duration-100 ${cur.ringColor}`}
                  style={{ width: `${stepPct}%` }}
                />
              </div>
            </div>
          )}

          {/* Step controls — proper buttons */}
          <div className="mt-8 flex items-center justify-center gap-2">
            {stepIdx > 0 && (
              <button
                onClick={prev}
                className="inline-flex items-center gap-1 px-4 py-2 rounded-full text-xs text-ink/60 hover:text-ink hover:bg-ink/5 transition-colors"
                aria-label="Previous step"
              >
                <ChevronLeft size={14} />
                Previous
              </button>
            )}
            {stepIdx < STEPS.length - 1 && (
              <button
                onClick={next}
                className={`inline-flex items-center gap-1 px-4 py-2 rounded-full text-xs ${cur.color} hover:bg-ink/5 transition-colors`}
                aria-label="Skip to next step"
              >
                Skip step
                <ChevronRight size={14} />
              </button>
            )}
          </div>
        </div>
      </main>

      {/* Footer note */}
      <div className="container-wide py-6 text-center text-[10px] tracking-widest uppercase text-ink/30">
        A small practice · Be still. Breathe. Begin again.
      </div>

      <style jsx>{`
        @keyframes breathe-halo {
          0%, 100% { transform: scale(0.95); opacity: 0.25; }
          50%      { transform: scale(1.08); opacity: 0.40; }
        }
      `}</style>
    </div>
  );
}