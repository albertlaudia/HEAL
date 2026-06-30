#!/usr/bin/env node
// HEAL — Accelerated path builder. Concurrent folders per letter, then save incrementally.
// Strategy: list each letter dir, then fan out and probe each subdir in parallel.

import { writeFile, appendFile, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0 Safari/537.36';
const BASE = 'https://hymnstogod.org';
const LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

const map = {};
const OUT = path.join(__dirname, '_hymn_paths.json');

async function fetchText(url) {
  for (let i = 0; i < 3; i++) {
    try {
      const r = await fetch(url, { headers: { 'User-Agent': UA } });
      if (!r.ok) return null;
      return await r.text();
    } catch (e) {
      if (i === 2) return null;
      await new Promise(r => setTimeout(r, 1000 * (i+1)));
    }
  }
}

async function listFolders(letterDir) {
  const html = await fetchText(`${BASE}/Hymn-Files/Public-Domain-Hymns/${letterDir}/`);
  if (!html) return [];
  const folderRegex = new RegExp(`href="(/Hymn-Files/Public-Domain-Hymns/${letterDir}/([^"/]+)/)"`, 'g');
  const seen = new Set();
  const matches = [];
  let m;
  while ((m = folderRegex.exec(html)) !== null) {
    const f = m[2];
    if (!f || f === '') continue;
    if (seen.has(f)) continue;
    seen.add(f);
    matches.push(f);
  }
  return matches;
}

async function getMp3(letterDir, folderName) {
  const html = await fetchText(`${BASE}/Hymn-Files/Public-Domain-Hymns/${letterDir}/${folderName}/`);
  if (!html) return null;
  const mp3Match = html.match(/href="(\/[^"]+\.mp3)"/);
  return mp3Match ? `${BASE}${mp3Match[1]}` : null;
}

function folderToSlug(folderName) {
  return folderName.toLowerCase().replace(/[_-]+/g, '-').replace(/^-+|-+$/g, '').replace(/[^a-z0-9-]/g, '');
}

async function processLetter(letter) {
  const letterDir = `${letter}-Hymns`;
  const folders = await listFolders(letterDir);
  console.log(`[${letter}] ${folders.length} folders`);
  // Probe all folders in this letter concurrently (8 at a time)
  const CONCURRENCY = 8;
  let i = 0;
  const results = [];
  while (i < folders.length) {
    const batch = folders.slice(i, i + CONCURRENCY);
    i += CONCURRENCY;
    const batchResults = await Promise.all(batch.map(f => {
      const slug = folderToSlug(f);
      return getMp3(letterDir, f).then(mp3 => ({ slug, folder: f, mp3 }));
    }));
    results.push(...batchResults);
  }
  let hits = 0;
  for (const { slug, folder, mp3 } of results) {
    if (mp3 && !map[slug]) {
      map[slug] = { mp3, folder, letterDir };
      hits++;
    }
  }
  // Save incrementally
  await writeFile(OUT, JSON.stringify(map, null, 2));
  return hits;
}

async function main() {
  console.log(`═══ HEAL — PD hymn path index builder ═══\n`);
  let total = 0;
  for (const letter of LETTERS) {
    const hits = await processLetter(letter);
    total += hits;
  }
  console.log(`\n✓ Total slugs indexed: ${total}`);
  console.log(`✓ Saved to ${OUT}`);
}

main().catch(e => { console.error('FATAL:', e); process.exit(1); });