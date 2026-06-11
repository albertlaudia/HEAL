'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { ArrowRight, Check } from 'lucide-react';
import { getProgramProgress, markStepComplete, type BadgeRecord } from '@/lib/programs-client';
import type { HEALProgramStep } from '@/lib/pb';

const practiceLinks: Record<string, string> = {
  breath: '/breathe',
  meditation: '/meditate',
  prayer: '/prayers',
  praise: '/praise',
  scripture: '/scripture',
};

export function StepReflection({
  programSlug,
  stepIndex,
  totalSteps,
  accent,
  step,
}: {
  programSlug: string;
  stepIndex: number;
  totalSteps: number;
  accent: string;
  step: HEALProgramStep;
}) {
  const [completed, setCompleted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [badgeEarned, setBadgeEarned] = useState<BadgeRecord | null>(null);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    getProgramProgress(programSlug).then((p) => {
      setCompleted(p.completedSteps.includes(stepIndex));
    });
  }, [programSlug, stepIndex]);

  const handleMarkComplete = async () => {
    setLoading(true);
    try {
      const result = await markStepComplete(programSlug, stepIndex, totalSteps);
      setCompleted(true);
      if (result.newBadgeEarned) {
        try {
          const res = await fetch(`/api/programs/${programSlug}/badge`);
          if (res.ok) {
            const b = await res.json();
            setBadgeEarned({
              programSlug,
              name: b.name,
              affirmation: b.affirmation,
              scriptureRef: b.scriptureRef,
              scriptureText: b.scriptureText,
              imagePath: b.imagePath,
              earnedAt: new Date().toISOString(),
            });
          }
        } catch {}
      }
    } catch (e) {
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <article className="space-y-8">
        <section>
          <p className="text-ink/80 leading-relaxed text-lg">{step.reflection}</p>
        </section>

        {step.scripture_ref && (
          <section className="card-quiet p-6 md:p-8">
            <p className="text-xs tracking-[0.2em] uppercase text-ink/50 mb-2">Scripture</p>
            <p className={`serif italic text-xl leading-relaxed ${accent}`}>
              "{step.scripture_text}"
            </p>
            <p className={`mt-3 text-sm font-medium ${accent}`}>— {step.scripture_ref}</p>
          </section>
        )}

        {step.practice_kind && step.practice_kind !== 'none' && (
          <section className="card-quiet p-6">
            <p className="text-xs tracking-[0.2em] uppercase text-ink/50 mb-2">Practice</p>
            <h3 className="serif text-2xl text-ink mb-2">{step.practice_title}</h3>
            <p className="text-sm text-ink/60 mb-4">
              This step pairs with a practice on the platform. Take five or ten minutes with it before you mark this step complete.
            </p>
            <Link
              href={
                step.practice_slug
                  ? (practiceLinks[step.practice_kind] || '/breathe') + '/' + step.practice_slug
                  : practiceLinks[step.practice_kind] || '/'
              }
              className={`inline-flex items-center gap-2 text-sm font-medium ${accent} hover:underline underline-offset-4`}
            >
              Open the practice
              <ArrowRight size={14} />
            </Link>
          </section>
        )}
      </article>

      <div className="mt-12 pt-8 border-t border-ink/10">
        {!hydrated ? (
          <div className="animate-pulse h-32 rounded-2xl bg-ink/5" />
        ) : completed ? (
          <div className="card-quiet p-8 border-2 border-sage-200 bg-sage-50/40">
            <div className="flex items-center gap-2 text-sage-700 text-xs tracking-[0.2em] uppercase font-medium mb-3">
              <Check size={14} />
              Step {stepIndex} complete
            </div>
            <h2 className={`serif text-3xl ${accent} mb-3`}>
              {step.response_headline}
            </h2>
            <p className="text-ink/75 leading-relaxed mb-5">
              {step.response_body}
            </p>
            {step.response_scripture && (
              <div className="pt-4 border-t border-sage-200/50">
                <p className={`text-sm italic ${accent}`}>"{step.response_scripture}"</p>
                <p className={`text-xs mt-1 ${accent}`}>— {step.scripture_ref}</p>
              </div>
            )}
          </div>
        ) : (
          <button
            onClick={handleMarkComplete}
            disabled={loading}
            className="w-full p-6 rounded-2xl border-2 border-dashed border-ink/15 hover:border-sage-400 hover:bg-sage-50/30 transition-all text-ink/70 hover:text-sage-800 group disabled:opacity-50"
          >
            <div className="flex items-center justify-center gap-3">
              <Check size={20} className="opacity-50 group-hover:opacity-100" />
              <span className="text-lg">{loading ? 'Marking…' : 'I have sat with this step'}</span>
            </div>
            <p className="text-xs text-ink/50 mt-2 group-hover:text-sage-700/70">
              Mark this step as complete when you are ready
            </p>
          </button>
        )}
      </div>

      {badgeEarned && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6 bg-ink/30 backdrop-blur-sm">
          <div className="card-quiet max-w-md w-full p-8 text-center bg-bone">
            <div className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Badge earned</div>
            <h2 className={`serif text-4xl ${accent} mb-3`}>{badgeEarned.name}</h2>
            {badgeEarned.imagePath && (
              <div className="aspect-square w-32 mx-auto mb-4 rounded-full overflow-hidden bg-cream-100 flex items-center justify-center">
                <img
                  src={badgeEarned.imagePath}
                  alt={badgeEarned.name}
                  className="w-full h-full object-contain p-2"
                />
              </div>
            )}
            <p className="serif italic text-lg text-ink/80 leading-relaxed mb-4">
              "{badgeEarned.affirmation}"
            </p>
            {badgeEarned.scriptureRef && (
              <div className="pt-4 border-t border-ink/10">
                <p className={`text-sm italic ${accent} leading-relaxed`}>"{badgeEarned.scriptureText}"</p>
                <p className={`text-xs mt-1 ${accent}`}>— {badgeEarned.scriptureRef}</p>
              </div>
            )}
            <div className="mt-6 flex flex-col sm:flex-row gap-3 justify-center">
              <Link
                href="/badges"
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-full bg-sage-600 text-bone hover:bg-sage-700 transition-colors text-sm"
              >
                See your badge collection →
              </Link>
              <button
                onClick={() => setBadgeEarned(null)}
                className="inline-flex items-center justify-center px-5 py-2.5 rounded-full border border-ink/15 text-ink/70 hover:border-ink/30 text-sm"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
