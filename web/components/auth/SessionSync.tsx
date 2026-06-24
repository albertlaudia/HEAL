'use client';

// Sync Firebase auth state ↔ server session cookie
// Mount once in the root layout (client component)
import { useEffect } from 'react';
import { watchAuth } from '@/lib/firebase-client';
import { syncSessionCookie, ensureUserDoc } from '@/lib/firebase-rest';
import { useAuth } from '@/lib/auth-store';

export function SessionSync() {
  const { setUser } = useAuth();

  useEffect(() => {
    let cancelled = false;
    return watchAuth(async (u) => {
      if (cancelled) return;
      if (u) {
        const r: any = await syncSessionCookie();
        const next = r?.user || { uid: u.uid, email: u.email, name: u.displayName, picture: u.photoURL };
        setUser(next);
        try { await ensureUserDoc(next.uid, next.name || undefined); } catch {}
      } else {
        await syncSessionCookie();
        setUser(null);
      }
    });
  }, [setUser]);

  return null;
}
