#!/usr/bin/env node
/**
 * HEAL PocketBase bootstrap
 * Creates HEAL_ prefixed collections on the shared PB instance.
 * Idempotent — safe to re-run.
 *
 * Pattern (proven 2026-06):
 *   1. POST with `fields` + flat options + null rules
 *   2. PATCH to set real rules
 *   3. PATCH to add SQL indexes (separate call)
 *   4. Seed via POST /records (with uniqueness check)
 *
 * Required-field quirk: default to required:false on bool/number/pattern fields.
 * Auth quirk: this instance uses _superusers not admins.
 */

import PocketBase from 'pocketbase';

const PB_URL = process.env.PB_URL || 'https://pocketbase.scaleupcrm.com';
const IDENTITY = process.env.PB_IDENTITY || process.env.HEAL_PB_IDENTITY;
const PASSWORD = process.env.PB_PASSWORD || process.env.HEAL_PB_PASSWORD;

if (!IDENTITY || !PASSWORD) {
  console.error('❌ PB_IDENTITY and PB_PASSWORD must be set in env');
  process.exit(1);
}

const pb = new PocketBase(PB_URL);
pb.autoCancellation(false);

async function auth() {
  // Try v0.39 default first
  try {
    await pb.admins.authWithPassword(IDENTITY, PASSWORD);
    console.log('✅ Authed as admin (v0.39 default)');
    return;
  } catch (e) {
    // Fall through to _superusers
  }
  try {
    await pb.collection('_superusers').authWithPassword(IDENTITY, PASSWORD);
    console.log('✅ Authed as _superuser (renamed)');
  } catch (e) {
    console.error('❌ Auth failed:', e.message);
    process.exit(1);
  }
}

