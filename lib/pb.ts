import PocketBase from 'pocketbase';

// Server-side PB client (no auth needed for public reads)
export const pb = new PocketBase(process.env.PB_URL || 'https://pocketbase.scaleupcrm.com');
pb.autoCancellation(false);

// Disable auto-refresh on the server (no localStorage available)
if (typeof window === 'undefined') {
  // @ts-ignore
  pb.authStore.onChange(() => {});
}

// Helper: get a record by slug (server-side)
export async function getBySlug<T = any>(col: string, slug: string): Promise<T | null> {
  try {
    return await pb.collection(col).getFirstListItem(`slug = "${slug}"`);
  } catch {
    return null;
  }
}

// Helper: get all published records
export async function getPublished<T = any>(col: string, sort = '-created', filter = 'is_published = true'): Promise<T[]> {
  try {
    return await pb.collection(col).getFullList({ sort, filter });
  } catch {
    return [];
  }
}

// Helper: get the daily meditation by day-of-year
export async function getDailyMeditation<T = any>(): Promise<T | null> {
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 0);
  const dayOfYear = Math.floor((now.getTime() - start.getTime()) / 86400000);
  try {
    return await pb.collection('HEAL_meditations').getFirstListItem(
      `day_of_year = ${dayOfYear} && is_published = true`
    );
  } catch {
    // Fallback: latest published
    try {
      return await pb.collection('HEAL_meditations').getFirstListItem('is_published = true');
    } catch {
      return null;
    }
  }
}

// Helper: get the daily quote (motivation word)
// Strategy: deterministic pick — dayOfYear % count, so every day of the year
// has a quote even if we only have 60 records. Stable across rebuilds.
export async function getDailyQuote<T = any>(): Promise<T | null> {
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 0);
  const dayOfYear = Math.floor((now.getTime() - start.getTime()) / 86400000);
  // First try exact day match
  try {
    return await pb.collection('HEAL_quotes').getFirstListItem(
      `day_of_year = ${dayOfYear} && is_published = true`
    );
  } catch {
    // Fallback: pick by deterministic offset
    try {
      const all = await pb.collection('HEAL_quotes').getFullList({ filter: 'is_published = true', sort: 'id' });
      if (all.length === 0) return null;
      const idx = dayOfYear % all.length;
      return all[idx] as T;
    } catch {
      return null;
    }
  }
}

// Helper: get the daily scripture
// Strategy: deterministic pick — dayOfYear % count, so every day has a scripture.
export async function getDailyScripture<T = any>(): Promise<T | null> {
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 0);
  const dayOfYear = Math.floor((now.getTime() - start.getTime()) / 86400000);
  try {
    return await pb.collection('HEAL_scriptures').getFirstListItem(
      `day_of_year = ${dayOfYear} && is_published = true`
    );
  } catch {
    try {
      const all = await pb.collection('HEAL_scriptures').getFullList({ filter: 'is_published = true', sort: 'sort_order' });
      if (all.length === 0) return null;
      return all[dayOfYear % all.length] as T;
    } catch {
      return null;
    }
  }
}

// Helper: get a quote by category (for the rotating wisdom section)
export async function getQuoteByDay<T = any>(offset = 0): Promise<T | null> {
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 0);
  const day = Math.floor((now.getTime() - start.getTime()) / 86400000) + offset;
  try {
    const list = await pb.collection('HEAL_quotes').getList(1, 1, {
      filter: `is_published = true`,
      sort: `-created`,
    });
    // pick deterministically by day
    if (list.items.length) {
      const all = await pb.collection('HEAL_quotes').getFullList({ filter: 'is_published = true' });
      return all[day % all.length] as T;
    }
    return null;
  } catch {
    return null;
  }
}
