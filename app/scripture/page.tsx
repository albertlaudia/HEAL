import { getPublished } from '@/lib/pb';
import Link from 'next/link';
import { ScriptureList } from '@/components/scripture/ScriptureList';

export const revalidate = 3600;

export default async function ScripturePage() {
  const scriptures = await getPublished('HEAL_scriptures', 'day_of_year', 'is_published = true');
  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Passages</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Scripture</h1>
        <p className="text-ink/60 leading-relaxed">
          A short passage, a single question, and the space to sit with it. Read slowly. There is nothing to do next.
        </p>
      </header>
      <ScriptureList scriptures={scriptures} />
    </div>
  );
}
