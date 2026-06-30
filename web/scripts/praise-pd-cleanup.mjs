#!/usr/bin/env node
// HEAL — Cleanup: delete old TTS-voice audio files + unpublish copyrighted hymns.
//
// Phase 1: Delete the old `song-*.mp3` files from CDN (they sound like voice reading lyrics)
// Phase 2: Mark copyrighted hymns as is_published=false (hide from library)
// Phase 3: For the same hymns, clear audio_url so the player doesn't try to play them
//
// Result: Praise library only shows PD-hymn-backed records.

import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const execp = promisify(exec);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PB_URL = process.env.PB_URL;
const PB_ID = process.env.PB_IDENTITY;
const PB_PASS = process.env.PB_PASSWORD;
const FTP_PASS = process.env.SMARTERASP_FTP_PASSWORD;

// Copyrighted hymns in PB (post-1930, NOT public domain)
const COPYRIGHTED_SLUGS = [
  'as-the-deer',
  'good-good-father',
  'tremble-abridged',
  'in-christ-alone',
  'bless-the-lord-ten-thousand-reasons',
  '10-000-reasons-bless-the-lord',
  'how-great-thou-art-abridged',
  'glory-to-god-in-the-highest',
  'forever-chris-tomlin',
  'grace-alone',
  'forever-reign',
  'jesus-i-my-cross-have-taken',
  'you-are-my-all-in-all',
  'you-are-my-hiding-place',
  'create-in-me-a-clean-heart',
  'mighty-to-save',
  'it-is-well-with-my-soul-modern',
  'holy-forever',
  'o-come-to-the-altar',
  'what-a-beautiful-name',
  'be-still-and-know-slow',  // not strictly copyright but replaced by PD version
];

async function deleteFromCDN(remoteName) {
  const script = path.join(__dirname, '_ftp_delete.py');
  await execp(`python3 ${script} "heal/audio/praise" "${remoteName}"`);
}

async function pbPatch(slug, fields) {
  const auth = await execp(`curl -s -X POST "${PB_URL}/api/collections/_superusers/auth-with-password" -H "Content-Type: application/json" -d '{"identity":"${PB_ID}","password":"${PB_PASS}"}'`);
  const token = JSON.parse(auth.stdout).token;
  const find = await execp(`curl -s "${PB_URL}/api/collections/HEAL_praise/records?perPage=1&filter=slug='${slug}'" -H "Authorization: ${token}"`);
  const items = JSON.parse(find.stdout).items || [];
  if (items.length === 0) return null;
  const recId = items[0].id;
  const patch = await execp(`curl -s -X PATCH "${PB_URL}/api/collections/HEAL_praise/records/${recId}" -H "Authorization: ${token}" -H "Content-Type: application/json" -d '${JSON.stringify(fields).replace(/'/g, "\\'")}'`);
  return JSON.parse(patch.stdout);
}

async function getAllPBRecords() {
  const auth = await execp(`curl -s -X POST "${PB_URL}/api/collections/_superusers/auth-with-password" -H "Content-Type: application/json" -d '{"identity":"${PB_ID}","password":"${PB_PASS}"}'`);
  const token = JSON.parse(auth.stdout).token;
  const r = await execp(`curl -s "${PB_URL}/api/collections/HEAL_praise/records?perPage=200&fields=slug,audio_url,is_published,audio_license" -H "Authorization: ${token}"`);
  return JSON.parse(r.stdout).items || [];
}

async function main() {
  console.log('=== HEAL Praise Cleanup ===\n');

  const records = await getAllPBRecords();
  console.log(`Total PB records: ${records.length}\n`);

  // ─── Phase 1: Delete old TTS-voice files from CDN ────
  console.log('--- Phase 1: Delete old song-*.mp3 from CDN ---');
  const oldAudioRecords = records.filter(r => {
    const url = r.audio_url || '';
    return url.includes('/song-') && !url.includes('/pd-');
  });
  console.log(`Found ${oldAudioRecords.length} records pointing to old TTS audio`);

  let deletedCdn = 0;
  let failedDelete = 0;
  for (const r of oldAudioRecords) {
    const url = r.audio_url;
    const filename = url.split('/').pop();
    try {
      await deleteFromCDN(filename);
      deletedCdn++;
    } catch (e) {
      console.log(`  ✗ CDN delete ${filename}: ${e.message}`);
      failedDelete++;
    }
  }
  console.log(`  CDN deletes: ${deletedCdn} OK, ${failedDelete} failed\n`);

  // ─── Phase 2: Mark copyrighted hymns as unpublished ────
  console.log('--- Phase 2: Mark copyrighted hymns as is_published=false ---');
  let unpublished = 0;
  for (const slug of COPYRIGHTED_SLUGS) {
    const rec = records.find(r => r.slug === slug);
    if (!rec) continue;
    try {
      await pbPatch(slug, {
        is_published: false,
        audio_url: '',
        audio_license: 'NOT SHIPPED — copyrighted (post-1930). Will add via OneLicense.',
        audio_source: 'Pending licensing',
      });
      unpublished++;
      console.log(`  ✓ unpublished ${slug}`);
    } catch (e) {
      console.log(`  ✗ ${slug}: ${e.message}`);
    }
  }
  console.log(`  Unpublished: ${unpublished}/${COPYRIGHTED_SLUGS.length}\n`);

  // ─── Phase 3: Clear audio_url on the unpublished ones we just touched ───
  console.log('--- Phase 3: Clear stale audio_url on remaining TTS records ---');
  // For records still pointing to /song- files, set audio_url to empty (so player skips)
  let cleared = 0;
  for (const r of records) {
    const url = r.audio_url || '';
    if (url.includes('/song-') && !url.includes('/pd-') && r.is_published !== false) {
      try {
        await pbPatch(r.slug, {
          audio_url: '',
          audio_license: 'TTS vocal removed in Path A cleanup',
          audio_source: 'No real recording — text-only',
        });
        cleared++;
        console.log(`  ✓ cleared audio_url for ${r.slug}`);
      } catch (e) {
        console.log(`  ✗ ${r.slug}: ${e.message}`);
      }
    }
  }
  console.log(`  Cleared: ${cleared}\n`);

  console.log('=== Done ===');
  console.log(`CDN files deleted: ${deletedCdn}`);
  console.log(`Hymns unpublished (copyright): ${unpublished}`);
  console.log(`Hymns with cleared audio_url (pending PD source): ${cleared}`);
}

main().catch(e => { console.error('FATAL:', e); process.exit(1); });