import { cachedQuery } from './db';
// HEAL — Generic list route for HEAL_* collections.
// Reads ?limit=, ?offset=, ?isPublished=, ?dayOfYear=, ?category=, etc.
// Returns the same JSON shape the mobile app expects from PB.

import { NextRequest, NextResponse } from 'next/server';
import {  getRow, invalidateCache } from './db';

export interface HealListOptions {
  table: string;
  defaultSort?: string;
  searchableFields?: string[];
  filterableFields?: string[];
}

export function buildHealListHandler(opts: HealListOptions) {
  return async function GET(req: NextRequest) {
    try {
      const url = new URL(req.url);
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '100', 10) || 100, 500);
      const offset = parseInt(url.searchParams.get('offset') || '0', 10) || 0;
      const filters: string[] = [];
      const params: unknown[] = [];

      for (const f of opts.filterableFields || []) {
        const v = url.searchParams.get(f);
        if (v !== null) {
          params.push(v);
          filters.push(`${f} = $${params.length}`);
        }
      }

      // Search: ILIKE across searchable fields
      const q = url.searchParams.get('q');
      if (q && opts.searchableFields?.length) {
        const orClauses = opts.searchableFields
          .map((f) => `${f}::text ILIKE $${params.length + 1}`)
          .join(' OR ');
        params.push(`%${q}%`);
        filters.push(`(${orClauses})`);
      }

      const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
      const order = opts.defaultSort || 'sort_order ASC, id ASC';
      const sql = `SELECT * FROM ${opts.table} ${where} ORDER BY ${order} LIMIT ${limit} OFFSET ${offset}`;
      const [rows, totalRes] = await Promise.all([
        cachedQuery<Record<string, unknown>>(
          `list:${opts.table}:${sql}:${JSON.stringify(params)}`,
          sql,
          params,
        ),
        // Total count uses the same WHERE, no LIMIT. Cached separately.
        cachedQuery<{ count: string }>(
          `count:${opts.table}:${where}:${JSON.stringify(params)}`,
          `SELECT count(*)::int AS count FROM ${opts.table} ${where}`,
          params,
        ),
      ]);

      return NextResponse.json({
        items: rows,
        total: parseInt(totalRes[0]?.count || '0', 10),
        limit, offset,
      });
    } catch (e) {
      return NextResponse.json({ error: String(e) }, { status: 500 });
    }
  };
}

export function buildHealGetHandler(opts: { table: string }) {
  return async function GET(
    _req: NextRequest,
    { params }: { params: Promise<{ id: string }> },
  ) {
    try {
      const { id } = await params;
      const row = await getRow<Record<string, unknown>>(opts.table, 'id = $1', [id]);
      if (!row) return NextResponse.json({ error: 'not found' }, { status: 404 });
      return NextResponse.json(row);
    } catch (e) {
      return NextResponse.json({ error: String(e) }, { status: 500 });
    }
  };
}

/// Optional: write handler for content collections.
/// Requires an admin token in `Authorization: Bearer <token>`.
export function buildHealWriteHandler(opts: { table: string }) {
  return async function POST(req: NextRequest) {
    try {
      const auth = req.headers.get('authorization') || '';
      if (auth !== `Bearer ${process.env.HEAL_ADMIN_TOKEN}`) {
        return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
      }
      const body = await req.json();
      const { Pool } = await import('pg');
      const pool = new Pool({
        connectionString: process.env.HEAL_PG_URL || 'postgresql://heal:heal_production_2026@heal-pg:5432/heal',
      });
      const cols = Object.keys(body);
      const vals = Object.values(body);
      const placeholders = cols.map((_, i) => `$${i + 1}`).join(',');
      const sql = `INSERT INTO ${opts.table} (${cols.map((c) => `"${c}"`).join(',')}) VALUES (${placeholders}) RETURNING *`;
      const result = await pool.query(sql, vals);
      await pool.end();
      invalidateCache(`list:${opts.table}`);
      return NextResponse.json(result.rows[0], { status: 201 });
    } catch (e) {
      return NextResponse.json({ error: String(e) }, { status: 500 });
    }
  };
}
