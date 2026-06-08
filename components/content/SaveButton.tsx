'use client';

import { useEffect, useState } from 'react';
import { Heart } from 'lucide-react';
import { useAuth } from '@/lib/auth-store';
import { addFavorite, removeFavorite, listFavorites, recordHistoryDebounced } from '@/lib/firebase-rest';
import { AuthMenu } from '@/components/auth/AuthMenu';

type Props = {
  kind: 'meditation' | 'scripture' | 'prayer' | 'quote' | 'essay';
  slug: string;
  title: string;
  subtitle?: string;
  illustration_url?: string;
};

const ALLOWED_HISTORY_KINDS = ['meditation', 'scripture', 'prayer', 'essay'] as const;

export function SaveButton({ kind, slug, title, subtitle, illustration_url }: Props) {
  const { user } = useAuth();
  const [saved, setSaved] = useState(false);
  const [busy, setBusy] = useState(false);
  const [showAuth, setShowAuth] = useState(false);

  useEffect(() => {
    if (!user) return;
    let alive = true;
    listFavorites(user.uid, kind).then(rows => {
      if (alive) setSaved(!!rows.find(r => r.slug === slug));
    }).catch(() => {});
    // Debounced — multiple visits to the same page within 30s = 1 write
    if (ALLOWED_HISTORY_KINDS.includes(kind as any)) {
      recordHistoryDebounced(user.uid, { kind: kind as 'meditation' | 'scripture' | 'prayer' | 'essay', slug, title });
    }
    return () => { alive = false; };
  }, [user, kind, slug, title]);

  const toggle = async () => {
    if (!user) { setShowAuth(true); return; }
    setBusy(true);
    try {
      if (saved) {
        await removeFavorite(user.uid, kind, slug);
        setSaved(false);
      } else {
        await addFavorite(user.uid, { kind, slug, title, subtitle, illustration_url });
        setSaved(true);
      }
    } finally { setBusy(false); }
  };

  return (
    <>
      <button
        onClick={toggle}
        disabled={busy}
        className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm transition-all ${
          saved ? 'bg-clay/15 text-clay border border-clay/30' : 'bg-paper border border-ink/10 text-ink/70 hover:border-ink/30'
        }`}
        aria-label={saved ? 'Remove from favorites' : 'Save to favorites'}
      >
        <Heart size={14} fill={saved ? 'currentColor' : 'none'} />
        {saved ? 'Saved' : 'Save'}
      </button>
      {showAuth && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-ink/30 backdrop-blur-sm" onClick={() => setShowAuth(false)}>
          <div className="card-quiet max-w-sm w-full p-8" onClick={e => e.stopPropagation()}>
            <h3 className="serif text-xl mb-3">Sign in to save</h3>
            <p className="text-sm text-ink/60 mb-6">Your favorites and journal will sync across devices.</p>
            <AuthMenu />
            <button onClick={() => setShowAuth(false)} className="mt-4 w-full text-sm text-ink/50">Maybe later</button>
          </div>
        </div>
      )}
    </>
  );
}
