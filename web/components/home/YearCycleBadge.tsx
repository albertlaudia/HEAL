'use client';

// Quiet, hand-feel calendar hint.
// Was: "Year 1 · Day 159 of 366" — too system-y, too "loading screen".
// Now: a single whispered day, no year, no "of 366".
export function YearCycleBadge({
  dayOfYear,
  compact = false,
}: {
  yearCycle?: number;
  dayOfYear: number;
  label?: string;
  compact?: boolean;
}) {
  // Convert day-of-year to a soft phrase: "Day 159" or just "Day 159 · early summer"
  const seasonal = seasonOfDay(dayOfYear);

  if (compact) {
    return (
      <span className="inline-flex items-center gap-1.5 text-[10px] tracking-[0.2em] uppercase text-ink/40">
        <span className="w-1 h-1 rounded-full bg-sage-500/50" />
        Day {dayOfYear}
        {seasonal && <span className="text-ink/30">· {seasonal}</span>}
      </span>
    );
  }
  return (
    <div className="inline-flex items-center gap-2 text-xs tracking-[0.2em] uppercase text-ink/45">
      <span className="w-1.5 h-1.5 rounded-full bg-sage-500/60" />
      <span>Day {dayOfYear}</span>
      {seasonal && <span className="text-ink/30">· {seasonal}</span>}
    </div>
  );
}

function seasonOfDay(d: number): string | null {
  // Northern-hemisphere style seasons. Add some warmth so the badge feels like a breath of context, not a calendar.
  // (We don't say "spring", "summer" literally — we say what the season is for the practice.)
  if (d >= 1 && d <= 60) return 'early winter';
  if (d <= 91) return 'late winter';
  if (d <= 121) return 'early spring';
  if (d <= 152) return 'mid-spring';
  if (d <= 182) return 'late spring';
  if (d <= 213) return 'early summer';
  if (d <= 244) return 'mid-summer';
  if (d <= 274) return 'late summer';
  if (d <= 305) return 'early autumn';
  if (d <= 335) return 'mid-autumn';
  return 'late autumn';
}