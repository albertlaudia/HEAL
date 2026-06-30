#!/usr/bin/env node
// HEAL — Build a complete map of slug → mp3 URL by scraping hymnstogod.org listings.
//
// Walks /Hymn-Files/Public-Domain-Hymns/X-Hymns/ directories, lists subdirs,
// and saves the FIRST mp3 found inside to a JSON file.
// Output: web/scripts/_hymn_paths.json — flat {slug: mp3url} map.
//
// Rate-limit friendly: sleeps 1.5s between requests. Runs once.

import { writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0 Safari/537.36';
const BASE = 'https://hymnstogod.org';
const LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function getFolders(letterDir) {
  const url = `${BASE}/Hymn-Files/Public-Domain-Hymns/${letterDir}/`;
  try {
    const r = await fetch(url, { headers: { 'User-Agent': UA } });
    if (!r.ok) return [];
    const html = await r.text();
    const folderRegex = new RegExp(`href="(/Hymn-Files/Public-Domain-Hymns/${letterDir}/([^"]+?)/)"`, 'g');
    const seen = new Set();
    let m;
    const matches = [];
    while ((m = folderRegex.exec(html)) !== null) {
      const folderName = m[2];
      if (folderName === '') continue;
      if (seen.has(folderName)) continue;
      seen.add(folderName);
      matches.push(folderName);
    }
    return matches;
  } catch (e) {
    console.error(`  ✗ ${url}: ${e.message}`);
    return [];
  }
}

async function getMp3(letterDir, folderName) {
  const url = `${BASE}/Hymn-Files/Public-Domain-Hymns/${letterDir}/${folderName}/`;
  try {
    const r = await fetch(url, { headers: { 'User-Agent': UA } });
    if (!r.ok) return null;
    const html = await r.text();
    const mp3Match = html.match(/href="([^"]+\.mp3)"/);
    if (mp3Match) {
      const mp3Path = mp3Match[1];
      return mp3Path.startsWith('/') ? `${BASE}${mp3Path}` : `${BASE}/${mp3Path}`;
    }
    return null;
  } catch (e) {
    return null;
  }
}

function folderToSlug(folderName) {
  return folderName
    .toLowerCase()
    .replace(/[_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/[^a-z0-9-]/g, '');
}

async function main() {
  console.log('═══ Building hymn path index from hymnstogod.org ═══\n');
  const map = {};
  let dirs = 0;
  let hits = 0;

  for (const letter of LETTERS) {
    const letterDir = `${letter}-Hymns`;
    process.stdout.write(`[${letter}] `);
    const folders = await getFolders(letterDir);
    console.log(`${folders.length} folders`);
    dirs += folders.length;

    for (const folder of folders) {
      const slug = folderToSlug(folder);
      const mp3 = await getMp3(letterDir, folder);
      if (mp3 && !map[slug]) {
        map[slug] = { mp3, folder, letterDir };
        hits++;
      }
      await sleep(200);
    }
    await sleep(500);
  }

  const out = path.join(__dirname, '_hymn_paths.json');
  await writeFile(out, JSON.stringify(map, null, 2));
  console.log(`\n✓ Indexed ${hits} unique hymn slugs`);
  console.log(`✓ Saved to ${out}`);
  console.log(`\nSample entries:`);
  for (const [slug, v] of Object.entries(map).slice(0, 8)) {
    console.log(`  ${slug}: ${v.mp3}`);
  }
}

main().catch(e => { console.error('FATAL:', e); process.exit(1); });