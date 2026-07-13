// HEAL — Postgres client (used by all /api/heal/* routes).
// Single shared client, server-side only, with a 5-min in-memory cache
// per collection to take load off Postgres.

import { Pool } from 'pg';

declare global {
  // eslint-disable-next-line no-var
  var __HEAL_PG_POOL__: Pool | undefined;
  // eslint-disable-next-line no-var
  var __HEAL_PG_CACHE__: Map<string, { expires: number; data: unknown }> | undefined;
}

function getPool(): Pool {
  if (!global.__HEAL_PG_POOL__) {
    const url = process.env.HEAL_PG_URL || 'postgresql://heal:heal_production_2026@heal-pg:5432/heal';
    global.__HEAL_PG_POOL__ = new Pool({
      connectionString: url,
      max: 10,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 5_000,
    });
  }
  return global.__HEAL_PG_POOL__;
}

function getCache(): Map<string, { expires: number; data: unknown }> {
  if (!global.__HEAL_PG_CACHE__) {
    global.__HEAL_PG_CACHE__ = new Map();
  }
  return global.__HEAL_PG_CACHE__;
}

/// Cached query helper. 5-min TTL per key.
export async function cachedQuery<T = Record<string, unknown>>(
  cacheKey: string,
  sql: string,
  params: unknown[] = [],
  ttlSeconds = 300,
): Promise<T[]> {
  const cache = getCache();
  const cached = cache.get(cacheKey);
  if (cached && cached.expires > Date.now()) {
    return cached.data as T[];
  }
  const pool = getPool();
  const result = await pool.query(sql, params);
  const data = result.rows as T[];
  // LRU-ish: cap at 256 entries
  if (cache.size > 256) {
    const firstKey = cache.keys().next().value;
    if (firstKey) cache.delete(firstKey);
  }
  cache.set(cacheKey, { expires: Date.now() + ttlSeconds * 1000, data });
  return data;
}

/// Invalidate a cache key (used after writes).
export function invalidateCache(prefix?: string) {
  const cache = getCache();
  if (!prefix) {
    cache.clear();
    return;
  }
  for (const k of Array.from(cache.keys())) {
    if (k.startsWith(prefix)) cache.delete(k);
  }
}

/// Convert snake_case DB rows to camelCase JSON (matches what mobile expects).
/// Postgres returns everything lowercase; we just normalize the keys.
function snakeToCamel<T extends Record<string, unknown>>(row: T): T {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(row)) {
    const camel = k.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    out[camel] = v;
  }
  return out as T;
}

export async function listRows<T extends Record<string, unknown>>(
  table: string,
  options: { where?: string; params?: unknown[]; orderBy?: string; limit?: number } = {},
): Promise<T[]> {
  const clauses: string[] = [];
  if (options.where) clauses.push(`WHERE ${options.where}`);
  if (options.orderBy) clauses.push(`ORDER BY ${options.orderBy}`);
  if (options.limit) clauses.push(`LIMIT ${options.limit}`);
  const sql = `SELECT * FROM ${table} ${clauses.join(' ')}`;
  const rows = await cachedQuery<T>(`list:${table}:${sql}:${JSON.stringify(options.params || [])}`, sql, options.params);
  return rows.map(snakeToCamel);
}

export async function getRow<T extends Record<string, unknown>>(
  table: string,
  where: string,
  params: unknown[],
): Promise<T | null> {
  const sql = `SELECT * FROM ${table} WHERE ${where} LIMIT 1`;
  const rows = await cachedQuery<T>(`get:${table}:${where}:${JSON.stringify(params)}`, sql, params);
  return rows.length ? snakeToCamel(rows[0]) : null;
}

/// Health check — used by the /api/health route.
export async function pgHealthCheck(): Promise<{ ok: boolean; latencyMs: number; error?: string }> {
  const start = Date.now();
  try {
    const pool = getPool();
    await pool.query('SELECT 1');
    return { ok: true, latencyMs: Date.now() - start };
  } catch (e) {
    return { ok: false, latencyMs: Date.now() - start, error: String(e) };
  }
}
