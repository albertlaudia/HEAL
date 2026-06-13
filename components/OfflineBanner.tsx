'use client';

import { useState, useEffect } from 'react';
import { Wifi, WifiOff } from 'lucide-react';

export function OfflineBanner() {
  const [online, setOnline] = useState(true);
  const [showBack, setShowBack] = useState(false);

  useEffect(() => {
    if (typeof navigator === 'undefined') return;
    setOnline(navigator.onLine);
    const onUp = () => { setOnline(true); setShowBack(true); setTimeout(() => setShowBack(false), 3000); };
    const onDown = () => setOnline(false);
    window.addEventListener('online', onUp);
    window.addEventListener('offline', onDown);
    return () => {
      window.removeEventListener('online', onUp);
      window.removeEventListener('offline', onDown);
    };
  }, []);

  if (online && !showBack) return null;

  return (
    <div
      className={`fixed top-0 left-0 right-0 z-[60] transition-all duration-500 ${
        online ? 'translate-y-0 opacity-100' : 'translate-y-0 opacity-100'
      }`}
      role="status"
      aria-live="polite"
    >
      <div className={`px-4 py-2 text-center text-xs ${
        online
          ? 'bg-sage-100 text-sage-800'
          : 'bg-amber-50 text-amber-900'
      }`}>
        {online ? (
          <span className="inline-flex items-center gap-2 animate-fade-in">
            <Wifi size={12} />
            <span>You are back online. Welcome back.</span>
          </span>
        ) : (
          <span className="inline-flex items-center gap-2">
            <WifiOff size={12} />
            <span>You are offline. HEAL still works for what you have already opened.</span>
          </span>
        )}
      </div>
    </div>
  );
}
