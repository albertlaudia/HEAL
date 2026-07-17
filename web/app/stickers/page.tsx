// HEAL — Sticker book (web).
//
// Full-screen collection of every sticker HEAL can give the user:
//   - Streak family (3, 7, 14, 30, 60, 100, 365 day)
//   - Practice family (first breath, first meditation, first prayer, ...)
//   - Bible moment family (Psalm 23, Sermon on the Mount, ...)
//   - Program badges (e.g. "Finished Forgiveness")
//
// Each tile shows the earned/locked state. Earned tiles are colorful;
// locked tiles are desaturated with a small lock icon. The user can
// see the full list, not just earned ones — the locked ones act as
// motivation.
//
// Data source: a static sticker catalog (mirrored from the mobile
// `sticker_book.dart` so the two clients stay aligned). Earned state
// is read from localStorage (anonymous) or Firestore (signed in).

import type { Metadata } from 'next';
import { StickerBookClient } from '@/components/stickers/StickerBookClient';

export const metadata: Metadata = {
  title: 'Stickers · HEAL',
  description: 'A quiet collection of every sticker HEAL can give you.',
};

export const dynamic = 'force-dynamic';

export default function StickersPage() {
  return <StickerBookClient />;
}
