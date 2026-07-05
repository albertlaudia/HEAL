import Link from 'next/link';
import { getPublished } from '@/lib/pb';

export const revalidate = 3600;

export const metadata = {
  title: 'Reflections — long reads on the practice',
  description: 'Slower pieces on the practice of Christian mindfulness — theology, psychology, story. A short reading for a quiet hour.',
};

export default async function ReflectionsPage() {
  const essays = await getPublished('HEAL_essays', '-published_at', 'is_published = true');
  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Long reads</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Reflections</h1>
        <p className="text-ink/60 leading-relaxed">
          Slower pieces on the practice of Christian mindfulness — theology, psychology, story. A short reading for a quiet hour.
        </p>
      </header>

      {essays.length === 0 ? (
        <p className="text-ink/50 serif italic">The first reflection is being written.</p>
      ) : (
        <div className="space-y-6 max-w-3xl">
          {essays.map((e: any) => (
            <Link key={e.id} href={`/essays/${e.slug}`} className="block card-quiet p-8 hover:scale-[1.005] transition-transform">
              <p className="text-xs tracking-widest uppercase text-ink/40 mb-3">
                {new Date(e.published_at).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                {e.reading_minutes ? ` · ${e.reading_minutes} min` : ''}
              </p>
              <h2 className="serif text-3xl mb-3">{e.title}</h2>
              {e.subtitle && <p className="serif italic text-ink/60 mb-4">{e.subtitle}</p>}
              {e.excerpt && <p className="text-ink/70 leading-relaxed line-clamp-3">{e.excerpt}</p>}
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
