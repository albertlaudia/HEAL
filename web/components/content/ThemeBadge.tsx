import { cn } from '@/lib/utils';

const THEME_STYLES: Record<string, string> = {
  calm: 'bg-sage-100 text-sage-800',
  gratitude: 'bg-dawn-100 text-dawn-700',
  'let-go': 'bg-mist-100 text-mist-700',
  love: 'bg-clay/15 text-clay',
  focus: 'bg-mist-100 text-mist-700',
  stillness: 'bg-sage-50 text-sage-700',
  courage: 'bg-dawn-100 text-dawn-700',
  rest: 'bg-mist-50 text-mist-600',
};

const THEME_LABELS: Record<string, string> = {
  calm: 'calm',
  gratitude: 'gratitude',
  'let-go': 'let go',
  love: 'love',
  focus: 'focus',
  stillness: 'stillness',
  courage: 'courage',
  rest: 'rest',
};

export function ThemeBadge({ theme, className }: { theme?: string; className?: string }) {
  if (!theme) return null;
  return (
    <span className={cn(
      'inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] tracking-wider uppercase',
      THEME_STYLES[theme] || 'bg-ink/5 text-ink/70',
      className
    )}>
      {THEME_LABELS[theme] || theme}
    </span>
  );
}
