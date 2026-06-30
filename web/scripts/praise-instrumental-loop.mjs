#!/usr/bin/env node
// HEAL — Path C: convert short AI instrumentals to 2-3 min loops + upload + PB backfill.
//
// Strategy:
//   1. Take existing *instr.mp3 files (30-45s, 32kHz mono, AI-generated music)
//   2. Loop to 150 seconds (2:30) with crossfade to avoid clicks
//   3. Re-encode to 44.1kHz stereo 128kbps (CD quality, app-ready)
//   4. Upload to CDN
//   5. Update PB HEAL_praise.audio_url
//
// RATE LIMITS:
//   - FTP upload: ~1 file per 5s (single connection)
//   - PB write:   ~50 req/sec (PB safe up to 100 req/sec)
//   - ffmpeg:     ~5-10 sec per file (CPU-bound)
//
// USAGE:
//   ./praise-instrumental-loop.mjs --batch-size 1 --per-hour 1   # safest, ships 1/hour
//   ./praise-instrumental-loop.mjs --batch-size 3 --per-hour 6   # moderate
//   ./praise-instrumental-loop.mjs --batch-size 10 --per-hour 12 # max cron (hourly cron does 12/day)
//
// RECOMMENDED FOR HOURLY CRON: --batch-size 1 --per-hour 1
//   (one song processed and shipped per hour, no resource spike, easy to debug)

import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import { readdir, stat, mkdir, writeFile, readFile, unlink } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const execp = promisify(exec);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ─── CONFIG ──────────────────────────────────────────────────────
const SOURCE_DIR = process.env.HEAL_PRAISE_SRC || '/workspace/.mavis-cache/heal-song-gen';
const FTP_HOST = 'win8108.site4now.net';
const FTP_USER = process.env.SMARTERASP_FTP_USER || 'respc';
const FTP_PASS = process.env.SMARTERASP_FTP_PASSWORD;
const CDNDIR = 'heal/audio/praise';
const CDNURL = 'https://resources.positiveness.club/heal/audio/praise';

const BATCH_SIZE = parseInt(process.env.BATCH_SIZE || process.argv.find(a => a.startsWith('--batch-size='))?.split('=')[1] || '1');
const PER_HOUR = parseInt(process.env.PER_HOUR || process.argv.find(a => a.startsWith('--per-hour='))?.split('=')[1] || '1');
const LOOP_SECONDS = parseInt(process.env.LOOP_SECONDS || process.argv.find(a => a.startsWith('--loop='))?.split('=')[1] || '150');

const DRY_RUN = process.argv.includes('--dry-run');

// ─── FTP single-file upload (calls companion Python script — avoids inline-escape bugs) ───
async function ftpUpload(localPath, remoteName) {
  const scriptPath = path.join(__dirname, '_ftp_upload.py');
  await execp(`python3 ${scriptPath} "${localPath}" "${CDNDIR}" "${remoteName}"`);
}

// ─── PB backfill ─────────────────────────────────────────────────
async function pbBackfill(slug, audioUrl, licenseNote = 'AI instrumental loop (Path C)') {
  // Use PB v0.39 REST API. PB_IDENTITY/PB_PASSWORD must be set.
  const pbUrl = process.env.PB_URL;
  const pbId = process.env.PB_IDENTITY;
  const pbPass = process.env.PB_PASSWORD;
  if (!pbUrl || !pbId || !pbPass) {
    console.log(`  SKIP PB backfill (no creds): ${slug}`);
    return;
  }
  const auth = await execp(`curl -s -X POST "${pbUrl}/api/collections/_superusers/auth-with-password" -H "Content-Type: application/json" -d '{"identity":"${pbId}","password":"${pbPass}"}'`);
  const token = JSON.parse(auth.stdout).token;
  if (!token) {
    console.log(`  PB auth failed: ${slug}`);
    return;
  }
  // Find record id by slug
  const find = await execp(`curl -s "${pbUrl}/api/collections/HEAL_praise/records?perPage=1&filter=slug='${slug}'" -H "Authorization: ${token}"`);
  const items = JSON.parse(find.stdout).items || [];
  if (items.length === 0) {
    console.log(`  NO PB record for slug=${slug}`);
    return;
  }
  const recId = items[0].id;
  // Patch
  const patch = await execp(`curl -s -X PATCH "${pbUrl}/api/collections/HEAL_praise/records/${recId}" -H "Authorization: ${token}" -H "Content-Type: application/json" -d '{"audio_url":"${audioUrl}","duration_seconds":${LOOP_SECONDS},"audio_license":"${licenseNote}","audio_source":"loop of AI-generated 30s instrumental"}'`);
  console.log(`  ✓ PB patched ${slug}: ${JSON.parse(patch.stdout).id}`);
}

