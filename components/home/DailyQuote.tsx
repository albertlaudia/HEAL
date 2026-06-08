import { cn } from '@/lib/utils';

export function DailyQuote({ quote }: { quote: any }) {
  if (!quote) {
    return (
      <div className="card-quiet p-8">
        <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">A Word</p>
        <p className="serif text-2xl text-ink/40">Coming soon</p>
      </div>
    );
  }
  return (
    <div className="card-quiet p-8 flex flex-col h-full">
      <p className="text-xs tracking-widest uppercase text-ink/40 mb-6">A Word For You</p>
      <blockquote className="serif text-2xl leading-snug text-ink/85 flex-1">
        "{quote.text}"
      </blockquote>
      {quote.attribution && (
        <p className="mt-6 text-sm text-ink/50 serif italic">— {quote.attribution}</p>
      )}
    </div>
  );
}
