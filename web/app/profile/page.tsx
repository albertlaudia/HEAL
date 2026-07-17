// HEAL — Profile page (web).
//
// The user's full practice profile:
//   1. Header: avatar + name + sign-in state
//   2. Streak summary: current, longest, total sessions
//   3. Activity heatmap: last 90 days, GitHub-style
//   4. Sticker highlights: most recent + rarest earned
//   5. Quick links: library, stickers, journal
//
// Data is read from localStorage (anonymous) or Firestore (signed in).
// Server component for static metadata, client component for interactivity.

import type { Metadata } from 'next';
import { ProfileClient } from '@/components/profile/ProfileClient';

export const metadata: Metadata = {
  title: 'Your practice · HEAL',
  description: 'A quiet summary of the work you have done.',
};

export const dynamic = 'force-dynamic';

export default function ProfilePage() {
  return <ProfileClient />;
}
