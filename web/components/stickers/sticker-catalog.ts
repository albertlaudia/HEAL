// HEAL — sticker catalog (web).
//
// Mirrors `mobile/lib/services/sticker_book.dart` so the same stickers
// show up on web and mobile. When you add a sticker, add it here too.
//
// Adding a new sticker:
//   1. Add a new StickerSpec below.
//   2. Add an unlock rule in `evaluate.ts` (web) AND `sticker_book.dart`
//      (mobile) so both clients compute the same earned state.

export type StickerFamily = 'streak' | 'practice' | 'moment' | 'program';

export type StickerSpec = {
  id: string;
  family: StickerFamily;
  name: string;
  description: string;
  milestone?: number;          // streak family: day count
  color: 'rose' | 'teal' | 'amber' | 'sage' | 'indigo' | 'muted-blue' | 'warm-cream';
  symbol: string;              // SVG path key (see SYMBOLS below)
};

export const STICKER_CATALOG: StickerSpec[] = [
  // ── Streak family ─────────────────────────────────────────
  { id: 'streak-3',   family: 'streak', name: '3 days',         description: 'Three days in a row. The beginning of a rhythm.', milestone: 3,   color: 'rose',   symbol: 'seed' },
  { id: 'streak-7',   family: 'streak', name: '7 days',         description: 'One week. A habit is forming.',              milestone: 7,   color: 'rose',   symbol: 'sprout' },
  { id: 'streak-14',  family: 'streak', name: '14 days',        description: 'Two weeks. Your body knows the way now.',     milestone: 14,  color: 'teal',   symbol: 'leaf' },
  { id: 'streak-30',  family: 'streak', name: '30 days',        description: 'A month. A small revolution.',               milestone: 30,  color: 'teal',   symbol: 'tree' },
  { id: 'streak-60',  family: 'streak', name: '60 days',        description: 'Two months. The work is becoming who you are.', milestone: 60, color: 'amber',  symbol: 'sun' },
  { id: 'streak-100', family: 'streak', name: '100 days',       description: 'A hundred days. Rare and worth honoring.',   milestone: 100, color: 'amber',  symbol: 'mountain' },
  { id: 'streak-365', family: 'streak', name: 'A full year',    description: 'Three hundred and sixty-five days. A practice, not a streak.', milestone: 365, color: 'indigo', symbol: 'crown' },

  // ── Practice family ───────────────────────────────────────
  { id: 'first-breath',    family: 'practice', name: 'First breath',     description: 'You sat and breathed with HEAL.',     color: 'sage',  symbol: 'wind' },
  { id: 'first-meditation',family: 'practice', name: 'First meditation', description: 'Your first guided meditation.',       color: 'muted-blue', symbol: 'moon' },
  { id: 'first-prayer',    family: 'practice', name: 'First prayer',     description: 'You prayed with HEAL.',               color: 'rose',  symbol: 'hands' },
  { id: 'first-praise',    family: 'practice', name: 'First praise',     description: 'You sang along with HEAL.',           color: 'amber', symbol: 'note' },
  { id: 'first-bible',     family: 'practice', name: 'First scripture',  description: 'You sat with a verse.',               color: 'indigo', symbol: 'book' },
  { id: 'first-favorite',  family: 'practice', name: 'First favorite',   description: 'You hearted your first practice.',    color: 'rose',  symbol: 'heart' },
  { id: 'first-share',     family: 'practice', name: 'First share',      description: 'You shared HEAL with someone.',       color: 'teal',  symbol: 'share' },

  // ── Bible moment family ───────────────────────────────────
  { id: 'moment-genesis-1',    family: 'moment', name: 'In the beginning',  description: 'You sat with Genesis 1.',           color: 'amber',  symbol: 'star' },
  { id: 'moment-psalm-23',     family: 'moment', name: 'The Lord is my shepherd', description: 'You sat with Psalm 23.',        color: 'sage',   symbol: 'staff' },
  { id: 'moment-psalm-139',    family: 'moment', name: 'You have searched me', description: 'You sat with Psalm 139.',          color: 'indigo', symbol: 'search' },
  { id: 'moment-sermon-mount', family: 'moment', name: 'Blessed',           description: 'You finished the Beatitudes.',    color: 'muted-blue', symbol: 'mountain' },
  { id: 'moment-cross',        family: 'moment', name: 'It is finished',    description: 'You sat with the crucifixion.',  color: 'rose',   symbol: 'cross' },
  { id: 'moment-resurrection', family: 'moment', name: 'He is risen',       description: 'You sat with the resurrection.', color: 'amber',  symbol: 'sunrise' },
  { id: 'moment-pentecost',    family: 'moment', name: 'The Spirit came',   description: 'You sat with Pentecost.',        color: 'teal',   symbol: 'flame' },
];

