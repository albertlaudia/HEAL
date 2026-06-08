#!/usr/bin/env node
/**
 * HEAL — Expand all select field values to include every value found in
 * the JSON content files. One-shot fix; safe to re-run.
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

const pb = new PocketBase(PB_URL);
pb.autoCancellation(false);
try { await pb.admins.authWithPassword(IDENTITY, PASSWORD); } catch { await pb.collection('_superusers').authWithPassword(IDENTITY, PASSWORD); }

// Walk all JSON files, collect every string used in any 'select' field
const selectValues = new Map(); // fieldKey -> Set(values)

async function walkJson(dir) {
  let entries;
  try { entries = await readdir(dir, { withFileTypes: true }); } catch { return; }
  for (const e of entries) {
    const p = join(dir, e.name);
    if (e.isDirectory()) await walkJson(p);
    else if (e.name.endsWith('.json')) {
      const data = JSON.parse(await readFile(p, 'utf8'));
      const list = Array.isArray(data) ? data : [data];
      for (const item of list) collectSelects(item, '');
    }
  }
}

function collectSelects(obj, prefix) {
  if (!obj || typeof obj !== 'object') return;
  for (const [k, v] of Object.entries(obj)) {
    if (typeof v === 'string' && v.length < 40 && /^[a-z][a-z0-9_-]*$/.test(v)) {
      const key = `${prefix}${k}`;
      if (!selectValues.has(key)) selectValues.set(key, new Set());
      selectValues.get(key).add(v);
    }
  }
}

await walkJson(CONTENT_DIR);

// Map JSON field names to collection field names (we know them)
const fieldMap = {
  meditations: { theme: 'theme', season: 'season' },
  quotes: { category: 'category' },
  prayers: { category: 'category' },
  breathwork: { theme: 'theme' },
  scriptures: { theme: 'theme' },
};

const colToFile = {
  HEAL_meditations: 'meditations',
  HEAL_quotes: 'quotes',
  HEAL_prayers: 'prayers',
  HEAL_breathwork: 'breathwork',
  HEAL_scriptures: 'scriptures',
};

for (const [colName, dir] of Object.entries(colToFile)) {
  const col = await pb.collections.getFirstListItem(`name = "${colName}"`);
  const map = fieldMap[dir];
  const newFields = col.fields.map(f => {
    if (f.type !== 'select') return f;
    const jsonName = Object.entries(map).find(([, v]) => v === f.name)?.[0];
    if (!jsonName) return f;
    const seen = selectValues.get(jsonName);
    if (!seen || seen.size === 0) return f;
    const merged = [...new Set([...f.values, ...seen])];
    if (merged.length === f.values.length) return f;
    return { ...f, values: merged };
  });
  const changed = newFields.some((f, i) => f !== col.fields[i]);
  if (changed) {
    await pb.collections.update(col.id, { fields: newFields, schema: newFields });
    console.log(`  ✓ ${colName} select values expanded`);
  } else {
    console.log(`  ⏩ ${colName} no change needed`);
  }
}

console.log('Done.');
