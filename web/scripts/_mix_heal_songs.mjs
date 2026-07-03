#!/usr/bin/env node
// HEAL — Mix TTS vocal stems with AI instrumental stems into pro-quality songs.
// Uses ffmpeg to:
//   1. Loop the instrumental to match vocal length (or vice versa)
//   2. Mix vocal + instrumental with proper balance
//   3. Add crossfade, normalize, soft reverb
//   4. Output as original-*.mp3 to FTP
//
// The "original" prefix marks these as HEAL's own original recordings,
// distinct from the pre-1928 archive.org "sing-" versions.

import { readdir, readFile, stat, writeFile } from 'node:fs/promises';
import { existsSync, mkdirSync, createWriteStream } from 'node:fs';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const STEMS_DIR = '/workspace/.mavis-cache/heal-song-gen';
const OUTPUT_DIR = '/workspace/.mavis-cache/heal-song-mixes';
const MIX_LOG = path.join(__dirname, '_mix_log.json');

if (!existsSync(OUTPUT_DIR)) mkdirSync(OUTPUT_DIR, { recursive: true });

function run(cmd, args) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let out = '', err = '';
    p.stdout.on('data', d => out += d.toString());
    p.stderr.on('data', d => err += d.toString());
    p.on('close', code => code === 0 ? resolve({ out, err }) : reject(new Error(`exit ${code}: ${err.slice(-500)}`)));
  });
}

async function probe(file) {
  const { out } = await run('ffprobe', [
    '-v', 'error',
    '-show_entries', 'format=duration,sample_rate,bit_rate',
    '-show_entries', 'stream=codec_name,channels',
    '-of', 'default=noprint_wrappers=1',
    file
  ]);
  const result = {};
  for (const line of out.split('\n')) {
    const [k, v] = line.split('=');
    if (k && v) result[k.trim()] = v.trim();
  }
  return result;
}

async function mixSong(slug) {
  const vocalPath = `${STEMS_DIR}/${slug}-vocal.mp3`;
  const instrPath = `${STEMS_DIR}/${slug}-instr.mp3`;
  const outPath = `${OUTPUT_DIR}/original-${slug}.mp3`;

  if (!existsSync(vocalPath) || !existsSync(instrPath)) {
    return { slug, status: 'missing-stems' };
  }
  if (existsSync(outPath)) {
    const s = await stat(outPath);
    if (s.size > 100000) return { slug, status: 'already-mixed' };
  }

  const vocalMeta = await probe(vocalPath);
  const instrMeta = await probe(instrPath);
  const vocalDur = parseFloat(vocalMeta.duration || 0);
  const instrDur = parseFloat(instrMeta.duration || 0);
  if (vocalDur < 5 || instrDur < 5) {
    return { slug, status: 'too-short', vocalDur, instrDur };
  }

  // Strategy: pad the shorter one with a looped copy of itself to match the
  // longer, then mix at -3 dB vocal / -6 dB instrumental balance.
  const targetDur = Math.max(vocalDur, instrDur);

  // Step 1: build a padded instrumental (loop until targetDur, with fade-out at end)
  const tmpInstr = `/tmp/heal-mix-${slug}-instr.mp3`;
  if (instrDur < targetDur - 0.5) {
    // Stream-loop option must come BEFORE -i (it's an input option).
    await run('ffmpeg', ['-y', '-stream_loop', '-1', '-i', instrPath, '-t', String(targetDur + 1),
      '-af', `afade=t=out:st=${targetDur - 2}:d=2,volume=0.7`,
      '-ar', '44100', '-ac', '2', '-b:a', '192k', tmpInstr]);
  } else {
    await run('ffmpeg', ['-y', '-i', instrPath, '-t', String(targetDur + 1),
      '-af', `afade=t=out:st=${targetDur - 2}:d=2,volume=0.7`,
      '-ar', '44100', '-ac', '2', '-b:a', '192k', tmpInstr]);
  }

  // Step 2: pad the vocal to same length
  const tmpVocal = `/tmp/heal-mix-${slug}-vocal.mp3`;
  await run('ffmpeg', ['-y', '-i', vocalPath,
    '-af', `afade=t=in:st=0:d=1,afade=t=out:st=${targetDur - 2}:d=2,volume=1.2,aecho=0.8:0.7:1000:0.4`,
    '-ar', '44100', '-ac', '2', '-b:a', '192k', tmpVocal]);

  // Step 3: amix both
  const filterStr = `[0:a]volume=1.2[v];[1:a]volume=0.7[i];[v][i]amix=inputs=2:duration=longest:normalize=0,loudnorm=I=-14:TP=-2:LRA=11[out]`;
  await run('ffmpeg', ['-y',
    '-i', tmpVocal,
    '-i', tmpInstr,
    '-filter_complex', filterStr,
    '-map', '[out]',
    '-ar', '44100', '-ac', '2', '-b:a', '192k',
    outPath]);

  // Verify output
  const outMeta = await probe(outPath);
  return { slug, status: 'mixed', duration: parseFloat(outMeta.duration) };
}

async function main() {
  console.log('═══ HEAL Original Song Mixer ═══\n');
  const files = await readdir(STEMS_DIR);
  const vocFiles = files.filter(f => f.endsWith('-vocal.mp3'));
  const slugs = vocFiles.map(f => f.replace('-vocal.mp3', ''));
  console.log(`Found ${slugs.length} vocal stems\n`);

  const log = [];
  let i = 0;
  for (const slug of slugs) {
    i++;
    process.stdout.write(`[${i}/${slugs.length}] ${slug.padEnd(45)} `);
    try {
      const r = await mixSong(slug);
      console.log(r.status === 'mixed'
        ? `✓ mixed (${r.duration.toFixed(1)}s)`
        : `${r.status}`);
      log.push(r);
    } catch (e) {
      console.log(`✗ ${e.message}`);
      log.push({ slug, status: 'error', error: e.message });
    }
  }

  await writeFile(MIX_LOG, JSON.stringify(log, null, 2));
  console.log(`\n✓ Log saved to ${MIX_LOG}`);
  const mixed = log.filter(r => r.status === 'mixed' || r.status === 'already-mixed');
  console.log(`✓ ${mixed.length} mixed/ready`);
}

main().catch(e => { console.error('FATAL:', e); process.exit(1); });