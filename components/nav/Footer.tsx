import Link from 'next/link';

export function Footer() {
  return (
    <footer className="mt-32 border-t border-ink/5 bg-bone">
      <div className="container-wide py-16">
        <div className="grid md:grid-cols-3 gap-12">
          <div>
            <Link href="/" className="serif text-3xl tracking-wide">HEAL</Link>
            <p className="mt-4 text-ink/60 max-w-xs leading-relaxed">
              A quiet practice. Daily Christian mindfulness for a noisy world.
            </p>
            <p className="mt-6 hand text-2xl text-sage-700">
              Be still. Breathe. Begin again.
            </p>
          </div>

          <div>
            <h4 className="text-sm tracking-widest uppercase text-ink/50 mb-4">Practice</h4>
            <ul className="space-y-2 text-ink/70">
              <li><Link href="/" className="hover:text-ink">Today</Link></li>
              <li><Link href="/meditate" className="hover:text-ink">Meditate</Link></li>
              <li><Link href="/breathe" className="hover:text-ink">Breathe</Link></li>
              <li><Link href="/scripture" className="hover:text-ink">Scripture</Link></li>
              <li><Link href="/prayers" className="hover:text-ink">Prayers</Link></li>
              <li><Link href="/essays" className="hover:text-ink">Essays</Link></li>
            </ul>
          </div>

          <div>
            <h4 className="text-sm tracking-widest uppercase text-ink/50 mb-4">HEAL</h4>
            <ul className="space-y-2 text-ink/70">
              <li><Link href="/about" className="hover:text-ink">Why Christian mindfulness</Link></li>
              <li><Link href="/contact" className="hover:text-ink">Contact</Link></li>
              <li><Link href="/privacy" className="hover:text-ink">Privacy</Link></li>
              <li><Link href="/terms" className="hover:text-ink">Terms</Link></li>
            </ul>
          </div>
        </div>

        <div className="mt-16 pt-8 border-t border-ink/5 flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-ink/50">
          <p>© {new Date().getFullYear()} HEAL. Made with care.</p>
          <p className="serif italic text-ink/40">"Be still, and know that I am God." — Psalm 46:10</p>
        </div>
      </div>
    </footer>
  );
}
