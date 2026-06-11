#!/usr/bin/env node
/**
 * HEAL — seed Programs + Program Steps to PocketBase
 * Reads /content/programs/*.json, upserts into HEAL_programs and HEAL_program_steps.
 *
 * Run: node scripts/seed-programs.mjs
 *
 * Requires PB_IDENTITY + PB_PASSWORD in env (uses _superusers auth).
 */

import PocketBase from 'pocketbase';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const PB_URL = process.env.PB_URL || 'https://pocketbase.scaleupcrm.com';
const IDENTITY = process.env.PB_IDENTITY || process.env.HEAL_PB_IDENTITY;
const PASSWORD = process.env.PASSWORD || process.env.PB_PASSWORD || process.env.HEAL_PB_PASSWORD;

if (!IDENTITY || !PASSWORD) {
  console.error('❌ PB_IDENTITY and PB_PASSWORD must be set in env');
  process.exit(1);
}

const pb = new PocketBase(PB_URL);
pb.autoCancellation(false);

async function auth() {
  try {
    await pb.admins.authWithPassword(IDENTITY, PASSWORD);
    console.log('✅ Authed as admin');
    return;
  } catch (e) {}
  try {
    await pb.collection('_superusers').authWithPassword(IDENTITY, PASSWORD);
    console.log('✅ Authed as _superuser');
  } catch (e) {
    console.error('❌ Auth failed:', e.message);
    process.exit(1);
  }
}

// ───────────────────────────────────────────────────────────────
// 1. Create collections if missing
// ───────────────────────────────────────────────────────────────
async function ensureCollection(name, fields, indexes = [], rules = {}) {
  let existing = null;
  try {
    existing = await pb.collections.getFirstListItem(`name = "${name}"`);
    console.log(`✓ ${name} exists`);
  } catch (e) {
    if (e.status !== 404) throw e;
    console.log(`+ Creating ${name}...`);
    // Step 1: POST with fields + null rules (so it accepts the create)
    const created = await pb.collections.create({
      name,
      type: 'base',
      fields,
      indexes,
      listRule: null,
      viewRule: null,
      createRule: null,
      updateRule: null,
      deleteRule: null,
    });
    // Step 2: PATCH real rules
    await pb.collections.update(created.id, {
      listRule: rules.list ?? '',
      viewRule: rules.view ?? '',
      createRule: rules.create ?? '',
      updateRule: rules.update ?? '',
      deleteRule: rules.delete ?? '',
    });
    existing = created;
    console.log(`  ✓ created`);
  }
}

async function ensurePrograms() {
  await ensureCollection('HEAL_programs', [
    { name: 'slug', type: 'text', required: true, options: { min: 1, max: 200, pattern: '^[a-z0-9-]+$' } },
    { name: 'title', type: 'text', required: true, options: { min: 1, max: 200 } },
    { name: 'tagline', type: 'text', required: false, options: { max: 500 } },
    { name: 'description', type: 'editor', required: false, options: {} },
    { name: 'duration_label', type: 'text', required: false, options: { max: 100 } },
    { name: 'category', type: 'select', required: false, maxSelect: 1, values: ['identity', 'anxiety', 'grief', 'rhythm', 'fear', 'body', 'gratitude', 'stillness'] },
    { name: 'theme_color', type: 'select', required: false, maxSelect: 1, values: ['sage', 'rose', 'teal', 'amber', 'muted-blue', 'indigo', 'warm-cream'] },
    { name: 'illustration_url', type: 'url', required: false, options: {} },
    { name: 'illustration_prompt', type: 'text', required: false, options: { max: 2000 } },
    { name: 'badge_name', type: 'text', required: false, options: { max: 100 } },
    { name: 'badge_affirmation', type: 'text', required: false, options: { max: 500 } },
    { name: 'badge_scripture_ref', type: 'text', required: false, options: { max: 100 } },
    { name: 'badge_scripture_text', type: 'text', required: false, options: { max: 1000 } },
    { name: 'badge_image_prompt', type: 'text', required: false, options: { max: 2000 } },
    { name: 'badge_image_path', type: 'text', required: false, options: { max: 200 } },
    { name: 'step_count', type: 'number', required: false, options: { min: 1, max: 30 } },
    { name: 'sort_order', type: 'number', required: false, options: { min: 0 } },
    { name: 'is_published', type: 'bool', required: false, options: {} },
  ], [
    'CREATE UNIQUE INDEX idx_HEAL_programs_slug ON HEAL_programs (slug)',
    'CREATE INDEX idx_HEAL_programs_cat ON HEAL_programs (category)',
  ], { list: '', view: '', create: '', update: '', delete: '' });
}

