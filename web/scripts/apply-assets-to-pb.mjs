#!/usr/bin/env node
/**
 * HEAL — Update PocketBase with locally-generated asset paths.
 *
 * Reads from /public/{images,audio}/, reconciles with PB records,
 * and PATCHes illustration_url / audio_url for any record where the file
 * exists locally but the PB field is empty.
 *
 * Run after any batch of asset generation.
 *
 * Usage:
 *   node scripts/apply-assets-to-pb.mjs                    # reconcile everything
 *   node scripts/apply-assets-to-pb.mjs meditations        # only meditations
 *   node scripts/apply-assets-to-pb.mjs prayers            # only prayers
 *   node scripts/apply-assets-to-pb.mjs praise             # only praise
 *   node scripts/apply-assets-to-pb.mjs essays             # only essays
 *   node scripts/apply-assets-to-pb.mjs --dry-run          # preview only
 */

import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import PocketBase from 'pocketbase';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const PB_URL = process.env.PB_URL || 'https://pocketbase.scaleupcrm.com';
const IDENTITY = process.env.PB_IDENTITY;
const PASSWORD = process.env.PASSWORD || process.env.PB_PASSWORD;
const DRY_RUN = process.argv.includes('--dry-run');
const FILTER = process.argv.find((a) => !a.startsWith('--') && a !== 'apply-assets-to-pb.mjs' && a.endsWith('.mjs') === false);

if (!IDENTITY || !PASSWORD) {
  console.error('❌ PB_IDENTITY and PB_PASSWORD must be set');
  process.exit(1);
}

const pb = new PocketBase(PB_URL);
pb.autoCancellation(false);
try {
  await pb.collection('_superusers').authWithPassword(IDENTITY, PASSWORD);
} catch {
  try { await pb.admins.authWithPassword(IDENTITY, PASSWORD); } catch { console.error('auth failed'); process.exit(1); }
}

async function reconcileMeditations() {
  const dir = path.join(ROOT, 'public/images/meditations');
  const files = (await fs.readdir(dir)).filter((f) => f.startsWith('illustration-') && f.endsWith('.png'));
  const slugToPath = new Map();
  for (const f of files) slugToPath.set(f.replace(/^illustration-/, '').replace(/\.png$/, ''), '/images/meditations/' + f);

  const audioDir = path.join(ROOT, 'public/audio/meditations');
  const audioFiles = (await fs.readdir(audioDir)).filter((f) => f.startsWith('audio-') && f.endsWith('.mp3'));
  const slugToAudio = new Map();
  for (const f of audioFiles) slugToAudio.set(f.replace(/^audio-/, '').replace(/\.mp3$/, ''), '/audio/meditations/' + f);

  const meditations = await pb.collection('HEAL_meditations').getFullList({ filter: 'is_published = true' });
  let updated = 0;
  for (const m of meditations) {
    const newIll = !m.illustration_url && slugToPath.has(m.slug) ? slugToPath.get(m.slug) : null;
    const newAudio = !m.audio_url && slugToAudio.has(m.slug) ? slugToAudio.get(m.slug) : null;
    if (newIll || newAudio) {
      const update = {};
      if (newIll) update.illustration_url = newIll;
      if (newAudio) update.audio_url = newAudio;
      if (DRY_RUN) {
        console.log(`  [DRY] ${m.slug}: ill=${newIll} audio=${newAudio}`);
      } else {
        await pb.collection('HEAL_meditations').update(m.id, update);
        console.log(`  ✓ ${m.slug}: ${Object.keys(update).join(', ')}`);
        updated++;
      }
    }
  }
  console.log(`  Total updated: ${updated}`);
}

