import Link from 'next/link';
import { Home, BookOpen, Wind, Sparkles } from 'lucide-react';

export default function NotFound() {
  return (
    <div className="min-h-[70vh] flex items-center justify-center px-6 py-20">
      <div className="text-center max-w-md">
        {/* Breathing circle with a tiny gap — visualizes "off the path" */}
        <div className="relative w-28 h-28 mx-auto mb-12">
          <div
            className="absolute inset-0 rounded-full border-2 border-sage-300/40 animate-breath"
            style={{ animationDuration: '6s' }}
          />
          <div
            className="absolute inset-4 rounded-full border-2 border-sage-400/50 animate-breath"
            style={{ animationDuration: '6s', animationDelay: '0.5s' }}
          />
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="serif text-3xl text-ink/30 font-light">?</span>
          </div>
        </div>

        <p className="text-xs tracking-[0.3em] uppercase text-ink/40 mb-4">404</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Wandered off the path</h1>
        <p className="serif italic text-ink/60 text-lg mb-3 leading-relaxed">
          The page you're looking for has gone quiet.
        </p>
        <p className="serif italic text-ink/40 text-sm mb-12">
          That happens. Return to the practice.
        </p>

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

        <p className="text-[10px] tracking-widest uppercase text-ink/30 mb-4">Or take a moment</p>
        <div className="grid grid-cols-3 gap-2 max-w-sm mx-auto">
          <Link href="/now" className="card-quiet p-3 text-xs text-ink/60 hover:text-ink hover:scale-[1.03] transition-all">
            <Wind size={14} className="mx-auto mb-1 text-sage-600" />
            <p className="text-[10px]">A quick reset</p>
          </Link>
          <Link href="/scripture" className="card-quiet p-3 text-xs text-ink/60 hover:text-ink hover:scale-[1.03] transition-all">
            <BookOpen size={14} className="mx-auto mb-1 text-amber-700" />
            <p className="text-[10px]">Read a verse</p>
          </Link>
          <Link href="/breathe" className="card-quiet p-3 text-xs text-ink/60 hover:text-ink hover:scale-[1.03] transition-all">
            <Sparkles size={14} className="mx-auto mb-1 text-cyan-700" />
            <p className="text-[10px]">A breath</p>
          </Link>
        </div>
      </div>
    </div>
  );
}
