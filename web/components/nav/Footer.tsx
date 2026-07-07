import Link from 'next/link';

export function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="mt-32 border-t border-ink/5 bg-bone">
      <div className="container-wide py-16">
        <div className="grid md:grid-cols-4 gap-12">
          <div>
            <Link href="/" className="serif text-3xl tracking-wide">HEAL</Link>
            <p className="mt-4 text-ink/60 max-w-xs leading-relaxed">
              A quiet practice. Daily Christian mindfulness for a noisy world.
            </p>
            <p className="mt-6 hand text-2xl text-sage-700">
              Be still. Breathe. Begin again.
            </p>
            <p className="mt-6 text-xs text-ink/40">
              HEAL by{' '}
              <a
                href="https://positiveness.club"
                className="underline underline-offset-2 hover:text-ink/70"
                target="_blank"
                rel="noopener noreferrer"
              >
                positiveness.club
              </a>
            </p>
          </div>

          <div>
            <h4 className="text-sm tracking-widest uppercase text-ink/50 mb-4">Practice</h4>
            <ul className="space-y-2 text-ink/70">
              <li><Link href="/" className="hover:text-ink">Today</Link></li>
              <li><Link href="/world" className="hover:text-ink">The world, today</Link></li>
              <li><Link href="/meditate" className="hover:text-ink">Meditate</Link></li>
              <li><Link href="/breathe" className="hover:text-ink">Breathe</Link></li>
              <li><Link href="/scripture" className="hover:text-ink">Scripture</Link></li>
              <li><Link href="/prayers" className="hover:text-ink">Prayers</Link></li>
              <li><Link href="/essays" className="hover:text-ink">Reflections</Link></li>
              <li><Link href="/praise" className="hover:text-ink">Praise</Link></li>
              <li><Link href="/programs" className="hover:text-ink">Programs</Link></li>
              <li><Link href="/badges" className="hover:text-ink">Badges</Link></li>
            </ul>
          </div>

          <div>
            <h4 className="text-sm tracking-widest uppercase text-ink/50 mb-4">The space</h4>
            <ul className="space-y-2 text-ink/70">
              <li><Link href="/about" className="hover:text-ink">Why HEAL</Link></li>
              <li><Link href="/guidelines" className="hover:text-ink">Community guidelines</Link></li>
              <li><Link href="/contact" className="hover:text-ink">Contact</Link></li>
            </ul>
          </div>

          <div>
            <h4 className="text-sm tracking-widest uppercase text-ink/50 mb-4">Legal</h4>
            <ul className="space-y-2 text-ink/70">
              <li><Link href="/privacy" className="hover:text-ink">Privacy</Link></li>
              <li><Link href="/terms" className="hover:text-ink">Terms of service</Link></li>
              <li><Link href="/guidelines" className="hover:text-ink">Community guidelines</Link></li>
              <li><Link href="/contact" className="hover:text-ink">Report a concern</Link></li>
            </ul>
            <p className="mt-6 text-xs text-ink/50 leading-relaxed">
              HEAL is a pastoral platform, not a substitute for medical, psychological, or legal care. If you are in crisis, call 988 (US) or your local emergency number.
            </p>
          </div>
        </div>

        <div className="mt-16 pt-8 border-t border-ink/5 flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-ink/50">
          <p>© {year} positiveness.club. All rights reserved.</p>
          <p className="serif italic text-ink/40">"Be still, and know that I am God." — Psalm 46:10</p>
        </div>
      </div>
    </footer>
  );
}
