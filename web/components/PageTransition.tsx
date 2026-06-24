'use client';

import { usePathname } from 'next/navigation';
import { useEffect, useState, ReactNode } from 'react';

export function PageTransition({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const [key, setKey] = useState(pathname);

  useEffect(() => {
    setKey(pathname);
  }, [pathname]);

  // IMPORTANT: do NOT add transform / filter / backdrop-filter / will-change
  // to this wrapper. A non-none transform would create a new containing
  // block, breaking `position: fixed` for any descendant popup
  // (WelcomeOverlay, MiniPlayer, AuthMenu dropdowns, InstallPrompt, etc.).
  // The page-enter animation is opacity-only for the same reason.
  return (
    <div key={key} className="animate-page-enter">
      {children}
    </div>
  );
}
