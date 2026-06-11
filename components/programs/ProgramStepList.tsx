'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { ChevronRight } from 'lucide-react';
import { getProgramProgress, type ProgramProgressState } from '@/lib/programs-client';
import type { HEALProgramStep } from '@/lib/pb';

export function ProgramStepList({
  programSlug,
  steps,
  accent,
}: {
  programSlug: string;
  steps: HEALProgramStep[];
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

  const completedSet = new Set(state.completedSteps);
  const nextUnlocked = !state.completed
    ? state.completedSteps.length + 1
    : steps.length + 1;

  return (
    <ol className="space-y-3">
      {steps.map((step, i) => {
        const isComplete = completedSet.has(step.order_index);
        const isUnlocked = step.order_index <= nextUnlocked;
        const isCurrent = !state.completed && state.completedSteps.length + 1 === step.order_index;
        const stepAccent = isCurrent ? accent.replace('text-', 'bg-').replace('-700', '-100') : 'bg-ink/5';
        return (
          <li key={step.id} className="group">
            <Link
              href={isUnlocked ? `/programs/${programSlug}/${step.order_index}` : '#'}
              aria-disabled={!isUnlocked}
              onClick={(e) => { if (!isUnlocked) e.preventDefault(); }}
              className={`
                flex items-start gap-4 p-5 rounded-2xl border transition-all
                ${isComplete ? 'border-sage-200 bg-sage-50/30' : isCurrent ? 'border-ink/20 bg-bone' : 'border-ink/10 bg-bone/60'}
                ${isUnlocked ? 'hover:border-ink/30 hover:-translate-y-0.5 cursor-pointer' : 'opacity-50 cursor-not-allowed'}
              `}
            >
              <div className={`
                shrink-0 w-9 h-9 rounded-full flex items-center justify-center text-sm font-medium
                ${isComplete ? 'bg-sage-200 text-sage-800' : isCurrent ? `${stepAccent} ${accent}` : 'bg-ink/5 text-ink/40'}
              `}>
                {isComplete ? '✓' : i + 1}
              </div>
              <div className="flex-1 min-w-0">
                <h3 className={`serif text-lg mb-1 ${isComplete ? 'text-ink/70' : 'text-ink'}`}>
                  {step.title}
                </h3>
                <p className="text-sm text-ink/55 line-clamp-2">{step.reflection}</p>
                {step.scripture_ref && (
                  <p className={`mt-2 text-xs italic ${accent}`}>— {step.scripture_ref}</p>
                )}
              </div>
              {isUnlocked && (
                <ChevronRight
                  size={18}
                  className={`shrink-0 mt-1 ${isComplete ? 'text-sage-600' : 'text-ink/30 group-hover:text-ink/60'} transition-colors`}
                />
              )}
            </Link>
          </li>
        );
      })}
    </ol>
  );
}
