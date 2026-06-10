'use client';

import { Calendar } from 'lucide-react';

export function YearCycleBadge({
  yearCycle,
  dayOfYear,
  label,
  compact = false,
}: {
  yearCycle: number;
  dayOfYear: number;
  label: string;
  compact?: boolean;
}) {
  if (compact) {
    return (
      <span className="inline-flex items-center gap-1.5 text-[10px] tracking-widest uppercase text-sage-700 bg-sage-50 px-2 py-1 rounded-full">
        <Calendar size={10} />
        Year {yearCycle} · Day {dayOfYear}
      </span>
    );
  }
  return (
    <div className="inline-flex items-center gap-2 text-xs tracking-widest uppercase text-sage-700 bg-sage-50/80 border border-sage-200/60 px-3 py-1.5 rounded-full">
      <Calendar size={12} />
      <span>{label}</span>
    </div>
  );
}
