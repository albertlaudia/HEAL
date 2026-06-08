'use client';

import { useEffect, useState } from 'react';

export function InstallPrompt() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    // register service worker
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(() => {});
    }
    // capture install prompt
    const handler = (e: Event) => {
      e.preventDefault();
      (window as any).__healPrompt = e;
      setShow(true);
    };
    window.addEventListener('beforeinstallprompt', handler);
    return () => window.removeEventListener('beforeinstallprompt', handler);
  }, []);

  if (!show) return null;

  const install = async () => {
    const e: any = (window as any).__healPrompt;
    if (!e) return;
    e.prompt();
    await e.userChoice.catch(() => {});
    setShow(false);
  };

  return (
    <div className="fixed bottom-4 left-4 right-4 sm:left-auto sm:right-4 sm:max-w-sm z-50">
      <div className="card-quiet p-5 flex items-center gap-4 animate-fade-up">
        <div className="flex-1">
          <p className="serif text-lg">Carry HEAL with you</p>
          <p className="text-sm text-ink/60">Install for daily reminders and offline practice.</p>
        </div>
        <button onClick={install} className="btn-primary text-sm px-4 py-2">Install</button>
        <button onClick={() => setShow(false)} className="text-ink/40 hover:text-ink" aria-label="Dismiss">×</button>
      </div>
    </div>
  );
}
