/**
 * Programs + Badges client-side helpers
 * Stores user progress in Firestore under /users/{uid}/programs/{programSlug}
 * and earned badges under /users/{uid}/badges/{programSlug}
 *
 * Anonymous users: progress is kept in localStorage as a fallback so they
 * can still see their work. Badges for anonymous users are local-only
 * (no cross-device sync).
 */
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase-client';
import { getCurrentUser } from './auth-client';

export type ProgramProgressState = {
  started: boolean;
  completed: boolean;
  completedSteps: number[];
  currentStep: number;
  completedAt: string | null;
};

const LOCAL_PREFIX = 'heal_program_';
const BADGE_PREFIX = 'heal_badge_';

function localKey(slug: string) {
  return `${LOCAL_PREFIX}${slug}`;
}
function localBadgeKey(slug: string) {
  return `${BADGE_PREFIX}${slug}`;
}

function emptyState(): ProgramProgressState {
  return {
    started: false,
    completed: false,
    completedSteps: [],
    currentStep: 1,
    completedAt: null,
  };
}

export async function getProgramProgress(programSlug: string): Promise<ProgramProgressState> {
  const user = getCurrentUser();
  if (user) {
    try {
      const snap = await getDoc(doc(db, 'users', user.uid, 'programs', programSlug));
      if (snap.exists()) {
        return snap.data() as ProgramProgressState;
      }
    } catch (e) {
      // fall through to local
    }
  }
  // Local fallback
  if (typeof window !== 'undefined') {
    try {
      const raw = window.localStorage.getItem(localKey(programSlug));
      if (raw) return JSON.parse(raw) as ProgramProgressState;
    } catch {}
  }
  return emptyState();
}

export async function markStepComplete(
  programSlug: string,
  stepIndex: number,
  totalSteps: number
): Promise<{ nowCompleted: boolean; newBadgeEarned: { name: string; affirmation: string } | null }> {
  const user = getCurrentUser();
  const prev = await getProgramProgress(programSlug);
  const completedSteps = Array.from(new Set([...prev.completedSteps, stepIndex])).sort((a, b) => a - b);
  const allDone = completedSteps.length >= totalSteps;
  const next: ProgramProgressState = {
    started: true,
    completed: allDone,
    completedSteps,
    currentStep: Math.min(stepIndex + 1, totalSteps),
    completedAt: allDone ? (prev.completedAt || new Date().toISOString()) : prev.completedAt,
  };
  let newBadge: { name: string; affirmation: string } | null = null;
  if (allDone && !prev.completed) {
    // Look up the badge details from PB. Import lazily to avoid SSR.
    try {
      const res = await fetch(`/api/programs/${programSlug}/badge`);
      if (res.ok) {
        const b = await res.json();
        newBadge = { name: b.name, affirmation: b.affirmation };
      }
    } catch {}
  }
  if (user) {
    try {
      await setDoc(doc(db, 'users', user.uid, 'programs', programSlug), {
        ...next,
        updatedAt: serverTimestamp(),
      }, { merge: false });
      if (newBadge) {
        await setDoc(doc(db, 'users', user.uid, 'badges', programSlug), {
          programSlug,
          name: newBadge.name,
          affirmation: newBadge.affirmation,
          earnedAt: serverTimestamp(),
        });
      }
    } catch (e) {
      // fall through to local
    }
  }
  // Always mirror to local for snappy UI + anonymous users
  if (typeof window !== 'undefined') {
    try {
      window.localStorage.setItem(localKey(programSlug), JSON.stringify(next));
      if (newBadge) {
        window.localStorage.setItem(localBadgeKey(programSlug), JSON.stringify({
          programSlug,
          name: newBadge.name,
          affirmation: newBadge.affirmation,
          earnedAt: next.completedAt,
        }));
      }
    } catch {}
  }
  return { nowCompleted: allDone, newBadgeEarned: newBadge };
}

export type BadgeRecord = {
  programSlug: string;
  name: string;
  affirmation: string;
  scriptureRef?: string;
  scriptureText?: string;
  imagePath?: string;
  earnedAt: string;
};

export async function getAllBadges(): Promise<BadgeRecord[]> {
  const user = getCurrentUser();
  if (user) {
    try {
      // List user's badges subcollection
      const { getDocs, collection } = await import('firebase/firestore');
      const snap = await getDocs(collection(db, 'users', user.uid, 'badges'));
      return snap.docs.map((d) => {
        const data = d.data();
        return {
          programSlug: data.programSlug,
          name: data.name,
          affirmation: data.affirmation,
          earnedAt: data.earnedAt?.toDate?.()?.toISOString?.() || new Date().toISOString(),
        } as BadgeRecord;
      });
    } catch (e) {
      // fall through to local
    }
  }
  // Local fallback
  if (typeof window !== 'undefined') {
    const out: BadgeRecord[] = [];
    for (let i = 0; i < window.localStorage.length; i++) {
      const k = window.localStorage.key(i);
      if (k && k.startsWith(BADGE_PREFIX)) {
        try {
          out.push(JSON.parse(window.localStorage.getItem(k) || '{}'));
        } catch {}
      }
    }
    return out.sort((a, b) => (a.earnedAt > b.earnedAt ? -1 : 1));
  }
  return [];
}
