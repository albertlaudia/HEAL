'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState, useEffect } from 'react';
import { cn } from '@/lib/utils';
import { Menu, X } from 'lucide-react';
import { AuthMenu } from '@/components/auth/AuthMenu';

const links = [
  { href: '/', label: 'Today' },
  { href: '/meditate', label: 'Meditate' },
  { href: '/breathe', label: 'Breathe' },
  { href: '/scripture', label: 'Scripture' },
  { href: '/prayers', label: 'Prayers' },
  { href: '/essays', label: 'Essays' },
  { href: '/praise', label: 'Praise' },
  { href: '/about', label: 'About' },
];

export function Nav() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => { setOpen(false); }, [pathname]);

  return (
    <header
      className={cn(
        'sticky top-0 z-40 transition-all duration-500',
        scrolled ? 'bg-bone/80 backdrop-blur-md border-b border-ink/5' : 'bg-transparent'
      )}
    >
      <div className="container-wide flex items-center justify-between h-16">
        <Link href="/" className="flex items-center gap-2 group">
          <Logo />
          <span className="serif text-2xl tracking-wide group-hover:tracking-wider transition-all">HEAL</span>
        </Link>

        <nav className="hidden md:flex items-center gap-1">
          {links.map(l => {
            const active = l.href === '/' ? pathname === '/' : pathname.startsWith(l.href);
            return (
              <Link
                key={l.href}
                href={l.href}
                className={cn(
                  'px-3 py-2 text-sm rounded-full transition-colors',
                  active ? 'text-ink' : 'text-ink/60 hover:text-ink'
                )}
              >
                {l.label}
              </Link>
            );
          })}
        </nav>

        <button
          onClick={() => setOpen(o => !o)}
          className="md:hidden p-2 -mr-2 text-ink/70 hover:text-ink"
          aria-label="Toggle menu"
        >
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
        <div className="hidden md:block"><AuthMenu /></div>
      </div>

      {/* Mobile drawer */}
      <div
        className={cn(
          'md:hidden overflow-hidden transition-all duration-500',
          open ? 'max-h-[420px] border-b border-ink/5' : 'max-h-0'
        )}
      >
        <nav className="container-wide py-4 flex flex-col gap-1 bg-bone/95 backdrop-blur">
          {links.map(l => {
            const active = l.href === '/' ? pathname === '/' : pathname.startsWith(l.href);
            return (
              <Link
                key={l.href}
                href={l.href}
                className={cn(
                  'px-3 py-3 rounded-xl text-lg serif',
                  active ? 'text-ink bg-ink/5' : 'text-ink/70'
                )}
              >
                {l.label}
              </Link>
            );
          })}
        </nav>
      </div>
    </header>
  );
}

function Logo() {
  return (
    <svg width="28" height="28" viewBox="0 0 28 28" fill="none" className="text-sage-600">
      <circle cx="14" cy="14" r="12" stroke="currentColor" strokeWidth="1.2" opacity="0.5" />
      <circle cx="14" cy="14" r="7" stroke="currentColor" strokeWidth="1.2" />
      <circle cx="14" cy="14" r="2" fill="currentColor" />
    </svg>
  );
}
