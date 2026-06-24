'use client';

import Link from 'next/link';
import { useEffect } from 'react';

export default function Error({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { console.error(error); }, [error]);
  return (
    <div className="container-quiet py-32 text-center">
      <p className="text-xs tracking-[0.3em] uppercase text-ink/40 mb-6">an interruption</p>
      <h1 className="serif text-5xl md:text-6xl mb-4">Something paused</h1>
      <p className="serif italic text-ink/60 text-xl mb-12">
        Even the best liturgies need a breath. Try again, gently.
      </p>
      <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
        <button onClick={reset} className="btn-primary">Try again</button>
        <Link href="/" className="btn-ghost">Back to today</Link>
      </div>
    </div>
  );
}
