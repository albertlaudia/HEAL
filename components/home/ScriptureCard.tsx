import Link from 'next/link';
import { BookOpen } from 'lucide-react';

export function ScriptureCard({ scripture }: { scripture: any }) {
  if (!scripture) {
    return (
      <div className="card-quiet p-8">
        <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">Scripture</p>
        <p className="serif text-2xl text-ink/40">—</p>
      </div>
    );
  }
  return (
    <div className="card-quiet p-8 flex flex-col h-full">
      <p className="text-xs tracking-widest uppercase text-ink/40 mb-6">Scripture</p>
      <p className="serif text-xl leading-relaxed text-ink/85 flex-1">
        "{scripture.text}"
      </p>
      <p className="mt-6 serif italic text-ink/60">— {scripture.reference}</p>
      {scripture.reflection_prompt && (
        <p className="mt-4 text-sm text-ink/50 leading-relaxed">
          <span className="hand text-xl text-sage-700">Reflect: </span>
          {scripture.reflection_prompt}
        </p>
      )}
      <Link
        href="/scripture"
        className="mt-6 inline-flex items-center gap-2 text-sm text-ink/60 hover:text-ink transition-colors"
      >
        <BookOpen size={14} /> Today's full reading
      </Link>
    </div>
  );
}
