import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDuration(seconds: number) {
  if (!seconds) return '—';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m === 0) return `${s}s`;
  return s ? `${m}m ${s}s` : `${m}m`;
}

export function dayOfYear(date = new Date()) {
  const start = new Date(date.getFullYear(), 0, 0);
  return Math.floor((date.getTime() - start.getTime()) / 86400000);
}

export function dateLabel(date = new Date()) {
  return date.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
}

export function seasonOf(date = new Date()): 'advent' | 'christmas' | 'lent' | 'easter' | 'ordinary' | 'pentecost' {
  const m = date.getMonth() + 1;
  const d = date.getDate();
  // Liturgical seasons (Western Christian)
  if (m === 12 && d >= 1 && d < 25) return 'advent';
  if ((m === 12 && d >= 25) || m === 1 && d <= (8 - 1 + 6 + 1)) return 'christmas'; // rough
  if (m === 2 || m === 3 || (m === 4 && d < 14)) return 'lent';
  if (m === 4 && d >= 14 && d < 50) return 'easter'; // through Pentecost
  if (m === 5 && d < 20) return 'easter';
  return 'ordinary';
}

export function themeHue(theme?: string) {
  switch (theme) {
    case 'calm': return 'from-sage-100 via-bone to-bone';
    case 'gratitude': return 'from-dawn-100 via-bone to-bone';
    case 'let-go': return 'from-mist-100 via-bone to-bone';
    case 'love': return 'from-clay/20 via-bone to-bone';
    case 'focus': return 'from-mist-100 via-bone to-bone';
    case 'stillness': return 'from-sage-50 via-bone to-bone';
    case 'courage': return 'from-dawn-100 via-bone to-bone';
    case 'rest': return 'from-mist-50 via-bone to-bone';
    default: return 'from-bone via-bone to-bone';
  }
}
