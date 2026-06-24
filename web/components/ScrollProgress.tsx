'use client';

import { useEffect, useState } from 'react';

export function ScrollProgress({ color = 'sage' }: { color?: 'sage' | 'amber' | 'indigo' | 'cyan' }) {
  const [pct, setPct] = useState(0);

  useEffect(() => {
    const onScroll = () => {
      const doc = document.documentElement;
      const total = doc.scrollHeight - doc.clientHeight;
      const p = total > 0 ? Math.min(100, Math.max(0, (window.scrollY / total) * 100)) : 0;
      setPct(p);
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll, { passive: true });
    return () => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
    };
  }, []);

  const colorMap = {
    sage: 'bg-sage-500',
    amber: 'bg-amber-500',
    indigo: 'bg-indigo-500',
    cyan: 'bg-cyan-500',
  };

  return (
    <div
      className="fixed top-0 left-0 right-0 z-50 h-0.5 bg-transparent pointer-events-none"
      aria-hidden
    >
      <div
        className={`h-full ${colorMap[color]} transition-all duration-150`}
        style={{ width: `${pct}%`, opacity: pct > 0.5 ? 1 : 0 }}
      />
    </div>
  );
}
