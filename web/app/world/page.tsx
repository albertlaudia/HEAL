import Link from 'next/link';
import { ArrowRight } from 'lucide-react';
import { getPublished } from '@/lib/pb';

export const revalidate = 3600;

export const metadata = {
  title: 'The world, today — daily invitations',
  description: 'A daily piece on the world today — a problem, a grace, or a gratitude. A prayer, a Bible verse, and one thing we could expect.',
};

const KIND_COLORS: Record<string, string> = {
  challenge: 'border-cyan-200/60 bg-cyan-50/40 text-cyan-800',
  grace:     'border-sage-200/60 bg-sage-50/40 text-sage-800',
  gratitude: 'border-amber-200/60 bg-amber-50/40 text-amber-800',
};

export default async function WorldIndexPage() {
  const all = (await getPublished('HEAL_world', '-published_at', 'is_published = true', 90)) || [];

  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Daily</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">The world, today</h1>
        <p className="text-ink/60 leading-relaxed">
          Each day, one fresh look at the world. A weight to pray into, a piece of grace you might have missed, or something worth giving thanks for. A prayer, a Bible verse, and one thing we could expect — for the next 90 days, archived here.
        </p>
      </header>

      {all.length === 0 ? (
        <p className="text-ink/50 serif italic">
          Today&apos;s piece is still being written. It appears here at 6am Australia.
        </p>
      ) : (
        <div className="space-y-3 max-w-3xl">
          {all.map((w: any) => (
            <Link
              key={w.id}
              href={`/world/${w.slug}`}
              className="group flex items-baseline gap-4 card-quiet p-5 hover:scale-[1.005] transition-all"
            >
              <p className="text-xs tracking-widest uppercase text-ink/40 shrink-0 w-28">
                {w.published_at && new Date(w.published_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
              </p>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className={`text-[10px] tracking-[0.2em] uppercase px-2 py-0.5 rounded-full border ${KIND_COLORS[w.prompt_kind] || KIND_COLORS.grace}`}>
                    {w.prompt_kind}
                  </span>
                </div>
                <h2 className="serif text-xl leading-snug mb-1 group-hover:text-sage-800 transition-colors">
                  {w.title}
                </h2>
                {w.scripture_ref && (
                  <p className="serif italic text-xs text-ink/45">— {w.scripture_ref}</p>
                )}
              </div>
              <ArrowRight size={14} className="text-ink/30 group-hover:text-ink/70 transition-colors shrink-0" />
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
