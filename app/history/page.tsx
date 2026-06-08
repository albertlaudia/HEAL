'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth-store';
import { listHistory } from '@/lib/firebase-rest';
import { History as HistoryIcon } from 'lucide-react';
import { AuthMenu } from '@/components/auth/AuthMenu';
import { format } from 'date-fns';

type H = { id?: string; kind: string; slug: string; title: string; viewedAt?: any };

export default function HistoryPage() {
  const { user, ready } = useAuth();
  const [items, setItems] = useState<H[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { setLoading(false); return; }
    listHistory(user.uid, 50).then(setItems).catch(() => {}).finally(() => setLoading(false));
  }, [user]);

  if (!ready) return null;

  if (!user) {
    return (
      <div className="container-quiet py-32 text-center">
        <HistoryIcon className="mx-auto text-ink/30 mb-6" size={32} />
        <h1 className="serif text-4xl mb-4">History</h1>
        <p className="text-ink/60 mb-8">Your recent visits. Sign in to keep them synced across devices.</p>
        <AuthMenu />
      </div>
    );
  }

  return (
    <div className="container-quiet py-16">
      <header className="mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Recent</p>
        <h1 className="serif text-5xl mb-4">History</h1>
        <p className="text-ink/60">The places you've been lately.</p>
      </header>

      {loading ? <p className="text-ink/50">Loading…</p> : items.length === 0 ? (
        <p className="text-ink/50 serif italic">No history yet.</p>
      ) : (
        <ul className="space-y-2">
          {items.map(h => (
            <li key={h.id}>
              <Link
                href={h.kind === 'meditation' ? `/meditate/${h.slug}` : h.kind === 'essay' ? `/essays/${h.slug}` : '#'}
                className="card-quiet p-4 flex items-center justify-between gap-4 hover:scale-[1.005] transition-transform"
              >
                <div>
                  <p className="text-xs text-ink/40 uppercase tracking-wider">{h.kind}</p>
                  <p className="serif text-lg">{h.title}</p>
                </div>
                <p className="text-xs text-ink/40">
                  {h.viewedAt?.toDate ? format(h.viewedAt.toDate(), 'MMM d') : '…'}
                </p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
