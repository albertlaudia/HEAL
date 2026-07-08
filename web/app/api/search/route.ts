// HEAL — Search across all content types.
//
// Single endpoint that searches:
//   - meditations (271 records)
//   - praise (124)
//   - prayers (67)
//   - quotes (60)
//   - scriptures (31)
//   - breathwork (6)
//   - essays/Reflections (3)
//   - bible_readings (365 — by book name or chapter)
//
// Returns ranked results (title matches first, then body matches).
// Used by the global search modal in the header.

import { NextRequest, NextResponse } from 'next/server';
import { pb } from '@/lib/pb';
import type { RecordModel } from 'pocketbase';

const COLLECTIONS: Array<{
  name: string;
  titleFields: string[];
  bodyFields: string[];
  type: 'meditation' | 'praise' | 'prayer' | 'scripture' | 'essay' | 'breathwork' | 'quote' | 'bible';
  urlBase: string;
  illustrationField?: string;
}> = [
  {
    name: 'HEAL_meditations',
    titleFields: ['title', 'scripture_ref'],
    bodyFields: ['body', 'reflection', 'prayer', 'tags', 'theme', 'season'],
    type: 'meditation',
    urlBase: '/meditate',
    illustrationField: 'illustration_url',
  },
  {
    name: 'HEAL_praise',
    titleFields: ['title', 'subtitle'],
    bodyFields: ['description', 'reflection', 'lyrics', 'tags', 'scripture_refs', 'category', 'mood'],
    type: 'praise',
    urlBase: '/praise',
    illustrationField: 'illustration_url',
  },
  {
    name: 'HEAL_prayers',
    titleFields: ['title', 'subtitle'],
    bodyFields: ['body', 'tags', 'occasion', 'scripture_refs'],
    type: 'prayer',
    urlBase: '/prayers',
  },
  {
    name: 'HEAL_scriptures',
    titleFields: ['reference', 'verse_text', 'scripture_text'],
    bodyFields: ['reflection', 'tags', 'theme'],
    type: 'scripture',
    urlBase: '/scripture',  // linked to parent + hash (#{slug}) for deep-link
  },
  {
    name: 'HEAL_essays',
    titleFields: ['title', 'subtitle'],
    bodyFields: ['body', 'tags'],
    type: 'essay',
    urlBase: '/essays',
  },
  {
    name: 'HEAL_breathwork',
    titleFields: ['name'],
    bodyFields: ['description', 'benefits', 'tags'],
    type: 'breathwork',
    urlBase: '/breathe',
  },
  {
    name: 'HEAL_quotes',
    titleFields: ['text', 'author'],
    bodyFields: ['text', 'author', 'source', 'tags'],
    type: 'quote',
    urlBase: '/about',
  },
];

type SearchHit = {
  type: string;
  id: string;
  slug: string;
  title: string;
  subtitle: string;
  excerpt: string;
  illustrationUrl: string;
  url: string;
  score: number;
  matchField: string;
};

function getString(rec: RecordModel, field: string): string {
  const v = rec[field];
  if (typeof v === 'string') return v;
  if (Array.isArray(v)) return v.join(' ');
  return '';
}

function scoreRecord(rec: RecordModel, q: string, conf: typeof COLLECTIONS[0]): number {
  const query = q.toLowerCase();
  const queryTokens = query.split(/\s+/).filter((t) => t.length > 1);

  let score = 0;
  let firstField = '';

  // Title fields weighted highest
  for (const f of conf.titleFields) {
    const v = getString(rec, f).toLowerCase();
    if (!v) continue;
    if (v === query) {
      score += 100;
      if (!firstField) firstField = f;
    } else if (v.startsWith(query)) {
      score += 50;
      if (!firstField) firstField = f;
    } else if (v.includes(query)) {
      score += 25;
      if (!firstField) firstField = f;
    } else {
      for (const t of queryTokens) {
        if (v.includes(t)) {
          score += 5;
          if (!firstField) firstField = f;
          break;
        }
      }
    }
  }

  // Body fields lower weight
  for (const f of conf.bodyFields) {
    const v = getString(rec, f).toLowerCase();
    if (!v) continue;
    if (v.includes(query)) {
      score += 10;
      if (!firstField) firstField = f;
    } else {
      for (const t of queryTokens) {
        if (v.includes(t)) {
          score += 2;
          if (!firstField) firstField = f;
          break;
        }
      }
    }
  }

  return score;
}

function buildExcerpt(rec: RecordModel, q: string, conf: typeof COLLECTIONS[0]): string {
  // Try to find a body field with the query and return a window around it
  for (const f of conf.bodyFields) {
    const v = getString(rec, f);
    if (!v) continue;
    const lower = v.toLowerCase();
    const idx = lower.indexOf(q.toLowerCase());
    if (idx >= 0) {
      const start = Math.max(0, idx - 40);
      const end = Math.min(v.length, idx + q.length + 80);
      const slice = v.slice(start, end).replace(/\s+/g, ' ').trim();
      return (start > 0 ? '… ' : '') + slice + (end < v.length ? ' …' : '');
    }
  }
  // Fallback: just first body field, first 120 chars
  for (const f of conf.bodyFields) {
    const v = getString(rec, f);
    if (v) {
      return v.slice(0, 120).replace(/\s+/g, ' ').trim() + (v.length > 120 ? ' …' : '');
    }
  }
  return '';
}

