// Per-user in-memory cache for Firestore reads.
// ──────────────────────────────────────────────────────────────────
// WHY THIS EXISTS:
//   Even with the best schema, every `getDoc`/`getDocs` costs 1
//   read on Spark. With 1M users each opening the app twice a day,
//   that's 2M reads/day on a 50K/day cap.
//
//   The fix: in-memory cache, session-scoped. Once a user's
//   favorites are loaded, subsequent renders use the cached array.
//   On reload, we still hit Firestore once (cold start), then
//   stay cached.
//
//   Combined with Next.js's per-page SSR cache (revalidate=3600),
//   the actual Firestore read load on hot pages is < 1 per user
//   per session.
// ──────────────────────────────────────────────────────────────────

type CacheEntry<T> = { data: T; ts: number };
const cache = new Map<string, CacheEntry<any>>();
const TTL_MS = 5 * 60 * 1000; // 5 min in-memory TTL

export async function cached<T>(key: string, fetcher: () => Promise<T>): Promise<T> {
  const now = Date.now();
  const hit = cache.get(key);
  if (hit && now - hit.ts < TTL_MS) return hit.data as T;
  const data = await fetcher();
  cache.set(key, { data, ts: now });
  return data;
}

export function invalidate(prefix: string) {
  for (const k of cache.keys()) if (k.startsWith(prefix)) cache.delete(k);
}
