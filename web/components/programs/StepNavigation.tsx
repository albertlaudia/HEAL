'use client';

import Link from 'next/link';
import { ArrowLeft, ArrowRight } from 'lucide-react';

export function StepNavigation({
  programSlug,
  programTitle,
  prevStep,
  nextStep,
  accent,
}: {
  programSlug: string;
  programTitle: string;
  prevStep: { order_index: number; title: string } | null;
  nextStep: { order_index: number; title: string } | null;
  accent: string;
}) {
  return (
    <div className="mt-8 flex items-center justify-between">
      {prevStep ? (
        <Link
          href={`/programs/${programSlug}/${prevStep.order_index}`}
          className="inline-flex items-center gap-2 text-sm text-ink/60 hover:text-ink"
        >
          <ArrowLeft size={14} />
          Step {prevStep.order_index}: {prevStep.title}
        </Link>
      ) : <span />}
      {nextStep ? (
        <Link
          href={`/programs/${programSlug}/${nextStep.order_index}`}
          className={`inline-flex items-center gap-2 text-sm font-medium ${accent} hover:underline`}
        >
          Step {nextStep.order_index}: {nextStep.title}
          <ArrowRight size={14} />
        </Link>
      ) : (
        <Link
          href={`/programs/${programSlug}`}
          className={`inline-flex items-center gap-2 text-sm font-medium ${accent} hover:underline`}
        >
          Finish the program
          <ArrowRight size={14} />
        </Link>
      )}
    </div>
  );
}