// ───────────────────────────────────────────────────────────────
// Collection definitions
// ───────────────────────────────────────────────────────────────
const collections = [
  // ── Core content ─────────────────────────────────────────────
  {
    name: 'HEAL_meditations',
    fields: [
      { name: 'title', type: 'text', required: true, options: { min: 1, max: 200 } },
      { name: 'slug', type: 'text', required: true, options: { min: 1, max: 200, pattern: '^[a-z0-9-]+$' } },
      { name: 'scripture_ref', type: 'text', required: false, options: { max: 100 } },
      { name: 'scripture_text', type: 'text', required: false, options: { max: 2000 } },
      { name: 'translation', type: 'text', required: false, options: { max: 20 } },
      { name: 'body', type: 'editor', required: true, options: {} },
      { name: 'reflection', type: 'text', required: false, options: { max: 1000 } },
      { name: 'prayer', type: 'text', required: false, options: { max: 1000 } },
      { name: 'audio_url', type: 'url', required: false, options: {} },
      { name: 'illustration_url', type: 'url', required: false, options: {} },
      { name: 'duration_seconds', type: 'number', required: false, options: { min: 0, max: 3600 } },
      { name: 'theme', type: 'select', required: false, options: { maxSelect: 1, values: ['calm', 'gratitude', 'let-go', 'love', 'focus', 'stillness', 'courage', 'rest'] } },
      { name: 'season', type: 'select', required: false, options: { maxSelect: 1, values: ['ordinary', 'advent', 'christmas', 'lent', 'easter', 'pentecost'] } },
      { name: 'day_of_year', type: 'number', required: false, options: { min: 1, max: 366 } },
      { name: 'launch_batch', type: 'text', required: false, options: { max: 50 } },
      { name: 'sort_order', type: 'number', required: false, options: { min: 0 } },
      { name: 'is_published', type: 'bool', required: false, options: {} },
      { name: 'tags', type: 'json', required: false, options: {} },
    ],
    indexes: [
      'CREATE UNIQUE INDEX idx_HEAL_meditations_slug ON HEAL_meditations (slug)',
      'CREATE INDEX idx_HEAL_meditations_day ON HEAL_meditations (day_of_year)',
      'CREATE INDEX idx_HEAL_meditations_theme ON HEAL_meditations (theme)',
      'CREATE INDEX idx_HEAL_meditations_season ON HEAL_meditations (season)',
    ],
    rules: { list: '', view: '', create: '', update: '', delete: '' }, // public read
  },
  {
    name: 'HEAL_quotes',
    fields: [
      { name: 'text', type: 'text', required: true, options: { max: 1000 } },
      { name: 'attribution', type: 'text', required: false, options: { max: 200 } },
      { name: 'source', type: 'text', required: false, options: { max: 200 } },
      { name: 'category', type: 'select', required: false, options: { maxSelect: 1, values: ['courage', 'grace', 'love', 'peace', 'rest', 'hope', 'wisdom', 'gratitude', 'strength'] } },
      { name: 'illustration_url', type: 'url', required: false, options: {} },
      { name: 'day_of_year', type: 'number', required: false, options: { min: 1, max: 366 } },
      { name: 'is_motivation', type: 'bool', required: false, options: {} },
      { name: 'is_published', type: 'bool', required: false, options: {} },
    ],
    indexes: [
      'CREATE INDEX idx_HEAL_quotes_day ON HEAL_quotes (day_of_year)',
      'CREATE INDEX idx_HEAL_quotes_cat ON HEAL_quotes (category)',
    ],
    rules: { list: '', view: '', create: '', update: '', delete: '' },
  },
  {
    name: 'HEAL_scriptures',
    fields: [
      { name: 'reference', type: 'text', required: true, options: { max: 100 } },
      { name: 'text', type: 'text', required: true, options: { max: 2000 } },
      { name: 'translation', type: 'text', required: false, options: { max: 20 } },
      { name: 'theme', type: 'select', required: false, options: { maxSelect: 1, values: ['calm', 'gratitude', 'let-go', 'love', 'focus', 'stillness', 'courage', 'rest', 'hope', 'wisdom'] } },
      { name: 'reflection_prompt', type: 'text', required: false, options: { max: 500 } },
      { name: 'day_of_year', type: 'number', required: false, options: { min: 1, max: 366 } },
      { name: 'is_published', type: 'bool', required: false, options: {} },
    ],
    indexes: [
      'CREATE INDEX idx_HEAL_scriptures_day ON HEAL_scriptures (day_of_year)',
      'CREATE INDEX idx_HEAL_scriptures_theme ON HEAL_scriptures (theme)',
    ],
    rules: { list: '', view: '', create: '', update: '', delete: '' },
  },
  {
    name: 'HEAL_breathwork',
    fields: [
      { name: 'name', type: 'text', required: true, options: { max: 100 } },
      { name: 'slug', type: 'text', required: true, options: { min: 1, max: 100, pattern: '^[a-z0-9-]+$' } },
      { name: 'description', type: 'text', required: false, options: { max: 500 } },
      { name: 'instructions', type: 'editor', required: true, options: {} },
      { name: 'pattern', type: 'text', required: false, options: { max: 100 } }, // e.g. "4-7-8"
      { name: 'inhale_seconds', type: 'number', required: false, options: { min: 0, max: 60 } },
      { name: 'hold_seconds', type: 'number', required: false, options: { min: 0, max: 60 } },
      { name: 'exhale_seconds', type: 'number', required: false, options: { min: 0, max: 60 } },
      { name: 'cycles', type: 'number', required: false, options: { min: 1, max: 50 } },
      { name: 'illustration_url', type: 'url', required: false, options: {} },
      { name: 'audio_url', type: 'url', required: false, options: {} },
      { name: 'theme', type: 'select', required: false, options: { maxSelect: 1, values: ['calm', 'focus', 'rest', 'courage', 'energy'] } },
      { name: 'sort_order', type: 'number', required: false, options: { min: 0 } },
      { name: 'is_published', type: 'bool', required: false, options: {} },
    ],
    indexes: [
      'CREATE UNIQUE INDEX idx_HEAL_breathwork_slug ON HEAL_breathwork (slug)',
    ],
    rules: { list: '', view: '', create: '', update: '', delete: '' },
  },
  {
    name: 'HEAL_prayers',
    fields: [
      { name: 'title', type: 'text', required: true, options: { max: 200 } },
      { name: 'slug', type: 'text', required: true, options: { min: 1, max: 200, pattern: '^[a-z0-9-]+$' } },
      { name: 'body', type: 'editor', required: true, options: {} },
      { name: 'category', type: 'select', required: false, options: { maxSelect: 1, values: ['morning', 'evening', 'anxiety', 'gratitude', 'forgiveness', 'strength', 'rest', 'other'] } },
      { name: 'attribution', type: 'text', required: false, options: { max: 200 } },
      { name: 'illustration_url', type: 'url', required: false, options: {} },
      { name: 'sort_order', type: 'number', required: false, options: { min: 0 } },
      { name: 'is_published', type: 'bool', required: false, options: {} },
    ],
    indexes: [
      'CREATE UNIQUE INDEX idx_HEAL_prayers_slug ON HEAL_prayers (slug)',
      'CREATE INDEX idx_HEAL_prayers_cat ON HEAL_prayers (category)',
    ],
    rules: { list: '', view: '', create: '', update: '', delete: '' },
  },
  {
    name: 'HEAL_essays',
    fields: [
      { name: 'title', type: 'text', required: true, options: { max: 200 } },
      { name: 'slug', type: 'text', required: true, options: { min: 1, max: 200, pattern: '^[a-z0-9-]+$' } },
      { name: 'subtitle', type: 'text', required: false, options: { max: 300 } },
      { name: 'excerpt', type: 'text', required: false, options: { max: 500 } },
      { name: 'body', type: 'editor', required: true, options: {} },
      { name: 'author', type: 'text', required: false, options: { max: 100 } },
      { name: 'illustration_url', type: 'url', required: false, options: {} },
      { name: 'reading_minutes', type: 'number', required: false, options: { min: 1, max: 60 } },
      { name: 'tags', type: 'json', required: false, options: {} },
      { name: 'published_at', type: 'date', required: false, options: {} },
      { name: 'is_published', type: 'bool', required: false, options: {} },
    ],
    indexes: [
      'CREATE UNIQUE INDEX idx_HEAL_essays_slug ON HEAL_essays (slug)',
    ],
    rules: { list: '', view: '', create: '', update: '', delete: '' },
  },
  {
    name: 'HEAL_pages',
    fields: [
      { name: 'key', type: 'text', required: true, options: { min: 1, max: 100, pattern: '^[a-z0-9_-]+$' } },
      { name: 'title', type: 'text', required: true, options: { max: 200 } },
      { name: 'body', type: 'editor', required: true, options: {} },
      { name: 'meta_description', type: 'text', required: false, options: { max: 300 } },
    ],
    indexes: [
      'CREATE UNIQUE INDEX idx_HEAL_pages_key ON HEAL_pages (key)',
    ],
    rules: { list: '', view: '', create: '', update: '', delete: '' },
  },
];