async function reconcilePrayers() {
  const dir = path.join(ROOT, 'public/images/prayers');
  const files = (await fs.readdir(dir)).filter((f) => f.startsWith('prayer-') && f.endsWith('.png'));
  const slugToPath = new Map();
  for (const f of files) slugToPath.set(f.replace(/^prayer-/, '').replace(/\.png$/, ''), '/images/prayers/' + f);

  const prayers = await pb.collection('HEAL_prayers').getFullList({ filter: 'is_published = true' });
  let updated = 0;
  for (const p of prayers) {
    if (!p.illustration_url && slugToPath.has(p.slug)) {
      const newPath = slugToPath.get(p.slug);
      if (DRY_RUN) {
        console.log(`  [DRY] ${p.slug}: ill=${newPath}`);
      } else {
        await pb.collection('HEAL_prayers').update(p.id, { illustration_url: newPath });
        console.log(`  ✓ ${p.slug}: ill`);
        updated++;
      }
    }
  }
  console.log(`  Total updated: ${updated}`);
}

async function reconcilePraise() {
  const dir = path.join(ROOT, 'public/images/praise');
  const files = (await fs.readdir(dir)).filter((f) => f.startsWith('praise-') && f.endsWith('.png'));
  const slugToPath = new Map();
  for (const f of files) slugToPath.set(f.replace(/^praise-/, '').replace(/\.png$/, ''), '/images/praise/' + f);

  const audioDir = path.join(ROOT, 'public/audio/praise');
  const slugToAudio = new Map();
  if (await fs.stat(audioDir).catch(() => null)) {
    for (const f of (await fs.readdir(audioDir)).filter((f) => f.startsWith('praise-') && f.endsWith('.mp3'))) {
      slugToAudio.set(f.replace(/^praise-/, '').replace(/\.mp3$/, ''), '/audio/praise/' + f);
    }
  }

  const songs = await pb.collection('HEAL_praise').getFullList({ filter: 'is_published = true' });
  let updated = 0;
  for (const s of songs) {
    const newIll = !s.illustration_url && slugToPath.has(s.slug) ? slugToPath.get(s.slug) : null;
    const newAudio = !s.audio_url && slugToAudio.has(s.slug) ? slugToAudio.get(s.slug) : null;
    if (newIll || newAudio) {
      const update = {};
      if (newIll) update.illustration_url = newIll;
      if (newAudio) update.audio_url = newAudio;
      if (DRY_RUN) {
        console.log(`  [DRY] ${s.slug}: ill=${newIll} audio=${newAudio}`);
      } else {
        await pb.collection('HEAL_praise').update(s.id, update);
        console.log(`  ✓ ${s.slug}: ${Object.keys(update).join(', ')}`);
        updated++;
      }
    }
  }
  console.log(`  Total updated: ${updated}`);
}

async function reconcileEssays() {
  const dir = path.join(ROOT, 'public/images/essays');
  if (!await fs.stat(dir).catch(() => null)) return;
  const files = (await fs.readdir(dir)).filter((f) => f.startsWith('essay-') && f.endsWith('.png'));
  const slugToPath = new Map();
  for (const f of files) slugToPath.set(f.replace(/^essay-/, '').replace(/\.png$/, ''), '/images/essays/' + f);

  const essays = await pb.collection('HEAL_essays').getFullList({ filter: 'is_published = true' });
  let updated = 0;
  for (const e of essays) {
    if (!e.illustration_url && slugToPath.has(e.slug)) {
      const newPath = slugToPath.get(e.slug);
      if (DRY_RUN) {
        console.log(`  [DRY] ${e.slug}: ill=${newPath}`);
      } else {
        await pb.collection('HEAL_essays').update(e.id, { illustration_url: newPath });
        console.log(`  ✓ ${e.slug}: ill`);
        updated++;
      }
    }
  }
  console.log(`  Total updated: ${updated}`);
}

const scope = FILTER;
if (!scope || scope === 'meditations') {
  console.log('── meditations ──');
  await reconcileMeditations();
}
if (!scope || scope === 'prayers') {
  console.log('── prayers ──');
  await reconcilePrayers();
}
if (!scope || scope === 'praise') {
  console.log('── praise ──');
  await reconcilePraise();
}
if (!scope || scope === 'essays') {
  console.log('── essays ──');
  await reconcileEssays();
}

console.log(DRY_RUN ? '\n(dry run, no changes made)' : '\n✅ Done');
