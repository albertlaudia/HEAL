import Link from 'next/link';
import Image from 'next/image';
import { Home, BookOpen, Wind, Sparkles, Music } from 'lucide-react';
import { getPublished } from '@/lib/pb';
import { cdnUrl } from '@/lib/utils';

export default async function NotFound() {
  // Pick 4 random published meditations to suggest — deterministic per-render
  // so users get fresh suggestions each time but server can cache.
  let suggestions: { slug: string; title: string; illustration_url?: string; reflection?: string; theme?: string }[] = [];
  try {
    const all = (await getPublished(
      'HEAL_meditations',
      '-id',
      'is_published = true',
      20
    )) as any[];
    suggestions = all
      .sort(() => Math.random() - 0.5)
      .slice(0, 4)
      .map(m => ({
        slug: m.slug,
        title: m.title,
        illustration_url: m.illustration_url,
        reflection: m.reflection,
        theme: m.theme,
      }));
  } catch (err) {
    // PB unreachable — fall through without suggestions
  }

  return (
    <div className="min-h-[70vh] flex items-center justify-center px-6 py-12 md:py-20">
      <div className="max-w-3xl w-full">
        <div className="text-center mb-12">
          {/* Breathing circle with a tiny gap — visualizes "off the path" */}
          <div className="relative w-28 h-28 mx-auto mb-10">
            <div className="absolute inset-0 rounded-full border-2 border-sage-300/40 animate-breath" style={{ animationDuration: '6s' }} />
            <div className="absolute inset-4 rounded-full border-2 border-sage-400/50 animate-breath" style={{ animationDuration: '6s', animationDelay: '0.5s' }} />
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="serif text-3xl text-ink/30 font-light">?</span>
            </div>
          </div>

          <p className="text-xs tracking-[0.3em] uppercase text-ink/40 mb-4">404 · wandered off the path</p>
          <h1 className="serif text-4xl md:text-5xl mb-4">A small pause</h1>
          <p className="serif italic text-ink/60 text-base md:text-lg mb-3 leading-relaxed max-w-md mx-auto">
            The page you're looking for has gone quiet. That happens.
          </p>
          <p className="serif italic text-ink/45 text-sm mb-10 max-w-md mx-auto">
            Here are a few places you can land instead.
          </p>

          {/* Primary actions */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-3 mb-12">
            <Link href="/" className="btn-primary">
              <Home size={14} />
              Back to today
            </Link>
            <Link href="/meditate" className="btn-ghost">
              <BookOpen size={14} />
              Browse meditations
            </Link>
          </div>

          {/* Secondary on-ramps */}
          <p className="text-[10px] tracking-widest uppercase text-ink/30 mb-3">Or take a moment</p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 max-w-lg mx-auto">
            <Link href="/now" className="card-quiet p-4 text-xs text-ink/60 hover:text-ink hover:scale-[1.03] transition-all">
              <Wind size={16} className="mx-auto mb-1.5 text-sage-600" />
              <p className="text-[11px]">A 90-second ritual</p>
            </Link>
            <Link href="/breathe" className="card-quiet p-4 text-xs text-ink/60 hover:text-ink hover:scale-[1.03] transition-all">
              <Sparkles size={16} className="mx-auto mb-1.5 text-cyan-700" />
              <p className="text-[11px]">A breath</p>
            </Link>
            <Link href="/scripture" className="card-quiet p-4 text-xs text-ink/60 hover:text-ink hover:scale-[1.03] transition-all">
              <BookOpen size={16} className="mx-auto mb-1.5 text-amber-700" />
              <p className="text-[11px]">Read a verse</p>
            </Link>
            <Link href="/praise" className="card-quiet p-4 text-xs text-ink/60 hover:text-ink hover:scale-[1.03] transition-all">
              <Music size={16} className="mx-auto mb-1.5 text-indigo-700" />
              <p className="text-[11px]">A song</p>
            </Link>
          </div>
        </div>

        {/* Suggested meditations */}
        {suggestions.length > 0 && (
          <div className="mt-16">
            <p className="text-[10px] tracking-widest uppercase text-ink/40 mb-6 text-center">
              Or sit with one of these
            </p>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {suggestions.map(m => (
                <Link
                  key={m.slug}
                  href={`/meditate/${m.slug}`}
                  className="card-quiet group overflow-hidden flex flex-col hover:scale-[1.02] transition-transform"
                >
                  <div className="relative aspect-[4/3] bg-sage-100">
                    {m.illustration_url && (
                      <Image
                        src={cdnUrl(m.illustration_url) || ''}
                        alt={m.title}
                        fill
                        sizes="(max-width: 768px) 50vw, 25vw"
                        className="object-cover group-hover:scale-105 transition-transform duration-700"
                      />
                    )}
                  </div>
                  <div className="p-3 flex-1">
                    <h3 className="serif text-sm leading-tight mb-1 group-hover:text-sage-700 transition-colors line-clamp-2">
                      {m.title}
                    </h3>
                    {m.reflection && (
                      <p className="text-[11px] text-ink/55 leading-snug line-clamp-2">
                        {m.reflection.split('. ')[0]}.
                      </p>
                    )}
                  </div>
                </Link>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}