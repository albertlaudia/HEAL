import { notFound } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { getProgramBySlug, getProgramSteps, getAllPrograms, type HEALProgram, type HEALProgramStep } from '@/lib/pb';
import { ProgramProgressTracker } from '@/components/programs/ProgramProgressTracker';
import { ProgramStepList } from '@/components/programs/ProgramStepList';
import { Award, BookOpen, ArrowLeft } from 'lucide-react';

export const revalidate = 3600;

export async function generateStaticParams() {
  const programs = await getAllPrograms();
  return programs.map((p) => ({ slug: p.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const program = await getProgramBySlug(slug);
  if (!program) return { title: 'Program not found' };
  return {
    title: program.title,
    description: program.tagline,
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

export default async function ProgramDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const program = await getProgramBySlug<HEALProgram>(slug);
  if (!program) notFound();
  const steps = await getProgramSteps<HEALProgramStep>(slug);
  const accent = themeColors[program.theme_color] || 'text-sage-700';

  return (
    <div className="container-wide py-12 md:py-16">
      <Link href="/programs" className="inline-flex items-center gap-2 text-sm text-ink/60 hover:text-ink mb-8">
        <ArrowLeft size={14} />
        All programs
      </Link>

      <div className="grid lg:grid-cols-[1fr_320px] gap-12 items-start">
        <div>
          <header className="mb-10">
            <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Program</p>
            <h1 className="serif text-5xl md:text-6xl mb-3">{program.title}</h1>
            <p className={`serif italic text-xl ${accent} mb-6`}>{program.tagline}</p>
            <p className="text-ink/70 leading-relaxed text-lg max-w-2xl">
              {program.description}
            </p>
            <div className="mt-6 flex flex-wrap items-center gap-3 text-sm text-ink/60">
              <span className="inline-flex items-center gap-1.5">
                <BookOpen size={14} />
                {steps.length} steps
              </span>
              <span>·</span>
              <span>{program.duration_label}</span>
              {program.badge_name && (
                <>
                  <span>·</span>
                  <span className="inline-flex items-center gap-1.5">
                    <Award size={14} className={accent} />
                    Earns the <span className={`font-medium ${accent}`}>{program.badge_name}</span> badge
                  </span>
                </>
              )}
            </div>
          </header>

          <ProgramProgressTracker programSlug={program.slug} totalSteps={steps.length} accent={accent} />
          <ProgramStepList programSlug={program.slug} steps={steps} accent={accent} />
        </div>

        <aside className="lg:sticky lg:top-24 space-y-6">
          {program.badge_name && (
            <div className="card-quiet p-6">
              <div className="aspect-square rounded-2xl bg-gradient-to-br from-bone to-cream-100 flex items-center justify-center mb-4 overflow-hidden">
                {program.badge_image_path ? (
                  <Image
                    src={program.badge_image_path}
                    alt={program.badge_name}
                    width={200}
                    height={200}
                    className="object-contain p-4"
                  />
                ) : (
                  <Award className="text-sage-300" size={80} />
                )}
              </div>
              <p className="text-xs tracking-[0.25em] uppercase text-ink/50 mb-1">Badge</p>
              <h3 className={`serif text-xl mb-2 ${accent}`}>{program.badge_name}</h3>
              <p className="text-sm text-ink/70 italic leading-relaxed">
                "{program.badge_affirmation}"
              </p>
              {program.badge_scripture_ref && (
                <div className="mt-4 pt-4 border-t border-ink/5">
                  <p className={`text-sm font-medium ${accent}`}>{program.badge_scripture_ref}</p>
                  <p className="mt-1 text-sm text-ink/65 leading-relaxed">"{program.badge_scripture_text}"</p>
                </div>
              )}
            </div>
          )}

          <div className="card-quiet p-6 text-sm text-ink/65 leading-relaxed">
            <p className="font-medium text-ink mb-2">At your own pace</p>
            <p>
              There is no deadline for this program. Some people do a step a day. Some do one a week. Some sit down on a Sunday morning and walk through three or four at a time. Move at the pace of your own life.
            </p>
          </div>
        </aside>
      </div>
    </div>
  );
}
