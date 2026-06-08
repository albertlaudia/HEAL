import { getPublished } from '@/lib/pb';
import { BreathStudio } from '@/components/breathe/BreathStudio';

export const revalidate = 3600;

export default async function BreathePage() {
  const practices = await getPublished('HEAL_breathwork', 'sort_order', 'is_published = true');
  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Practice</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Breath</h1>
        <p className="text-ink/60 leading-relaxed">
          The breath is the oldest prayer — it is always with you, it asks nothing, and it returns you to the present. Try one of these patterns.
        </p>
      </header>
      <BreathStudio practices={practices} />
    </div>
  );
}