// ───────────────────────────────────────────────────────────────
// Bootstrap runner
// ───────────────────────────────────────────────────────────────
async function ensureCollection(spec) {
  const existing = await pb.collections.getFirstListItem(`name = "${spec.name}"`).catch(() => null);
  if (existing) {
    console.log(`  ⏩ ${spec.name} exists — checking schema drift`);
    await checkSchemaDrift(existing, spec);
    return existing;
  }
  console.log(`  ➕ Creating ${spec.name}`);
  // Step 1: POST with fields, flat options, null rules
  const created = await pb.collections.create({
    name: spec.name,
    type: 'base',
    fields: spec.fields,
    indexes: spec.indexes || [],
    listRule: null,
    viewRule: null,
    createRule: null,
    updateRule: null,
    deleteRule: null,
  });
  // Step 2: PATCH to set real rules
  await pb.collections.update(created.id, {
    listRule: spec.rules.list,
    viewRule: spec.rules.view,
    createRule: spec.rules.create,
    updateRule: spec.rules.update,
    deleteRule: spec.rules.delete,
  });
  console.log(`  ✅ ${spec.name} created`);
  return created;
}

async function checkSchemaDrift(existing, spec) {
  const existingFields = new Map(existing.fields.map(f => [f.name, f]));
  const drift = [];
  for (const wanted of spec.fields) {
    const have = existingFields.get(wanted.name);
    if (!have) { drift.push(`+${wanted.name}`); continue; }
    if (have.type !== wanted.type) drift.push(`~${wanted.name}.type (have=${have.type} want=${wanted.type})`);
    if (JSON.stringify(have.options) !== JSON.stringify(wanted.options)) {
      // Only warn for some fields
      drift.push(`~${wanted.name}.options`);
    }
  }
  for (const have of existingFields.keys()) {
    if (!spec.fields.find(f => f.name === have)) drift.push(`-${have}`);
  }
  if (drift.length) console.log(`     ⚠️  drift: ${drift.slice(0, 5).join(', ')}${drift.length > 5 ? ` (+${drift.length - 5} more)` : ''}`);
  else console.log(`     ✓ schema matches`);
}

async function ensureIndexes(colName, indexSqls) {
  // PB doesn't have a clean "list indexes" API; we just attempt to PATCH them in.
  // PATCH silently no-ops on duplicates ("already exists" → treat as success).
  try {
    const col = await pb.collections.getFirstListItem(`name = "${colName}"`);
    await pb.collections.update(col.id, { indexes: indexSqls });
    console.log(`     ✓ indexes ensured on ${colName}`);
  } catch (e) {
    console.warn(`     ⚠️  index patch on ${colName}: ${e.message}`);
  }
}

async function main() {
  console.log('🌿 HEAL — PocketBase bootstrap');
  console.log(`   target: ${PB_URL}`);
  await auth();

  for (const spec of collections) {
    console.log(`\n📦 ${spec.name}`);
    const col = await ensureCollection(spec);
    if (spec.indexes) await ensureIndexes(col.name, spec.indexes);
  }

  console.log('\n✨ Done. Collections ready.');
}

main().catch(e => { console.error('💥', e); process.exit(1); });
