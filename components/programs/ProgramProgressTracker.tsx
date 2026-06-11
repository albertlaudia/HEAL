'use client';

import { useEffect, useState } from 'react';
import { getProgramProgress, type ProgramProgressState } from '@/lib/programs-client';

export function ProgramProgressTracker({
  programSlug,
  totalSteps,
  accent,
}: {
  programSlug: string;
  totalSteps: number;
  accent: string;
}) {
  const [state, setState] = useState<ProgramProgressState>({
    started: false,
    completed: false,
    completedSteps: [],
    currentStep: 1,
    completedAt: null,
  });
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    getProgramProgress(programSlug).then(setState).catch(() => {});
  }, [programSlug]);

  if (!hydrated || !state.started) {
    return (
      <div className="mb-8 p-5 rounded-2xl border border-dashed border-ink/10 bg-bone/30 text-sm text-ink/55 italic">
        Sign in to save your progress. Otherwise, your steps will be remembered only on this device.
      </div>
    );
  }

  const pct = Math.round((state.completedSteps.length / totalSteps) * 100);
  return (
    <div className={`mb-8 p-5 rounded-2xl border ${state.completed ? 'border-sage-200 bg-sage-50/50' : 'border-ink/10 bg-bone/60'}`}>
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-xs tracking-[0.2em] uppercase text-ink/50 mb-1">Your progress</p>
          <p className="text-ink/80">
            {state.completed ? (
              <>✨ You completed this program. The badge is yours.</>
            ) : (
              <>Step {state.currentStep} of {totalSteps} <span className="text-ink/50">— keep going, gently</span></>
            )}
          </p>
        </div>
        <div className="text-right">
          <span className={`serif text-2xl ${accent}`}>{pct}%</span>
        </div>
      </div>
      <div className="mt-3 h-1.5 bg-ink/5 rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full ${state.completed ? 'bg-sage-500' : 'bg-sage-400'} transition-all`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}
