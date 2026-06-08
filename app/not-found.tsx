import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="container-quiet py-32 text-center">
      <p className="text-xs tracking-[0.3em] uppercase text-ink/40 mb-6">404</p>
      <h1 className="serif text-5xl md:text-6xl mb-4">Wandered off the path</h1>
      <p className="serif italic text-ink/60 text-xl mb-12">
        The page you're looking for has gone quiet. Return to today's practice.
      </p>
      <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
        <Link href="/" className="btn-primary">Back to today</Link>
        <Link href="/meditate" className="btn-ghost">Browse meditations</Link>
      </div>
    </div>
  );
}
