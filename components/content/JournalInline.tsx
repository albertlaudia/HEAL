'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-store';
import { addJournal, listJournalPage, deleteJournal, type JournalEntry } from '@/lib/firebase-rest';
import { BookMarked, Plus, Trash2 } from 'lucide-react';
import { format } from 'date-fns';

export function JournalInline({ refKind, refSlug, refTitle }: { refKind: 'meditation' | 'scripture' | 'prayer' | 'quote' | 'essay'; refSlug: string; refTitle: string }) {
  const { user } = useAuth();
  const [entries, setEntries] = useState<JournalEntry[]>([]);
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!user) return;
    let alive = true;
    // Load just the first page of journal, then filter client-side
    // (cap 20 reads regardless of how many entries match this refSlug)
    listJournalPage(user.uid, 20).then(page => {
      if (!alive) return;
      setEntries(page.items.filter(r => r.refSlug === refSlug));
    }).catch(() => {});
    return () => { alive = false; };
  }, [user, refSlug]);

  const save = async () => {
    if (!user || !text.trim()) return;
    setBusy(true);
    try {
      await addJournal(user.uid, { kind: 'reflection', text: text.trim(), refKind, refSlug, refTitle });
      setText('');
      const page = await listJournalPage(user.uid, 20);
      setEntries(page.items.filter(r => r.refSlug === refSlug));
    } finally { setBusy(false); }
  };

  const remove = async (id?: string) => {
    if (!user || !id) return;
    await deleteJournal(user.uid, id);
    setEntries(es => es.filter(e => e.id !== id));
  };

  if (!user) {
    return <p className="text-sm text-ink/50 italic">Sign in to keep a private journal alongside this practice.</p>;
  }

  return (
    <div className="space-y-4">
      <div className="card-quiet p-5">
        <textarea
          rows={3}
          placeholder="What is stirring in you right now?"
          value={text}
          onChange={e => setText(e.target.value)}
          className="w-full bg-transparent resize-none focus:outline-none serif text-lg"
        />
        <div className="flex items-center justify-between mt-2">
          <p className="text-xs text-ink/40">Private to you · synced to your account</p>
          <button onClick={save} disabled={!text.trim() || busy} className="btn-pill">
            <Plus size={14} /> Save
          </button>
        </div>
      </div>
      {entries.length > 0 && (
        <div className="space-y-3">
          {entries.map(e => (
            <div key={e.id} className="card-quiet p-5 flex gap-3">
              <BookMarked size={16} className="text-sage-600 mt-1 shrink-0" />
              <div className="flex-1">
                <p className="serif text-base leading-relaxed whitespace-pre-line">{e.text}</p>
                <p className="text-xs text-ink/40 mt-2">
                  {e.createdAt?.toDate ? format(e.createdAt.toDate(), 'MMM d, h:mm a') : '…'}
                </p>
              </div>
              <button onClick={() => remove(e.id)} className="text-ink/30 hover:text-red-500" aria-label="Delete">
                <Trash2 size={14} />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
