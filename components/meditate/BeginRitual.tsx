'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { Pause, Wind, BookOpen, Sparkles, X, Play, ChevronRight } from 'lucide-react';

type Step = 'halt' | 'exhale' | 'align' | 'ready' | 'done';

const STEPS: { key: Step; letter: string; word: string; body: string; duration: number; }[] = [
  { key: 'halt',   letter: 'H', word: 'Halt',   body: 'Pause. Set the phone face-down. Let the room be still.', duration: 6 },
  { key: 'exhale', letter: 'E', word: 'Exhale', body: 'Breathe in 4. Hold 4. Out 4. Hold 2. Twice.', duration: 28 },
  { key: 'align',  letter: 'A', word: 'Align',  body: 'Read the scripture below. Let the Word find the place it is meant for.', duration: 8 },
  { key: 'ready',  letter: 'L', word: 'Listen', body: 'When you are ready, press play. There is no rush.', duration: 0 },
];

export function BeginRitual({
  scriptureRef,
  scriptureText,
  onComplete,
  onSkip,
}: {
  scriptureRef?: string;
  scriptureText?: string;
  onComplete: () => void;
  onSkip: () => void;
}) {
  const [stepIdx, setStepIdx] = useState(0);
  const [elapsed, setElapsed] = useState(0);
  const [breathPhase, setBreathPhase] = useState<'in' | 'hold' | 'out' | 'pause'>('in');
  const [breathCycle, setBreathCycle] = useState(0);
  const [ready, setReady] = useState(false);
  const totalBreathElapsed = useRef(0);

  const cur = STEPS[stepIdx];

  // Auto-advance timer
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

  // Breath phase tracker (only during exhale step)
  useEffect(() => {
    if (cur.key !== 'exhale') return;
    const phases = [
      { p: 'in' as const, d: 4 },
      { p: 'hold' as const, d: 4 },
      { p: 'out' as const, d: 4 },
      { p: 'pause' as const, d: 2 },
    ];
    const cycleLen = phases.reduce((s, x) => s + x.d, 0);
    const i = setInterval(() => {
      totalBreathElapsed.current += 0.1;
      const inCycle = totalBreathElapsed.current % cycleLen;
      let acc = 0;
      for (const ph of phases) {
        if (inCycle < acc + ph.d) {
          setBreathPhase(ph.p);
          break;
        }
        acc += ph.d;
      }
      setBreathCycle(Math.floor(totalBreathElapsed.current / cycleLen));
    }, 100);
    return () => {
      clearInterval(i);
      totalBreathElapsed.current = 0;
    };
  }, [cur.key]);

  const next = useCallback(() => {
    if (stepIdx < STEPS.length - 1) {
      setStepIdx(s => s + 1);
      setElapsed(0);
    }
  }, [stepIdx]);

  const skip = () => {
    onSkip();
  };

  return (
    <div className="fixed inset-0 z-50 bg-bone/95 backdrop-blur-md flex items-center justify-center p-6 animate-fade-in">
      <div className="max-w-xl w-full text-center relative">
        {/* Close / skip */}
        <button
          onClick={skip}
          className="absolute -top-4 -right-4 md:top-0 md:right-0 p-2 text-ink/40 hover:text-ink/70"
          aria-label="Skip ritual and begin"
          title="Skip ritual"
        >
          <X size={18} />
        </button>

        {/* Step indicator */}
        <div className="flex items-center justify-center gap-1.5 mb-12">
          {STEPS.map((s, i) => (
            <div
              key={s.key}
              className={`h-1 rounded-full transition-all duration-700 ${
                i === stepIdx ? 'w-8 bg-sage-600' : i < stepIdx ? 'w-4 bg-sage-400' : 'w-4 bg-ink/15'
              }`}
            />
          ))}
        </div>

        {/* The big letter */}
        <div className="mb-8 animate-fade-in" key={cur.key}>
          <p className="serif text-7xl md:text-8xl text-sage-700 leading-none mb-2 font-light">
            {cur.letter}
          </p>
          <p className="text-xs tracking-[0.3em] uppercase text-ink/50">
            {cur.word}
          </p>
        </div>

        {/* Step body */}
        <div className="min-h-[120px] mb-8">
          {cur.key === 'exhale' ? (
            <div className="space-y-4">
              <div className="relative w-40 h-40 mx-auto">
                <div
                  className="absolute inset-0 rounded-full bg-gradient-to-br from-sage-200 to-sage-400 transition-transform ease-in-out"
                  style={{
                    transform: `scale(${breathPhase === 'in' || breathPhase === 'hold' ? 1.4 : 0.8})`,
                    transitionDuration: `${breathPhase === 'in' ? 4 : breathPhase === 'out' ? 4 : 0.5}s`,
                    opacity: 0.35,
                  }}
                />
                <div
                  className="absolute inset-6 rounded-full bg-gradient-to-br from-sage-300 to-sage-500 transition-transform ease-in-out"
                  style={{
                    transform: `scale(${breathPhase === 'in' || breathPhase === 'hold' ? 1.4 : 0.8})`,
                    transitionDuration: `${breathPhase === 'in' ? 4 : breathPhase === 'out' ? 4 : 0.5}s`,
                    opacity: 0.5,
                  }}
                />
                <div
                  className="absolute inset-12 rounded-full bg-gradient-to-br from-sage-400 to-sage-600 transition-transform ease-in-out flex items-center justify-center"
                  style={{
                    transform: `scale(${breathPhase === 'in' || breathPhase === 'hold' ? 1.4 : 0.8})`,
                    transitionDuration: `${breathPhase === 'in' ? 4 : breathPhase === 'out' ? 4 : 0.5}s`,
                  }}
                >
                  <span className="serif text-bone text-base font-light">
                    {breathPhase === 'in' ? 'In' : breathPhase === 'hold' ? 'Hold' : breathPhase === 'out' ? 'Out' : 'Rest'}
                  </span>
                </div>
              </div>
              <p className="text-sm text-ink/60">
                {breathCycle < 2 ? `Cycle ${breathCycle + 1} of 2` : 'Almost there'}
              </p>
            </div>
          ) : cur.key === 'align' ? (
            <div className="space-y-4 max-w-md mx-auto">
              {scriptureText ? (
                <>
                  <blockquote className="serif italic text-xl leading-relaxed text-ink/85">
                    "{scriptureText}"
                  </blockquote>
                  {scriptureRef && (
                    <p className="text-xs tracking-widest uppercase text-ink/40">
                      — {scriptureRef}
                    </p>
                  )}
                </>
              ) : (
                <p className="serif italic text-lg text-ink/65">{cur.body}</p>
              )}
            </div>
          ) : cur.key === 'ready' ? (
            <div className="space-y-6">
              <p className="serif italic text-xl text-ink/65">{cur.body}</p>
              <button
                onClick={onComplete}
                className="btn-primary mx-auto animate-fade-in"
                style={{ animationDelay: '300ms' }}
              >
                <Play size={16} className="ml-0.5" />
                Begin meditation
                <ChevronRight size={16} />
              </button>
              <p className="text-xs text-ink/40">
                Or just <button onClick={onSkip} className="underline">start now</button>
              </p>
            </div>
          ) : (
            <p className="serif italic text-lg text-ink/65 max-w-sm mx-auto leading-relaxed">
              {cur.body}
            </p>
          )}
        </div>

        {/* Skip / next controls (only for non-ready steps) */}
        {cur.key !== 'ready' && (
          <div className="space-y-4">
            {/* Progress dots for timed steps */}
            {cur.duration > 0 && (
              <div className="flex items-center justify-center gap-1">
                {Array.from({ length: Math.ceil(cur.duration / 2) }).map((_, i) => (
                  <div
                    key={i}
                    className={`w-1.5 h-1.5 rounded-full transition-colors ${
                      elapsed > (i * 2) ? 'bg-sage-500' : 'bg-ink/15'
                    }`}
                  />
                ))}
              </div>
            )}
            <button
              onClick={next}
              className="text-sm text-ink/50 hover:text-ink underline underline-offset-4"
            >
              Skip this step
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
