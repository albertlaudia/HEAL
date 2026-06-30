import Link from 'next/link';
import Image from 'next/image';
import { getAllPrograms } from '@/lib/pb';
import { ProgramCard } from '@/components/programs/ProgramCard';
import { Sparkles, ArrowRight } from 'lucide-react';

export const revalidate = 3600;

export const metadata = {
  title: 'Programs',
  description: 'Multi-step practices for the long, slow work of healing. A program is a series of reflections, practices, and scripture that you walk through at your own pace — and earn a badge when you finish.',
};

export default async function ProgramsPage() {
  const programs = await getAllPrograms();

  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Programs</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Multi-step practices</h1>
        <p className="text-ink/60 leading-relaxed text-lg">
          Most of what we offer is a single meditation, prayer, or breath. Sometimes the soul needs a longer walk. A program is a series of small reflections, scripture, and practices — taken one step at a time, at your own pace. There is no deadline. There is no test. When you finish, you earn a badge that reminds you, in a quiet way, of the work you have done.
        </p>
      </header>

      {programs.length === 0 ? (
        <div className="mt-12 text-center py-20 border border-dashed border-ink/10 rounded-2xl">
          <Sparkles className="mx-auto text-ink/30 mb-4" size={32} />
          <p className="serif text-2xl text-ink/40">Programs are being prepared.</p>
          <p className="mt-2 text-sm text-ink/50">New programs are added as they are written and reviewed.</p>
        </div>
      ) : (
        <div className="grid md:grid-cols-2 gap-6">
          {programs.map((p) => (
            <ProgramCard key={p.id} program={p} />
          ))}
        </div>
      )}

      <section className="mt-20 max-w-2xl">
        <h2 className="serif text-2xl text-ink mb-3">How programs work</h2>
        <ul className="space-y-3 text-ink/70 leading-relaxed">
          <li className="flex gap-3"><span className="text-sage-700 mt-1">●</span>Pick a program. Each one has between 6 and 10 small steps.</li>
          <li className="flex gap-3"><span className="text-sage-700 mt-1">●</span>Each step is a short reflection with a scripture and a practice (a breath, a meditation, a prayer).</li>
          <li className="flex gap-3"><span className="text-sage-700 mt-1">●</span>Move at your own pace. There is no deadline. Some people do a step a day. Some do one a week. Some do them all in a sitting.</li>
          <li className="flex gap-3"><span className="text-sage-700 mt-1">●</span>Your progress is saved to your account, so you can step away and return.</li>
          <li className="flex gap-3"><span className="text-sage-700 mt-1">●</span>When you finish all the steps, you earn a quiet badge. The badge has a name, an affirmation, and a verse. It is yours to keep.</li>
        </ul>
        <div className="mt-10 flex items-center gap-3 text-ink/60 text-sm">
          <Sparkles size={16} className="text-sage-600" />
          <span>You do not need an account to read the steps. An account is required to save progress and earn badges.</span>
        </div>
        <Link href="/badges" className="mt-6 inline-flex items-center gap-2 text-sage-700 hover:text-sage-800 underline underline-offset-4">
          See badges you can earn
          <ArrowRight size={14} />
        </Link>
      </section>
    </div>
  );
}
