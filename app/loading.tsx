export default function Loading() {
  return (
    <div className="container-quiet py-32 text-center">
      <div className="inline-flex items-center gap-3">
        <span className="w-2 h-2 bg-ink/40 rounded-full animate-pulse" />
        <span className="w-2 h-2 bg-ink/40 rounded-full animate-pulse" style={{ animationDelay: '0.2s' }} />
        <span className="w-2 h-2 bg-ink/40 rounded-full animate-pulse" style={{ animationDelay: '0.4s' }} />
      </div>
      <p className="mt-6 serif italic text-ink/50">Settling in…</p>
    </div>
  );
}
