#!/usr/bin/env node
// HEAL — Find and download SUNG public-domain hymns from Archive.org.
// All recordings are pre-1928 = US public domain.

import { writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0 Safari/537.36';
const OUT_DIR = path.join(__dirname, '_sung_paths.json');
const DL_DIR = '/tmp/heal-sung-downloads';

// PB slug → Archive.org search query (best historical recordings)
const QUERIES = [
  // Amazing Grace (1922 Sacred Harp)
  { slug: 'amazing-grace', q: 'amazing grace', year: '1922', primary: 'amazing-grace-1922' },
  // A Mighty Fortress (1917 Edison)
  { slug: 'a-mighty-fortress', q: 'a mighty fortress', year: '1917', primary: 'edison-80504_01_5907' },
  // Abide With Me (1905 George Alexander)
  { slug: 'abide-with-me', q: 'abide with me', year: '1905', primary: 'abide-with-me-1905-george-alexander' },
  // What A Friend We Have In Jesus (1920 Metropolitan Quartet)
  { slug: 'what-a-friend-we-have-in-jesus', q: 'what a friend', year: '1920', primary: '78_what-a-friend-we-have-in-jesus_metropolitan-quartet-charles-g-converse_gbia0078158b' },
  // Nearer My God To Thee (1902 chimes)
  { slug: 'nearer-my-god-to-thee', q: 'nearer my god', year: '1902', primary: 'nearer1902' },
  // Holy Holy Holy (1917 Calvary Choir)
  { slug: 'holy-holy-holy', q: 'holy holy holy', year: '1917', primary: '78_holy-holy-holy-lord-god-almighty_the-calvary-choir-and-the-choir-of-boys-of-st_gbia0078059a' },
  // Come Thou Fount (1921 Metropolitan Quartet)
  { slug: 'come-thou-fount-of-every-blessing', q: 'come thou fount', year: '1921', primary: '78_come-thou-fount-of-every-blessing_john-wyeth-metropolitan-quartet_gbia0083652a' },
  // Joy To The World (1916)
  { slug: 'joy-to-the-world', q: 'joy to the world', year: '1916', primary: '78_joy-to-the-world_the-carol-singers_gbia0082923b' },
  // It Is Well With My Soul (1914)
  { slug: 'it-is-well-with-my-soul', q: 'it is well', year: '1914', primary: '78_it-is-well-with-my-soul_stanley-gillette-bliss_gbia3029098b' },
  // Jesus Lover Of My Soul (1914 Alma Gluck)
  { slug: 'jesus-lover-of-my-soul', q: 'jesus lover', year: '1914', primary: '78_jesus-lover-of-my-soul_alma-gluck-louise-homer-charles-wesley-joseph-p-holbrook_gbia0187622b' },
  // Just As I Am (1918 Arthur Middleton)
  { slug: 'just-as-i-am', q: 'just as i am', year: '1918', primary: '78_just-as-i-am_arthur-middleton-wm-d-bradbury_gbia0023324b' },
  // Rock Of Ages (1914 Alma Gluck)
  { slug: 'rock-of-ages', q: 'rock of ages', year: '1914', primary: '78_rock-of-ages_alma-gluck-louise-homer-rev-a-m-toplady-dr-thomas-hastings_gbia0051603a' },
  // Be Still My Soul (need to search separately — modern arrangement, post-1928)
  { slug: 'be-still-my-soul', q: 'be still my soul', year: 'pre-1928', primary: 'savior-like-a-shepherd-lead-us' },
];

async function fetchJson(url) {
  for (let i = 0; i < 3; i++) {
    try {
      const r = await fetch(url, { headers: { 'User-Agent': UA } });
      if (!r.ok) return null;
      return await r.json();
    } catch (e) {
      if (i === 2) return null;
      await new Promise(r => setTimeout(r, 1000 * (i+1)));
    }
  }
}

async function getFileInfo(identifier) {
  const data = await fetchJson(`https://archive.org/metadata/${identifier}`);
  if (!data) return null;
  const files = (data.files || []).filter(f => {
    const n = f.name || '';
    return n.endsWith('.mp3') || n.endsWith('.ogg') || n.endsWith('.flac');
  });
  if (files.length === 0) return null;
  // Prefer MP3 (smallest + universally compatible)
  const mp3 = files.find(f => f.name.endsWith('.mp3')) || files[0];
  return {
    identifier,
    file: mp3.name,
    size: parseInt(mp3.size || 0),
    url: `https://archive.org/download/${identifier}/${encodeURIComponent(mp3.name)}`,
    title: data.metadata?.title || identifier,
    creator: data.metadata?.creator || 'Unknown',
    date: data.metadata?.date || 'Unknown',
  };
}

async function main() {
  if (!existsSync(DL_DIR)) await mkdir(DL_DIR, { recursive: true });
  const found = [];
  for (const { slug, primary, year } of QUERIES) {
    process.stdout.write(`[${slug}] `);
    const info = await getFileInfo(primary);
    if (info) {
      console.log(`✓ ${info.title} (${info.size} bytes, ${info.date})`);
      found.push({ slug, ...info });
    } else {
      console.log(`✗ not found: ${primary}`);
    }
    await new Promise(r => setTimeout(r, 200));
  }
  await writeFile(OUT_DIR, JSON.stringify(found, null, 2));
  console.log(`\n✓ Saved ${found.length} to ${OUT_DIR}`);
}

main().catch(e => { console.error('FATAL:', e); process.exit(1); });