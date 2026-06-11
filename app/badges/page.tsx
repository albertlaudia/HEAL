import { getAllPrograms } from '@/lib/pb';
import { BadgesFullPage } from '@/components/programs/BadgesFullPage';

export const revalidate = 3600;

export const metadata = {
  title: 'Badges',
  description: 'A quiet collection of the work you have done.',
};

export default async function BadgesPage() {
  const programs = await getAllPrograms();
  const available = programs.filter((p) => p.badge_name);

  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Your collection</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Badges</h1>
        <p className="text-ink/60 leading-relaxed text-lg">
          When you finish a program, you earn a quiet badge. The badge has a name, an affirmation, and a verse — a small reminder, in your own collection, of the work you have done.
        </p>
      </header>

      <BadgesFullPage programs={available} />
    </div>
  );
}