export const SYMBOL_PATHS: Record<string, string> = {
  seed: 'M12 2C8 8 4 12 12 22C20 12 16 8 12 2Z',
  sprout: 'M12 22V12M12 12C12 8 8 6 6 4M12 12C12 8 16 6 18 4',
  leaf: 'M5 21C5 13 13 5 21 5C21 13 13 21 5 21Z',
  tree: 'M12 2L7 8H10V14H7L12 22L17 14H14V8H17L12 2Z',
  sun: 'M12 4V2M12 22V20M4 12H2M22 12H20M6 6L4 4M20 20L18 18M6 18L4 20M20 4L18 6M12 7A5 5 0 1 0 12 17A5 5 0 0 0 12 7Z',
  mountain: 'M3 20L9 10L13 16L17 8L21 20Z',
  crown: 'M3 8L6 14L12 6L18 14L21 8L19 18H5L3 8Z',
  wind: 'M3 8H15C17 8 19 6 19 4M3 16H19C21 16 21 14 21 12M3 12H13',
  moon: 'M21 12A9 9 0 1 1 12 3A7 7 0 0 0 21 12Z',
  hands: 'M9 11V5A1.5 1.5 0 0 1 12 5V11M15 11V5A1.5 1.5 0 0 1 18 5V11M9 11V15A3 3 0 0 0 12 18A3 3 0 0 0 15 15V11',
  note: 'M9 17V5L19 3V15M9 17A2 2 0 1 1 5 17A2 2 0 0 1 9 17ZM19 15A2 2 0 1 1 15 15A2 2 0 0 1 19 15Z',
  book: 'M4 4H10A4 4 0 0 1 14 8V20A2 2 0 0 0 12 18H4V4ZM20 4H14A4 4 0 0 0 10 8V20A2 2 0 0 1 12 18H20V4Z',
  heart: 'M12 21S4 14 4 8A5 5 0 0 1 12 5A5 5 0 0 1 20 8C20 14 12 21 12 21Z',
  share: 'M16 6L12 2L8 6M12 2V15M5 12V19A2 2 0 0 0 7 21H17A2 2 0 0 0 19 19V12',
  star: 'M12 2L14 9H21L15.5 13.5L17.5 21L12 16.5L6.5 21L8.5 13.5L3 9H10L12 2Z',
  staff: 'M9 21L15 3M15 3L18 6M15 3L12 6',
  search: 'M11 19A8 8 0 1 0 11 3A8 8 0 0 0 11 19ZM21 21L16 16',
  cross: 'M12 2V22M5 12H19',
  sunrise: 'M12 2V8M5 12H2M22 12H19M6 6L4 4M20 20L18 18M6 18L4 20M20 4L18 6M2 22H22M7 14A5 5 0 0 1 17 14',
  flame: 'M12 2C12 2 8 6 8 10A4 4 0 0 0 12 14A4 4 0 0 0 16 10C16 6 12 2 12 2ZM12 14V22',
};
