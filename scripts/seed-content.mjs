#!/usr/bin/env node
/**
 * HEAL — Seed content from local JSON files into PocketBase.
 * Reads from /content/{meditations,quotes,scriptures,prayers,breathwork,essays,pages}/*.json
 * For each record, checks if slug exists; if not, creates it.
 *
 * Environment:
 *   PB_URL, PB_IDENTITY, PB_PASSWORD
 */

import PocketBase from 'pocketbase';
import { readdir, readFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const PB_URL = process.env.PB_URL || 'https://pocketbase.scaleupcrm.com';
const IDENTITY = process.env.PB_IDENTITY;
const PASSWORD = process.env.PB_PASSWORD;
const __dirname = dirname(fileURLToPath(import.meta.url));
const CONTENT_DIR = join(__dirname, '..', 'content');

if (!IDENTITY || !PASSWORD) { console.error('❌ Set PB_IDENTITY + PB_PASSWORD'); process.exit(1); }

const pb = new PocketBase(PB_URL);
pb.autoCancellation(false);

async function auth() {
  try { await pb.admins.authWithPassword(IDENTITY, PASSWORD); return; } catch {}
  await pb.collection('_superusers').authWithPassword(IDENTITY, PASSWORD);
}

async function upsertBySlug(colName, payload) {
  if (!payload.slug) throw new Error(`${colName} record missing slug`);
  const existing = await pb.collection(colName).getFirstListItem(`slug = "${payload.slug}"`).catch(() => null);
  if (existing) {
    await pb.collection(colName).update(existing.id, payload);
    return { action: 'updated', slug: payload.slug };
  }
  await pb.collection(colName).create(payload);
  return { action: 'created', slug: payload.slug };
}

async function upsertByRef(colName, payload, refField = 'reference') {
  if (!payload[refField]) throw new Error(`${colName} record missing ${refField}`);
  const existing = await pb.collection(colName).getFirstListItem(`${refField} = "${payload[refField].replace(/"/g, '\\"')}"`).catch(() => null);
  if (existing) {
    await pb.collection(colName).update(existing.id, payload);
    return { action: 'updated', ref: payload[refField] };
  }
  await pb.collection(colName).create(payload);
  return { action: 'created', ref: payload[refField] };
}

async function upsertByKey(colName, payload) {
  const existing = await pb.collection(colName).getFirstListItem(`key = "${payload.key}"`).catch(() => null);
  if (existing) {
    await pb.collection(colName).update(existing.id, payload);
    return { action: 'updated', key: payload.key };
  }
  await pb.collection(colName).create(payload);
  return { action: 'created', key: payload.key };
}

async function seedDir(dir, handler, mapper) {
  try {
    const files = (await readdir(dir)).filter(f => f.endsWith('.json'));
    if (!files.length) { console.log(`  (no files in ${dir})`); return; }
    let made = 0, updated = 0;
    for (const f of files) {
      const data = JSON.parse(await readFile(join(dir, f), 'utf8'));
      const list = Array.isArray(data) ? data : [data];
      for (const item of list) {
        const payload = mapper ? mapper(item) : item;
        const r = await handler(payload);
        if (r.action === 'created') made++; else updated++;
      }
    }
    console.log(`  ✓ ${dir.split('/').pop()}: ${made} created, ${updated} updated`);
  } catch (e) {
    if (e.code === 'ENOENT') console.log(`  (skip ${dir} — no dir)`);
    else throw e;
  }
}

async function main() {
  console.log('🌿 HEAL — content seed');
  await auth();

  await seedDir(join(CONTENT_DIR, 'meditations'),
    p => upsertBySlug('HEAL_meditations', p));
  await seedDir(join(CONTENT_DIR, 'quotes'),
    p => upsertBySlug('HEAL_quotes', { ...p, slug: p.slug || `quote-${p.text?.slice(0, 30).toLowerCase().replace(/[^a-z0-9]+/g, '-')}` }),
    p => ({ ...p, slug: p.slug || `quote-${p.text?.slice(0, 30).toLowerCase().replace(/[^a-z0-9]+/g, '-')}` }));
  await seedDir(join(CONTENT_DIR, 'scriptures'),
    p => upsertByRef('HEAL_scriptures', p, 'reference'));
  await seedDir(join(CONTENT_DIR, 'prayers'),
    p => upsertBySlug('HEAL_prayers', p));
  await seedDir(join(CONTENT_DIR, 'breathwork'),
    p => upsertBySlug('HEAL_breathwork', p));
  await seedDir(join(CONTENT_DIR, 'essays'),
    p => upsertBySlug('HEAL_essays', p));
  await seedDir(join(CONTENT_DIR, 'pages'),
    p => upsertByKey('HEAL_pages', p));

  console.log('✨ Seed complete');
}

main().catch(e => { console.error('💥', e); process.exit(1); });
