'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { ArrowRight, Award } from 'lucide-react';
import { getProgramProgress, type ProgramProgressState } from '@/lib/programs-client';

type ProgramStub = {
  id: string;
  slug: string;
  title: string;
  step_count: number;
  theme_color: string;
  badge_name: string;
};

const themeColors: Record<string, string> = {
  rose: 'text-rose-700',
  teal: 'text-teal-700',
  amber: 'text-amber-700',
  sage: 'text-sage-700',
  indigo: 'text-indigo-700',
  'muted-blue': 'text-sky-700',
  'warm-cream': 'text-orange-800',
};

export function ContinueProgram() {
  const [candidates, setCandidates] = useState<{ program: ProgramStub; progress: ProgramProgressState }[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    // Read localStorage keys for any started program
    const found: { program: ProgramStub; progress: ProgramProgressState }[] = [];
    for (let i = 0; i < window.localStorage.length; i++) {
      const k = window.localStorage.key(i);
      if (k && k.startsWith('heal_program_')) {
        const slug = k.replace('heal_program_', '');
        try {
          const progress = JSON.parse(window.localStorage.getItem(k) || '{}');
          if (progress.started && !progress.completed) {
            found.push({ program: { id: slug, slug, title: slug, step_count: 0, theme_color: 'sage', badge_name: '' }, progress });
          }
        } catch {}
      }
    }
    if (found.length > 0) {
      // Fetch program metadata from PB
      Promise.all(
        found.map((c) =>
          fetch(`/api/programs/${c.program.slug}`).then((r) => r.json()).catch(() => null)
        )
      ).then((programs) => {
        const merged = found
          .map((c, i) => ({ ...c, program: programs[i] ? { ...c.program, ...programs[i] } : c.program }))
          .filter((c) => c.program.title && c.program.title !== c.program.slug)
          .sort((a, b) => (a.progress.completedAt || '') < (b.progress.completedAt || '') ? 1 : -1);
        setCandidates(merged);
      }).catch(() => {});
    }
  }, []);

  if (!hydrated || candidates.length === 0) return null;

  const top = candidates[0];
  const accent = themeColors[top.program.theme_color] || 'text-sage-700';
  const pct = Math.round((top.progress.completedSteps.length / top.program.step_count) * 100);
  const nextStep = top.progress.currentStep;

  return (
    <section className="my-12">
      <Link
        href={`/programs/${top.program.slug}/${nextStep}`}
        className="group block card-quiet p-6 md:p-8 hover:-translate-y-0.5 transition-transform"
      >
        <div className="flex items-start gap-4">
          <div className="shrink-0 w-12 h-12 rounded-full bg-sage-100 flex items-center justify-center">
            <Award className={`${accent}`} size={22} />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs tracking-[0.2em] uppercase text-ink/50 mb-1">Continue your practice</p>
            <h2 className={`serif text-2xl mb-2 ${accent} group-hover:underline underline-offset-4`}>
              {top.program.title}
            </h2>
            <p className="text-sm text-ink/65 mb-4">
              Step {top.progress.completedSteps.length} of {top.program.step_count} complete — keep going, gently
            </p>
            <div className="flex items-center gap-3">
              <div className="flex-1 h-1.5 bg-ink/5 rounded-full overflow-hidden">
                <div
                  className="h-full bg-sage-500 rounded-full transition-all"
                  style={{ width: `${pct}%` }}
                />
              </div>
              <span className={`text-sm font-medium ${accent}`}>{pct}%</span>
            </div>
            <div className="mt-4 inline-flex items-center gap-1 text-sm font-medium text-sage-700 group-hover:translate-x-0.5 transition-transform">
              Pick up where you left off
              <ArrowRight size={14} />
            </div>
          </div>
        </div>
      </Link>
    </section>
  );
}