export async function GET(req: NextRequest) {
  const url = new URL(req.url);
  const q = url.searchParams.get('q')?.trim() || '';
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '40', 10), 100);

  if (q.length < 2) {
    return NextResponse.json({ q, hits: [], totalHits: 0, took: 0 });
  }

  const t0 = Date.now();
  const hits: SearchHit[] = [];

  // Search in parallel across collections (cap by perPage=200; for HEAL that
  // catches everything except bible readings)
  const collectionPromises = COLLECTIONS.map(async (conf) => {
    try {
      const escQ = q.replace(/"/g, '\\"');
      const conditions = conf.titleFields.concat(conf.bodyFields).map((f) => `${f} ~ "${escQ}"`);
      const filter = conditions.length === 1
        ? conditions[0]
        : conditions.map((c) => `(${c})`).join(' || ');
      const records = await pb.collection(conf.name).getList(1, 200, {
        filter,
        sort: '-created',
      });
      // Debug log to stderr (always)
      console.log(`[search] ${conf.name} filter=${filter} got=${records.items.length} totalItems=${records.totalItems}`);

      for (const rec of records.items) {
        const s = scoreRecord(rec, q, conf);
        if (s > 0) {
          const title = conf.titleFields
            .map((f) => getString(rec, f))
            .find((t) => t.length > 0) || '';
          const subtitle = conf.titleFields
            .filter((f) => f !== conf.titleFields[0])
            .map((f) => getString(rec, f))
            .find((t) => t.length > 0) || '';
          const illustrationUrl = conf.illustrationField
            ? getString(rec, conf.illustrationField)
            : '';
          const slug = (rec.slug as string) || rec.id;
          // Scripture uses an in-page anchor (accordion id) instead of a deep route
          const url = conf.type === 'scripture'
            ? `${conf.urlBase}#${slug}`
            : `${conf.urlBase}/${slug}`;
          hits.push({
            type: conf.type,
            id: rec.id,
            slug,
            title,
            subtitle,
            excerpt: buildExcerpt(rec, q, conf),
            illustrationUrl,
            url,
            score: s,
            matchField: '',
          });
        }
      }
    } catch (e: any) {
      console.error(`[search] ${conf.name} ERROR:`, e?.message || e, '| status:', e?.status);
    }
  });

  await Promise.all(collectionPromises);

  // Sort by score desc, then title
  hits.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));

  // Special case: bible book search (e.g. "psalm" or "matthew")
  // Reads the precomputed bible-plan.json (book is nested in readings[].book
  // so we can't PB-filter on it). Returns one hit per book that matches.
  if (q.length >= 3) {
    try {
      const fs = await import('fs/promises');
      const path = await import('path');
      // Try multiple paths for the plan file (dev vs prod)
      const candidates = [
        path.join(process.cwd(), 'public', 'bible-plan.json'),
        path.join(process.cwd(), '..', 'public', 'bible-plan.json'),
        path.join(process.cwd(), 'web', 'public', 'bible-plan.json'),
      ];
      let plan: Array<{ day_number: number; title: string; readings: Array<{ book: string }> }> | null = null;
      for (const c of candidates) {
        try {
          const raw = await fs.readFile(c, 'utf-8');
          plan = JSON.parse(raw);
          break;
        } catch {}
      }
      if (plan) {
        const ql = q.toLowerCase();
        const bookMatches = new Map<string, { count: number; first: { day_number: number; title: string } }>();
        for (const day of plan) {
          for (const r of day.readings) {
            if (r.book.toLowerCase().includes(ql)) {
              if (!bookMatches.has(r.book)) {
                bookMatches.set(r.book, { count: 0, first: { day_number: day.day_number, title: day.title } });
              }
              bookMatches.get(r.book)!.count += 1;
            }
          }
        }
        for (const [book, m] of bookMatches) {
          hits.push({
            type: 'bible',
            id: `bible-${book.toLowerCase().replace(/\s+/g, '-')}`,
            slug: book.toLowerCase().replace(/\s+/g, '-'),
            title: book,
            subtitle: `${m.count} reading${m.count === 1 ? '' : 's'} · starts day ${m.first.day_number}`,
            excerpt: `First reading: ${m.first.title}`,
            illustrationUrl: '',
            url: `/bible/day/${m.first.day_number}`,
            score: 30,
            matchField: 'book',
          });
        }
      }
    } catch (e) {
      // bible-plan.json missing or unparseable; skip silently
    }
  }

  // Re-sort after bible additions
  hits.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));

  const top = hits.slice(0, limit);
  const took = Date.now() - t0;

  return NextResponse.json({
    q,
    hits: top,
    totalHits: hits.length,
    took,
  });
}
