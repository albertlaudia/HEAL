'use client';

import { useEffect } from 'react';

// Lightweight, local-only recently viewed tracker
// Drop <TrackView kind="meditation" slug="..." /> into any server page;
// it renders nothing but writes to localStorage on mount.
export function TrackView({ kind, slug }: { kind: string; slug: string }) {
  useEffect(() => {
    try {
      const key = 'heal_recently_viewed_v1';
      const raw = localStorage.getItem(key);
      const list = raw ? JSON.parse(raw) : [];
      const filtered = list.filter((x: any) => !(x.kind === kind && x.slug === slug));
      const next = [{ kind, slug, viewedAt: Date.now() }, ...filtered].slice(0, 12);
      localStorage.setItem(key, JSON.stringify(next));
    } catch {}
  }, [kind, slug]);
  return null;
}
