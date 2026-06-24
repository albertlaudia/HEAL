#!/usr/bin/env node
/**
 * Seed program illustration_url + badge_image_path from local /public/images/badges/*.webp
 * Updates HEAL_programs.illustration_url and HEAL_programs.badge_image_path.
 */
import PocketBase from 'pocketbase';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const PB_URL = process.env.PB_URL || 'https://pocketbase.scaleupcrm.com';
const IDENTITY = process.env.PB_IDENTITY || process.env.HEAL_PB_IDENTITY;
const PASSWORD = process.env.PASSWORD || process.env.PB_PASSWORD;

if (!IDENTITY || !PASSWORD) {
  console.error('❌ PB_IDENTITY and PB_PASSWORD must be set');
  process.exit(1);
}

const pb = new PocketBase(PB_URL);
pb.autoCancellation(false);

try {
  await pb.collection('_superusers').authWithPassword(IDENTITY, PASSWORD);
  console.log('✅ Authed as _superuser');
} catch {
  try { await pb.admins.authWithPassword(IDENTITY, PASSWORD); } catch { console.error('❌ auth failed'); process.exit(1); }
}

const programs = await pb.collection('HEAL_programs').getFullList();
const badgeDir = path.join(ROOT, 'public', 'images', 'badges');

let count = 0;
for (const p of programs) {
  const webpPath = path.join(badgeDir, `${p.slug}.webp`);
  let exists = false;
  try { await fs.access(webpPath); exists = true; } catch {}
  if (!exists) {
    console.log(`  ! no badge image for ${p.slug}`);
    continue;
  }
  const publicPath = `/images/badges/${p.slug}.webp`;
  // illustration_url is a `url` field — only set if the value is a real URL.
  // For local files, just set badge_image_path (text field) which the components use.
  await pb.collection('HEAL_programs').update(p.id, {
    badge_image_path: publicPath,
  });
  console.log(`  ✓ ${p.slug} → ${publicPath}`);
  count++;
}
console.log(`\n✅ Updated ${count} programs`);
