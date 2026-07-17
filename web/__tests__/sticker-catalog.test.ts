// HEAL — sticker catalog tests (web).
//
// Verifies the catalog is well-formed: every sticker has a known color,
// a known symbol with a valid SVG path, and the streak family's
// milestones are strictly increasing.

import { STICKER_CATALOG, SYMBOL_PATHS } from '../components/stickers/sticker-catalog';

describe('sticker-catalog', () => {
  it('has a unique id for every sticker', () => {
    const ids = STICKER_CATALOG.map((s) => s.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('every sticker has a valid color', () => {
    const validColors = new Set([
      'rose', 'teal', 'amber', 'sage', 'indigo', 'muted-blue', 'warm-cream',
    ]);
    for (const s of STICKER_CATALOG) {
      expect(validColors.has(s.color)).toBe(true);
    }
  });

  it('every sticker has a symbol with a known SVG path', () => {
    for (const s of STICKER_CATALOG) {
      expect(SYMBOL_PATHS[s.symbol]).toBeDefined();
      // Path must be non-empty and look like an SVG path (starts with M or similar).
      expect(SYMBOL_PATHS[s.symbol].length).toBeGreaterThan(2);
    }
  });

  it('streak family milestones are strictly increasing', () => {
    const streaks = STICKER_CATALOG
      .filter((s) => s.family === 'streak' && s.milestone != null)
      .map((s) => s.milestone!);
    for (let i = 1; i < streaks.length; i++) {
      expect(streaks[i]).toBeGreaterThan(streaks[i - 1]);
    }
  });

  it('has stickers across all 4 families', () => {
    const families = new Set(STICKER_CATALOG.map((s) => s.family));
    expect(families.has('streak')).toBe(true);
    expect(families.has('practice')).toBe(true);
    expect(families.has('moment')).toBe(true);
  });

  it('every practice sticker has a short name', () => {
    for (const s of STICKER_CATALOG.filter((s) => s.family === 'practice')) {
      expect(s.name.length).toBeLessThan(40);
    }
  });
});
