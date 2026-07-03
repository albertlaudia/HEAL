import { notFound } from 'next/navigation';
import Link from 'next/link';
import { getProgramBySlug, getProgramStep, getProgramSteps, getAllPrograms, type HEALProgram, type HEALProgramStep } from '@/lib/pb';
import { StepReflection } from '@/components/programs/StepReflection';
import { StepNavigation } from '@/components/programs/StepNavigation';
import { ArrowLeft } from 'lucide-react';

export const revalidate = 3600;
export const dynamicParams = true;

export async function generateStaticParams() {
  return [];
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string; stepId: string }> }) {
  const { slug, stepId } = await params;
  const program = await getProgramBySlug(slug);
  const step = await getProgramStep(slug, parseInt(stepId, 10));
  if (!program || !step) return { title: 'Step not found' };
  return {
    title: `${step.title} · ${program.title}`,
    description: step.reflection?.slice(0, 160),
  };
}

const themeColors: Record<string, string> = {
  rose: 'text-rose-700',
  teal: 'text-teal-700',
  amber: 'text-amber-700',
  sage: 'text-sage-700',
  indigo: 'text-indigo-700',
  'muted-blue': 'text-sky-700',
  'warm-cream': 'text-orange-800',
};

const practiceLinks: Record<string, string> = {
  breath: '/breathe',
  meditation: '/meditate',
  prayer: '/prayers',
  praise: '/praise',
  scripture: '/scripture',
};

export default async function StepPage({ params }: { params: Promise<{ slug: string; stepId: string }> }) {
  const { slug, stepId } = await params;
  const order = parseInt(stepId, 10);
  if (Number.isNaN(order)) notFound();
  const program = await getProgramBySlug<HEALProgram>(slug);
  if (!program) notFound();
  const step = await getProgramStep<HEALProgramStep>(slug, order);
  if (!step) notFound();
  const allSteps = await getProgramSteps<HEALProgramStep>(slug);
  const accent = themeColors[program.theme_color] || 'text-sage-700';

  const prevStep = order > 1 ? allSteps.find((s) => s.order_index === order - 1) : null;
  const nextStep = allSteps.find((s) => s.order_index === order + 1);

  return (
    <div className="container-quiet py-12 md:py-16 max-w-3xl">
      <Link href={`/programs/${slug}`} className="inline-flex items-center gap-2 text-sm text-ink/60 hover:text-ink mb-6">
        <ArrowLeft size={14} />
        Back to {program.title}
      </Link>

      <header className="mb-10">
        <div className="flex items-center gap-3 text-xs tracking-[0.2em] uppercase text-ink/50 mb-3">
          <span>{program.title}</span>
          <span>·</span>
          <span>Step {order} of {allSteps.length}</span>
        </div>
        <h1 className="serif text-4xl md:text-5xl leading-tight">{step.title}</h1>
      </header>

      <StepReflection
        programSlug={slug}
        stepIndex={order}
        totalSteps={allSteps.length}
        accent={accent}
        step={step}
      />

      <StepNavigation
        programSlug={slug}
        programTitle={program.title}
        prevStep={prevStep ? { order_index: prevStep.order_index, title: prevStep.title } : null}
        nextStep={nextStep ? { order_index: nextStep.order_index, title: nextStep.title } : null}
        accent={accent}
      />
    </div>
  );
}

export { practiceLinks };
