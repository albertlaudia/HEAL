'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth-store';
import { Flame } from 'lucide-react';

type StreakData = { current: number; longest: number; lastDate: string | null };

export function StreakCounter() {
  const { user, ready } = useAuth();
  const [streak, setStreak] = useState<StreakData | null>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    if (!ready) return;
    if (!user) { setLoaded(true); return; }
    // Read from localStorage cache (mirrors Firestore counter doc)
    try {
      const key = `heal.streak.${user.uid}`;
      const raw = localStorage.getItem(key);
      if (raw) {
        setStreak(JSON.parse(raw));
      } else {
        setStreak({ current: 0, longest: 0, lastDate: null });
      }
    } catch {
      setStreak({ current: 0, longest: 0, lastDate: null });
    }
    setLoaded(true);
  }, [user, ready]);

  if (!loaded) return null;

  if (!user) {
    return (
      <div className="card-quiet p-6 flex items-center gap-4">
        <div className="w-10 h-10 rounded-full bg-sage-100 flex items-center justify-center shrink-0">
          <Flame size={18} className="text-sage-700" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium">Begin a practice</p>
          <p className="text-xs text-ink/50">Sign in to track your daily rhythm.</p>
        </div>
      </div>
    );
  }

  if (!streak) return null;

  return (
    <div className="card-quiet p-6 flex items-center gap-4">
      <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 transition-colors ${streak.current > 0 ? 'bg-amber-100' : 'bg-sage-100'}`}>
        <Flame size={18} className={streak.current > 0 ? 'text-amber-700' : 'text-sage-700'} />
      </div>
      <div className="flex-1 min-w-0">
        <p className="serif text-base">
          {streak.current === 0
            ? 'A new day to begin'
            : streak.current === 1
              ? 'You began today'
              : streak.current < 7
                ? 'A gentle rhythm forming'
                : streak.current < 21
                  ? 'A practice taking root'
                  : streak.current < 60
                    ? 'A quiet habit'
                    : 'You walk this daily'}
        </p>
        <p className="text-xs text-ink/45 italic mt-0.5">
          {streak.longest > 0
            ? streak.current === streak.longest
              ? `the longest you've gone — day ${streak.current}`
              : `your longest was ${streak.longest} days`
            : 'One breath at a time.'}
        </p>
      </div>
    </div>
  );
}
