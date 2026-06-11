import PocketBase from 'pocketbase';

// Server-side PB client (no auth needed for public reads)
export const pb = new PocketBase(process.env.PB_URL || 'https://pocketbase.scaleupcrm.com');
pb.autoCancellation(false);

// Disable auto-refresh on the server (no localStorage available)
if (typeof window === 'undefined') {
  // @ts-ignore
  pb.authStore.onChange(() => {});
}

// ─── Calendar helpers ──────────────────────────────────────────────────────────
// HEAL uses a 5-year content rotation. Each year of a 5-year cycle has its own
// 366-day content set. After 5 years, the cycle restarts.
//
//   yearCycle (1-5) = ((year - HEAL_EPOCH_YEAR) % 5) + 1
//   dayOfYear (1-366)
//
// Records carry a `launch_batch` field (B1..B5) indicating which year of the
// 5-year cycle they belong to. Helpers below pick the right record by combining
// (yearCycle, dayOfYear) so:
//   - same calendar date in the same cycle → same content
//   - same calendar date in a different cycle → different content
//   - cycle repeats every 5 years

export const HEAL_EPOCH_YEAR = 2026;
export const HEAL_CYCLE_YEARS = 5;

export type CalendarCoord = {
  year: number;          // 2026, 2027, ...
  yearCycle: number;     // 1-5
  dayOfYear: number;     // 1-366
  cycleDay: number;      // 1 - (HEAL_CYCLE_YEARS * 366) — continuous day across the cycle
  label: string;         // "Year 1 · Day 159 of 366"
  batchCode: string;     // "B1".."B5"
};

export function getCalendarCoord(date: Date = new Date()): CalendarCoord {
  const year = date.getFullYear();
  const yearCycle = ((year - HEAL_EPOCH_YEAR) % HEAL_CYCLE_YEARS) + 1; // 1-5
  const start = new Date(year, 0, 0);
  const dayOfYear = Math.floor((date.getTime() - start.getTime()) / 86400000); // 1-366
  const yearsIntoEpoch = year - HEAL_EPOCH_YEAR;
  const cycleDay = yearsIntoEpoch * 366 + dayOfYear; // 1, 367, 733, ...
  const batchCode = `B${yearCycle}`;
  const label = `Year ${yearCycle} · Day ${dayOfYear} of 366`;
  return { year, yearCycle, dayOfYear, cycleDay, label, batchCode };
}

// Helper: get a record by slug (server-side)
export async function getBySlug<T = any>(col: string, slug: string): Promise<T | null> {
  try {
    return await pb.collection(col).getFirstListItem(`slug = "${slug}"`);
  } catch {
    return null;
  }
}

// Helper: get all published records (or top N if limit is provided)
export async function getPublished<T = any>(col: string, sort = '-created', filter = 'is_published = true', limit?: number): Promise<T[]> {
  try {
    const all = (await pb.collection(col).getFullList({ sort, filter })) as unknown as T[];
    return limit ? all.slice(0, limit) : all;
  } catch {
    return [];
  }
}

// Helper: pick a deterministic record from a list given a (yearCycle, dayOfYear) pair.
// Different year-cycles yield different picks for the same day-of-year.
function pickByCycle<T>(list: T[], coord: CalendarCoord): T {
  // Combine year cycle and day-of-year so each cycle gets its own 366-day rotation
  const seed = coord.cycleDay; // unique day across the 5-year cycle
  return list[((seed % list.length) + list.length) % list.length];
}

// Helper: get today's meditation for the current year-cycle
export async function getDailyMeditation<T = any>(coord: CalendarCoord = getCalendarCoord()): Promise<T | null> {
  try {
    // Try exact (yearCycle batch + dayOfYear) match first
    return await pb.collection('HEAL_meditations').getFirstListItem(
      `launch_batch = "${coord.batchCode}" && day_of_year = ${coord.dayOfYear} && is_published = true`
    );
  } catch {
    // Fallback: deterministic pick from the current year-cycle's batch
    try {
      const all = await pb.collection('HEAL_meditations').getFullList({
        filter: `launch_batch = "${coord.batchCode}" && is_published = true`,
        sort: 'sort_order,id',
      }) as unknown as T[];
      if (all.length === 0) {
        // Last resort: any published meditation
        const fallback = await pb.collection('HEAL_meditations').getFullList({ filter: 'is_published = true' }) as unknown as T[];
        if (fallback.length === 0) return null;
        return pickByCycle(fallback, coord);
      }
      return pickByCycle(all, coord);
    } catch {
      return null;
    }
  }
}

