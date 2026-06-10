'use client';

import { useEffect, useState } from 'react';

type TimeOfDay = 'dawn' | 'morning' | 'midday' | 'afternoon' | 'evening' | 'night';

const GREETINGS: Record<TimeOfDay, string> = {
  dawn: 'A new day',
  morning: 'Good morning',
  midday: 'A small pause',
  afternoon: 'A breath in the middle',
  evening: 'The day is winding down',
  night: 'Late hour',
};

const SCRIPTURE_HINTS: Record<TimeOfDay, string> = {
  dawn: 'The steadfast love of the Lord never ceases. His mercies are new this morning.',
  morning: 'This is the day that the Lord has made. Let us rejoice and be glad in it.',
  midday: 'Come to me, all you who are weary, and I will give you rest.',
  afternoon: 'Be still, and know that I am God.',
  evening: 'Let the day be enough. The Lord is keeping watch.',
  night: 'In peace I will lie down and sleep, for you alone, O Lord, make me dwell in safety.',
};

function timeOfDay(h: number): TimeOfDay {
  if (h < 6) return 'night';
  if (h < 8) return 'dawn';
  if (h < 12) return 'morning';
  if (h < 14) return 'midday';
  if (h < 18) return 'afternoon';
  if (h < 22) return 'evening';
  return 'night';
}

export function TodayAtAGlance() {
  const [tod, setTod] = useState<TimeOfDay | null>(null);

  useEffect(() => {
    setTod(timeOfDay(new Date().getHours()));
    // Update every hour
    const i = setInterval(() => setTod(timeOfDay(new Date().getHours())), 60 * 60 * 1000);
    return () => clearInterval(i);
  }, []);

  if (!tod) return null;

  return (
    <div className="text-center mb-12 animate-fade-in">
      <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">
        {GREETINGS[tod]}
      </p>
      <h1 className="serif text-5xl md:text-6xl tracking-tight mb-4">
        A quiet practice
      </h1>
      <p className="serif italic text-xl text-ink/60 max-w-xl mx-auto">
        {SCRIPTURE_HINTS[tod]}
      </p>
    </div>
  );
}
