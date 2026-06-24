'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth-store';
import { listJournalPage, deleteJournal, type JournalEntry } from '@/lib/firebase-rest';
import { BookMarked, Trash2 } from 'lucide-react';
import { AuthMenu } from '@/components/auth/AuthMenu';
import { format } from 'date-fns';

export default function JournalPage() {
  const { user, ready } = useAuth();
  const [entries, setEntries] = useState<JournalEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasMore, setHasMore] = useState(false);
  const [cursor, setCursor] = useState<any>(undefined);

  const load = async (more = false) => {
    if (!user) return;
    setLoading(true);
    try {
      const page = await listJournalPage(user.uid, 20, more ? cursor : undefined);
      setEntries(es => more ? [...es, ...page.items] : page.items);
      setCursor(page.cursor);
      setHasMore(page.hasMore);
    } finally { setLoading(false); }
  };

  useEffect(() => { if (user) load(false); else setLoading(false); }, [user]);

  if (!ready) return null;

  if (!user) {
    return (
      <div className="container-quiet py-32 text-center">
        <BookMarked className="mx-auto text-ink/30 mb-6" size={32} />
        <h1 className="serif text-4xl mb-4">Journal</h1>
        <p className="text-ink/60 mb-8">A private space for what rises in you. Sign in to keep your entries synced.</p>
        <AuthMenu />
      </div>
    );
  }

  return (
    <div className="container-quiet py-16">
      <header className="mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Private to you</p>
        <h1 className="serif text-5xl mb-4">Journal</h1>
        <p className="text-ink/60">What rises in you during the practice. Encrypted in transit, stored privately.</p>
      </header>

      {loading && entries.length === 0 ? (
        <p className="text-ink/50">Loading…</p>
      ) : entries.length === 0 ? (
        <p className="text-ink/50 serif italic py-12">No entries yet. Open any meditation, scripture, or prayer and tap "Your journal" to begin.</p>
      ) : (
        <>
          <div className="space-y-4">
            {entries.map(e => (
              <article key={e.id} className="card-quiet p-6">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-xs text-ink/40">
                    {e.createdAt?.toDate ? format(e.createdAt.toDate(), 'EEEE, MMMM d · h:mm a') : '…'}
                  </p>
                  <button
                    onClick={async () => { if (!e.id) return; await deleteJournal(user.uid, e.id); setEntries(es => es.filter(x => x.id !== e.id)); }}
                    className="text-ink/30 hover:text-red-500"
                    aria-label="Delete"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
                {e.refTitle && (
                  <Link
                    href={e.refKind === 'meditation' ? `/meditate/${e.refSlug}` : e.refKind === 'essay' ? `/essays/${e.refSlug}` : '#'}
                    className="text-xs text-sage-700 hover:underline serif italic mb-3 inline-block"
                  >
                    on "{e.refTitle}"
                  </Link>
                )}
                <p className="serif text-lg leading-relaxed whitespace-pre-line">{e.text}</p>
              </article>
            ))}
          </div>
          {hasMore && (
            <div className="text-center mt-8">
              <button onClick={() => load(true)} disabled={loading} className="btn-ghost">
                {loading ? '…' : 'Load older entries'}
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