// Helper: get the daily quote for the current year-cycle
export async function getDailyQuote<T = any>(coord: CalendarCoord = getCalendarCoord()): Promise<T | null> {
  try {
    // Try exact match first
    const exact = await pb.collection('HEAL_quotes').getFirstListItem(
      `day_of_year = ${coord.dayOfYear} && is_published = true`
    ).catch(() => null);
    if (exact) return exact as T;

    // Fallback: deterministic pick from all published quotes using cycle day
    const all = await pb.collection('HEAL_quotes').getFullList({ filter: 'is_published = true' }) as unknown as T[];
    if (all.length === 0) return null;
    return pickByCycle(all, coord);
  } catch {
    return null;
  }
}

// Helper: get the daily scripture for the current year-cycle
export async function getDailyScripture<T = any>(coord: CalendarCoord = getCalendarCoord()): Promise<T | null> {
  try {
    const exact = await pb.collection('HEAL_scriptures').getFirstListItem(
      `day_of_year = ${coord.dayOfYear} && is_published = true`
    ).catch(() => null);
    if (exact) return exact as T;

    const all = await pb.collection('HEAL_scriptures').getFullList({ filter: 'is_published = true', sort: 'sort_order' }) as unknown as T[];
    if (all.length === 0) return null;
    return pickByCycle(all, coord);
  } catch {
    return null;
  }
}

// Helper: get the daily praise song for the current year-cycle
export async function getDailyPraise<T = any>(coord: CalendarCoord = getCalendarCoord()): Promise<T | null> {
  try {
    const all = await pb.collection('HEAL_praise').getFullList({ filter: 'is_published = true', sort: 'sort_order' }) as unknown as T[];
    if (all.length === 0) return null;
    return pickByCycle(all, coord);
  } catch {
    return null;
  }
}

// Helper: get a prayer for the current year-cycle, optionally filtered by category
export async function getDailyPrayer<T = any>(category?: string, coord: CalendarCoord = getCalendarCoord()): Promise<T | null> {
  try {
    const filter = category
      ? `category = "${category}" && is_published = true`
      : `is_published = true`;
    const all = await pb.collection('HEAL_prayers').getFullList({ filter, sort: 'sort_order' }) as unknown as T[];
    if (all.length === 0) return null;
    return pickByCycle(all, coord);
  } catch {
    return null;
  }
}

// Helper: get a quote by category (for the rotating wisdom section)
export async function getQuoteByDay<T = any>(offset = 0, coord: CalendarCoord = getCalendarCoord()): Promise<T | null> {
  try {
    const all = await pb.collection('HEAL_quotes').getFullList({ filter: 'is_published = true' }) as unknown as T[];
    if (all.length === 0) return null;
    const day = coord.cycleDay + offset;
    return all[((day % all.length) + all.length) % all.length] as T;
  } catch {
    return null;
  }
}

// ─── Programs ──────────────────────────────────────────────────────────────────

export type HEALProgram = {
  id: string;
  slug: string;
  title: string;
  tagline: string;
  description: string;
  duration_label: string;
  category: string;
  theme_color: string;
  illustration_url: string;
  illustration_prompt: string;
  badge_name: string;
  badge_affirmation: string;
  badge_scripture_ref: string;
  badge_scripture_text: string;
  badge_image_prompt: string;
  badge_image_path: string;
  step_count: number;
  sort_order: number;
  is_published: boolean;
};

export type HEALProgramStep = {
  id: string;
  program: string;
  order_index: number;
  title: string;
  reflection: string;
  scripture_ref: string;
  scripture_text: string;
  practice_kind: string;
  practice_title: string;
  practice_slug: string;
  response_headline: string;
  response_body: string;
  response_scripture: string;
  sort_order: number;
  is_published: boolean;
};

export async function getAllPrograms<T = HEALProgram>(): Promise<T[]> {
  return getPublished<T>('HEAL_programs', 'sort_order,id');
}

export async function getProgramBySlug<T = HEALProgram>(slug: string): Promise<T | null> {
  return getBySlug<T>('HEAL_programs', slug);
}

export async function getProgramSteps<T = HEALProgramStep>(programSlug: string): Promise<T[]> {
  try {
    const all = await pb.collection('HEAL_program_steps').getFullList({
      filter: `program = "${programSlug}" && is_published = true`,
      sort: 'order_index',
    }) as unknown as T[];
    return all;
  } catch {
    return [];
  }
}

export async function getProgramStep<T = HEALProgramStep>(programSlug: string, orderIndex: number): Promise<T | null> {
  try {
    return await pb.collection('HEAL_program_steps').getFirstListItem(
      `program = "${programSlug}" && order_index = ${orderIndex} && is_published = true`
    ) as unknown as T;
  } catch {
    return null;
  }
}