async function ensureProgramSteps() {
  await ensureCollection('HEAL_program_steps', [
    { name: 'program', type: 'text', required: true, options: { min: 1, max: 200, pattern: '^[a-z0-9-]+$' } },
    { name: 'order_index', type: 'number', required: true, options: { min: 1, max: 30 } },
    { name: 'title', type: 'text', required: true, options: { min: 1, max: 200 } },
    { name: 'reflection', type: 'editor', required: false, options: {} },
    { name: 'scripture_ref', type: 'text', required: false, options: { max: 100 } },
    { name: 'scripture_text', type: 'text', required: false, options: { max: 1000 } },
    { name: 'practice_kind', type: 'select', required: false, maxSelect: 1, values: ['breath', 'meditation', 'prayer', 'praise', 'scripture', 'none'] },
    { name: 'practice_title', type: 'text', required: false, options: { max: 200 } },
    { name: 'practice_slug', type: 'text', required: false, options: { max: 200 } },
    { name: 'response_headline', type: 'text', required: false, options: { max: 200 } },
    { name: 'response_body', type: 'text', required: false, options: { max: 2000 } },
    { name: 'response_scripture', type: 'text', required: false, options: { max: 100 } },
    { name: 'sort_order', type: 'number', required: false, options: { min: 0 } },
    { name: 'is_published', type: 'bool', required: false, options: {} },
  ], [
    'CREATE UNIQUE INDEX idx_HEAL_program_steps_prog_ord ON HEAL_program_steps (program, order_index)',
    'CREATE INDEX idx_HEAL_program_steps_prog ON HEAL_program_steps (program)',
  ], { list: '', view: '', create: '', update: '', delete: '' });
}

// ───────────────────────────────────────────────────────────────
// 2. Seed programs
// ───────────────────────────────────────────────────────────────
async function upsertProgram(p) {
  const data = {
    slug: p.id,
    title: p.title,
    tagline: p.tagline || '',
    description: p.description || '',
    duration_label: p.duration_label || '',
    category: p.category || '',
    theme_color: p.theme_color || '',
    illustration_url: p.illustration_url || '',
    illustration_prompt: p.illustration_prompt || '',
    badge_name: p.badge?.name || '',
    badge_affirmation: p.badge?.affirmation || '',
    badge_scripture_ref: p.badge?.scripture_ref || '',
    badge_scripture_text: p.badge?.scripture_text || '',
    badge_image_prompt: p.badge?.image_prompt || '',
    badge_image_path: p.badge?.image_path || '',
    step_count: p.steps?.length || 0,
    sort_order: 0,
    is_published: true,
  };
  // Find existing
  let existing = null;
  try {
    const filter = `slug = "${p.id}"`;
    const list = await pb.collection('HEAL_programs').getList(1, 1, { filter });
    existing = list.items?.[0] || null;
  } catch (e) {}
  if (existing) {
    await pb.collection('HEAL_programs').update(existing.id, data);
    return existing.id;
  } else {
    const rec = await pb.collection('HEAL_programs').create(data);
    return rec.id;
  }
}

async function upsertStep(program, step) {
  const data = {
    program: program.id,
    order_index: step.order,
    title: step.title,
    reflection: step.reflection || '',
    scripture_ref: step.scripture_ref || '',
    scripture_text: step.scripture_text || '',
    practice_kind: step.practice?.kind || 'none',
    practice_title: step.practice?.title || '',
    practice_slug: step.practice?.slug || '',
    response_headline: step.response?.headline || '',
    response_body: step.response?.body || '',
    response_scripture: step.response?.scripture || '',
    sort_order: step.order,
    is_published: true,
  };
  let existing = null;
  try {
    const filter = `program = "${program.id}" && order_index = ${step.order}`;
    const list = await pb.collection('HEAL_program_steps').getList(1, 1, { filter });
    existing = list.items?.[0] || null;
  } catch (e) {}
  if (existing) {
    await pb.collection('HEAL_program_steps').update(existing.id, data);
  } else {
    await pb.collection('HEAL_program_steps').create(data);
  }
}

// ───────────────────────────────────────────────────────────────
// Main
// ───────────────────────────────────────────────────────────────
async function main() {
  await auth();
  await ensurePrograms();
  await ensureProgramSteps();

  const programsDir = path.join(ROOT, 'content', 'programs');
  const files = (await fs.readdir(programsDir)).filter((f) => f.endsWith('.json'));
  console.log(`\nSeeding ${files.length} program files...`);

  let programCount = 0;
  let stepCount = 0;
  for (const f of files) {
    const raw = await fs.readFile(path.join(programsDir, f), 'utf8');
    const data = JSON.parse(raw);
    for (const p of data.programs || []) {
      await upsertProgram(p);
      programCount++;
      console.log(`  ✓ ${p.title} (${p.steps.length} steps)`);
      for (const s of p.steps) {
        await upsertStep(p, s);
        stepCount++;
      }
    }
  }
  console.log(`\n✅ Seeded ${programCount} programs and ${stepCount} steps`);
}

main().catch((e) => {
  console.error('❌ Failed:', e);
  process.exit(1);
});