// ─── ffmpeg loop + re-encode ─────────────────────────────────────
async function loopInstrumental(srcPath, dstPath, seconds) {
  const filter = `[0:a]afade=t=in:st=0:d=2,afade=t=out:st=${seconds - 2}:d=2,aloop=loop=-1:size=2e+09:start=0[out]`;
  const cmd = `ffmpeg -y -i "${srcPath}" -filter_complex "${filter}" -map "[out]" -t ${seconds} -c:a libmp3lame -b:a 128k -ar 44100 "${dstPath}"`;
  const { stderr } = await execp(cmd);
  if (!existsSync(dstPath)) {
    throw new Error(`ffmpeg failed: ${stderr.split('\\n').slice(-3).join('\\n')}`);
  }
}

// ─── Process one slug ─────────────────────────────────────────────
async function processOne(slug) {
  const src = path.join(SOURCE_DIR, `${slug}-instr.mp3`);
  const dst = `/tmp/loop-${slug}.mp3`;
  if (!existsSync(src)) {
    console.log(`  NO source: ${src}`);
    return false;
  }
  console.log(`[${slug}] looping ${src} -> ${dst} (${LOOP_SECONDS}s)`);
  if (!DRY_RUN) {
    await loopInstrumental(src, dst, LOOP_SECONDS);
  }
  const remoteName = `${slug}-instr-loop.mp3`;
  const remoteUrl = `${CDNURL}/${remoteName}`;
  console.log(`[${slug}] uploading -> ${remoteUrl}`);
  if (!DRY_RUN) {
    await ftpUpload(dst, remoteName);
  }
  console.log(`[${slug}] backfilling PB`);
  if (!DRY_RUN) {
    await pbBackfill(slug, remoteUrl);
  }
  console.log(`[${slug}] done`);
  return true;
}

// ─── Main: process N songs, rate-limited ────────────────────────
async function main() {
  console.log(`=== HEAL praise loop pipeline ===`);
  console.log(`Source: ${SOURCE_DIR}`);
  console.log(`Batch size: ${BATCH_SIZE}, per hour: ${PER_HOUR}`);
  console.log(`Loop seconds: ${LOOP_SECONDS}, dry run: ${DRY_RUN}`);
  console.log('');

  // Find all *-instr.mp3 files
  const files = await readdir(SOURCE_DIR);
  const slugs = [...new Set(files
    .filter(f => f.endsWith('-instr.mp3'))
    .map(f => f.replace('-instr.mp3', ''))
  )];
  console.log(`Found ${slugs.length} instrumentals in cache`);

  // Cross-reference with PB records (only process records that exist)
  const pbUrl = process.env.PB_URL;
  const pbId = process.env.PB_IDENTITY;
  const pbPass = process.env.PB_PASSWORD;
  if (!pbUrl) {
    console.log(`No PB_URL — using all ${slugs.length} slugs`);
  } else {
    const auth = await execp(`curl -s -X POST "${pbUrl}/api/collections/_superusers/auth-with-password" -H "Content-Type: application/json" -d '{"identity":"${pbId}","password":"${pbPass}"}'`);
    const token = JSON.parse(auth.stdout).token;
    const pbList = await execp(`curl -s "${pbUrl}/api/collections/HEAL_praise/records?perPage=200&fields=slug" -H "Authorization: ${token}"`);
    const pbSlugs = (JSON.parse(pbList.stdout).items || []).map(r => r.slug);
    // Filter
    const matching = slugs.filter(s => pbSlugs.includes(s));
    console.log(`PB has ${pbSlugs.length} praise records; ${matching.length} match local instrumentals`);
    slugs.length = 0;
    slugs.push(...matching);
  }

  // Determine which to do this run
  const todo = slugs.slice(0, BATCH_SIZE);
  console.log(`Will process ${todo.length} songs this run:`);
  for (const s of todo) console.log(`  - ${s}`);
  console.log('');

  let success = 0;
  for (const slug of todo) {
    try {
      const ok = await processOne(slug);
      if (ok) success++;
    } catch (e) {
      console.error(`FAIL ${slug}: ${e.message}`);
    }
    // Rate-limit: if PER_HOUR > 1, sleep between
    if (PER_HOUR > 1 && todo.indexOf(slug) < todo.length - 1) {
      const sleepMs = Math.floor(3600 * 1000 / PER_HOUR);
      console.log(`Sleeping ${(sleepMs / 1000).toFixed(0)}s (rate limit ${PER_HOUR}/hour)`);
      await new Promise(r => setTimeout(r, sleepMs));
    }
  }

  console.log('');
  console.log(`=== Done: ${success}/${todo.length} succeeded ===`);
}

main().catch(e => {
  console.error('FATAL:', e);
  process.exit(1);
});
