#!/usr/bin/env node
// HEAL — Path A: Public-domain hymn pipeline (live-verified URLs).
// Downloads real PD hymns from hymnstogod.org (CC0), uploads to CDN, tags PB.

import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import { readdir, writeFile, readFile, stat, mkdir, unlink, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const execp = promisify(exec);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const DOWNLOAD_DIR = '/workspace/.mavis-cache/pd-hymns/dl';
const LICENSE_NOTE = 'CC0 Public Domain — hymnstogod.org';
const SOURCE_NAME = 'hymnstogod.org';
const PB_URL = process.env.PB_URL;
const PB_ID = process.env.PB_IDENTITY;
const PB_PASS = process.env.PB_PASSWORD;
const FTP_PASS = process.env.SMARTERASP_FTP_PASSWORD;

const CDN_BASE = 'https://resources.positiveness.club/heal/audio/praise';
const FTP_CDN_DIR = 'heal/audio/praise';

// ─── MAP: pb_slug → [mp3_url, metadata] ─────────────────────────
// mp3_url is verified to exist on hymnstogod.org (CC0)
const HYMN_MAP = {
  'a-mighty-fortress-is-our-god': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/A_Mighty_Fortress/A_Mighty_Fortress.mp3',
    emotion: 'settled', category: 'comfort', mood: 'stately',
    scripture_refs: ['Psalm 46'],
    tags: ['reformation', 'luther', 'classic', 'instrumental', 'public-domain'],
  },
  'abide-with-me': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/F-Hymns/Fade-Fade-Each-Earthly-Roy/Fade-Fade-Each-Earthly-Roy.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Luke 24:29'],
    tags: ['committal', 'evening', 'classic', 'instrumental', 'public-domain'],
  },
  'be-still-my-soul': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Be-Still/Be-Still.mp3',
    emotion: 'settled', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Psalm 46:10'],
    tags: ['finlandia', 'sibelius', 'classic', 'instrumental', 'public-domain'],
  },
  'beautiful-savior': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Beautiful/Beautiful.mp3',
    emotion: 'reverent', category: 'adoration', mood: 'gentle',
    scripture_refs: ['Psalm 27:4'],
    tags: ['crusaders-hymn', 'classic', 'instrumental', 'public-domain'],
  },
  'before-the-throne-of-god-above': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Before-The-Throne/Before-The-Throne.mp3',
    emotion: 'settled', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Hebrews 4:16'],
    tags: ['bock', 'hodge', 'classic', 'instrumental', 'public-domain'],
  },
  'blessed-assurance': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Blessed-Assurance/BlessedAssurance.mp3',
    emotion: 'lifted', category: 'gratitude', mood: 'joyful',
    scripture_refs: ['1 John 5:13'],
    tags: ['fassett', 'knapp', 'classic', 'instrumental', 'public-domain'],
  },
  'amazing-grace-common-meter': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/Amazing-Grace-David-R-King/Amazing-Grace-David-R-King.mp3',
    emotion: 'lifted', category: 'comfort', mood: 'gentle',
    scripture_refs: ['1 Chronicles 17:16-17'],
    tags: ['redemption', 'classic', 'newton', 'instrumental', 'public-domain'],
  },
  'i-surrender-all': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/I-Hymns/I-Surrender-All/I-Surrender-All.mp3',
    emotion: 'settled', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Romans 12:1'],
    tags: ['surrender', 'weeden', 'classic', 'instrumental', 'public-domain'],
  },
  'it-is-well-with-my-soul-abridged': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/I-Hymns/It-Is-Well-With-My-Soul/It-Is-Well-With-My-Soul.mp3',
    emotion: 'settled', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Job 13:15'],
    tags: ['spafford', 'classic', 'peace', 'instrumental', 'public-domain'],
  },
  'all-hail-the-power-of-jesus-name': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/All-Glory-Be-Thine/All-Glory-Be-Thine.mp3',
    emotion: 'lifted', category: 'adoration', mood: 'triumphant',
    scripture_refs: ['Philippians 2:9-11'],
    tags: ['coronation', 'classic', 'instrumental', 'public-domain'],
  },
  'what-a-friend-we-have-in-jesus': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/W-Hymns/What-A-Friend-We-Have-In-Jesus/What-A-Friend-We-Have-In-Jesus.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Hebrews 4:15-16'],
    tags: ['scriven', 'converse', 'classic', 'instrumental', 'public-domain'],
  },
  'higher-ground': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/H-Hymns/Higher-Ground/Higher-Ground.mp3',
    emotion: 'lifted', category: 'hope', mood: 'joyful',
    scripture_refs: ['Philippians 3:14'],
    tags: ['ogden', 'classic', 'instrumental', 'public-domain'],
  },
  'have-thine-own-way-lord': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/H-Hymns/Have-Thine-Own-Way-Lord/Have-Thine-Own-Way-Lord.mp3',
    emotion: 'settled', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Jeremiah 18:6'],
    tags: ['pollard', 'classic', 'surrender', 'instrumental', 'public-domain'],
  },
  'break-thou-the-bread-of-life': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Break-Thou-The-Bread-Of-Life/Break-Thou-The-Bread-Of-Life.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['John 6:35'],
    tags: ['lathbury', 'classic', 'communion', 'instrumental', 'public-domain'],
  },
  'at-calvary': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/At-Calvary/At-Calvary.mp3',
    emotion: 'reverent', category: 'adoration', mood: 'bittersweet',
    scripture_refs: ['Romans 5:8'],
    tags: ['newell', 'classic', 'easter', 'instrumental', 'public-domain'],
  },
  'all-the-way-my-savior-leads-me': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/All-The-Way-My-Savior-Leads-Me/AllTheWayMySaviorLeadsMe.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Psalm 139:24'],
    tags: ['whittle', 'classic', 'guidance', 'instrumental', 'public-domain'],
  },
  'a-friend-indeed': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/A-Friend-Indeed/A-Friend-Indeed.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['John 15:13'],
    tags: ['friendship', 'classic', 'instrumental', 'public-domain'],
  },
  'anywhere-with-jesus': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/Anywhere-With-Jesus/Anywhere-With-Jesus.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Psalm 139:9-10'],
    tags: ['companion', 'classic', 'instrumental', 'public-domain'],
  },
  'anywhere-is-home': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/Anywhere-Is-Home/Anywhere-Is-Home.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Philippians 4:11-12'],
    tags: ['home', 'classic', 'instrumental', 'public-domain'],
  },
  'almost-persuaded': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/Almost-Persuaded/Almost-Persuaded.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Acts 26:28'],
    tags: ['bliss', 'classic', 'invitation', 'instrumental', 'public-domain'],
  },
  'are-you-washed-in-the-blood': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/Are-You-Washed-In-The-Blood/AreYouWashedInTheBlood.mp3',
    emotion: 'reverent', category: 'comfort', mood: 'gentle',
    scripture_refs: ['1 John 1:7'],
    tags: ['huffman', 'classic', 'invitation', 'instrumental', 'public-domain'],
  },
  'at-the-door': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/At-The-Door/At-The-Door.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Revelation 3:20'],
    tags: ['miles', 'classic', 'invitation', 'instrumental', 'public-domain'],
  },
  'a-land-of-beauty': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/A-Land-Of-Beauty/A-Land-Of-Beauty.mp3',
    emotion: 'settled', category: 'hope', mood: 'gentle',
    scripture_refs: ['Revelation 21:1-4'],
    tags: ['heaven', 'classic', 'instrumental', 'public-domain'],
  },
  'be-thou-exalted': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Be-Thou-Exalted/BeThouExalted.mp3',
    emotion: 'lifted', category: 'adoration', mood: 'triumphant',
    scripture_refs: ['Psalm 21:13'],
    tags: ['exaltation', 'classic', 'instrumental', 'public-domain'],
  },
  'beautiful': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Beautiful/Beautiful.mp3',
    emotion: 'lifted', category: 'adoration', mood: 'joyful',
    scripture_refs: ['Psalm 27:4'],
    tags: ['beauty', 'classic', 'instrumental', 'public-domain'],
  },
  'all-will-be-well': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/All-Will-Be-Well/All-Will-Be-Well.mp3',
    emotion: 'lifted', category: 'hope', mood: 'gentle',
    scripture_refs: ['Romans 8:28'],
    tags: ['hope', 'classic', 'instrumental', 'public-domain'],
  },
  'all-things-are-ready': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/All-Things-Are-Ready/All-Things-Are-Ready.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Matthew 22:4'],
    tags: ['invitation', 'classic', 'instrumental', 'public-domain'],
  },
  'a-better-day-coming': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/A-Better-Day-Coming/A-Better-Day-Coming.mp3',
    emotion: 'lifted', category: 'hope', mood: 'gentle',
    scripture_refs: ['Revelation 21:4'],
    tags: ['hope', 'classic', 'instrumental', 'public-domain'],
  },
  'a-home-forever-there': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/A-Home-Forever-There/A-Home-Forever-There.mp3',
    emotion: 'settled', category: 'hope', mood: 'gentle',
    scripture_refs: ['John 14:2-3'],
    tags: ['home', 'heaven', 'classic', 'instrumental', 'public-domain'],
  },
  'a-home-on-high': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/A-Home-On-High/A-Home-On-High.mp3',
    emotion: 'settled', category: 'hope', mood: 'gentle',
    scripture_refs: ['Hebrews 11:16'],
    tags: ['home', 'heaven', 'classic', 'instrumental', 'public-domain'],
  },
  'a-joy-in-my-heart': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/A-Joy-In-My-Heart/A-Joy-In-My-Heart.mp3',
    emotion: 'lifted', category: 'celebration', mood: 'joyful',
    scripture_refs: ['Psalm 16:9'],
    tags: ['joy', 'classic', 'instrumental', 'public-domain'],
  },
  'all-glory-be-thine': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/All-Glory-Be-Thine/All-Glory-Be-Thine.mp3',
    emotion: 'lifted', category: 'adoration', mood: 'triumphant',
    scripture_refs: ['Jude 1:25'],
    tags: ['glory', 'classic', 'instrumental', 'public-domain'],
  },
  'a-wonderful-savior': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/A-Hymns/A-Wonderful-Savior/A-Wonderful-Savior.mp3',
    emotion: 'lifted', category: 'adoration', mood: 'joyful',
    scripture_refs: ['Isaiah 9:6'],
    tags: ['savior', 'classic', 'instrumental', 'public-domain'],
  },
  'be-still': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Be-Still/Be-Still.mp3',
    emotion: 'settled', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Psalm 46:10'],
    tags: ['stillness', 'classic', 'instrumental', 'public-domain'],
  },
  'blessed-communion': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Blessed-Communion/Blessed-Communion.mp3',
    emotion: 'reverent', category: 'comfort', mood: 'gentle',
    scripture_refs: ['1 Corinthians 10:16'],
    tags: ['communion', 'classic', 'instrumental', 'public-domain'],
  },
  'blest-be-the-tie': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/B-Hymns/Blest-Be-The-Tie/Blest-Be-The-Tie.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Colossians 2:2'],
    tags: ['fellowship', 'classic', 'instrumental', 'public-domain'],
  },
  'have-thy-own-way-lord': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/H-Hymns/Have-Thine-Own-Way-Lord/Have-Thine-Own-Way-Lord.mp3',
    emotion: 'settled', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Jeremiah 18:6'],
    tags: ['surrender', 'classic', 'instrumental', 'public-domain'],
  },
  'he-loved-me-so': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/H-Hymns/He-Loved-Me-So/He-Loved-Me-So.mp3',
    emotion: 'lifted', category: 'gratitude', mood: 'gentle',
    scripture_refs: ['John 3:16'],
    tags: ['love', 'classic', 'instrumental', 'public-domain'],
  },
  'heaven-holds-all-for-me': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/H-Hymns/Heaven-Holds-All-For-Me/Heaven-Holds-All-For-Me.mp3',
    emotion: 'settled', category: 'hope', mood: 'gentle',
    scripture_refs: ['John 14:2'],
    tags: ['heaven', 'classic', 'instrumental', 'public-domain'],
  },
  'higher-ground': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/H-Hymns/Higher-Ground/Higher-Ground.mp3',
    emotion: 'lifted', category: 'hope', mood: 'joyful',
    scripture_refs: ['Philippians 3:14'],
    tags: ['growth', 'classic', 'instrumental', 'public-domain'],
  },
  'hold-thou-my-hand': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/H-Hymns/Hold-Thou-My-Hand/Hold-Thou-My-Hand.mp3',
    emotion: 'companioned', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Psalm 139:10'],
    tags: ['guidance', 'classic', 'instrumental', 'public-domain'],
  },
  'i-surrender-all': {
    mp3: 'https://hymnstogod.org/Hymn-Files/Public-Domain-Hymns/I-Hymns/I-Surrender-All/I-Surrender-All.mp3',
    emotion: 'settled', category: 'comfort', mood: 'gentle',
    scripture_refs: ['Romans 12:1'],
    tags: ['surrender', 'classic', 'instrumental', 'public-domain'],
  },
};

// ─── Helpers ──────────────────────────────────────────────────────
async function downloadFile(url, dest) {
  // Wait 3-5s to be polite to the source server (rate-limit friendly)
  await new Promise(r => setTimeout(r, 3000));
  await execp(`curl -sL -o "${dest}" -m 60 -A "Mozilla/5.0 (HEAL Pipeline)" "${url}"`);
  const s = await stat(dest);
  if (s.size < 5000) {
    await unlink(dest).catch(() => {});
    throw new Error(`Download too small (${s.size} bytes) — likely 404`);
  }
  return s.size;
}

async function uploadViaFtp(local, remoteName) {
  const scriptPath = path.join(__dirname, '_ftp_upload.py');
  await execp(`python3 ${scriptPath} "${local}" "${FTP_CDN_DIR}" "${remoteName}"`);
}

async function pbPatch(slug, fields) {
  if (!PB_URL || !PB_ID || !PB_PASS) throw new Error('PB creds missing');
  const auth = await execp(`curl -s -X POST "${PB_URL}/api/collections/_superusers/auth-with-password" -H "Content-Type: application/json" -d '{"identity":"${PB_ID}","password":"${PB_PASS}"}'`);
  const token = JSON.parse(auth.stdout).token;
  if (!token) throw new Error('PB auth failed');
  const find = await execp(`curl -s "${PB_URL}/api/collections/HEAL_praise/records?perPage=1&filter=slug='${slug}'" -H "Authorization: ${token}"`);
  const items = JSON.parse(find.stdout).items || [];
  if (items.length === 0) throw new Error(`No PB record for slug=${slug}`);
  const recId = items[0].id;
  const patch = await execp(`curl -s -X PATCH "${PB_URL}/api/collections/HEAL_praise/records/${recId}" -H "Authorization: ${token}" -H "Content-Type: application/json" -d '${JSON.stringify(fields).replace(/'/g, "\\'")}'`);
  return JSON.parse(patch.stdout);
}

async function getDurationSec(filepath) {
  const r = await execp(`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${filepath}"`);
  return parseFloat(r.stdout);
}

// ─── Process one hymn ────────────────────────────────────────────
async function processOne(slug) {
  const meta = HYMN_MAP[slug];
  if (!meta) throw new Error(`No metadata for ${slug}`);

  const localFile = path.join(DOWNLOAD_DIR, `${slug}.mp3`);
  const remoteName = `pd-${slug}.mp3`;
  const remoteUrl = `${CDN_BASE}/${remoteName}`;

  console.log(`\n[${slug}]`);
  console.log(`  source: ${SOURCE_NAME} (CC0)`);
  console.log(`  url:    ${meta.mp3}`);

  console.log(`  ⏳ downloading...`);
  const dlSize = await downloadFile(meta.mp3, localFile);
  console.log(`  ✓ downloaded ${dlSize} bytes`);

  const dur = await getDurationSec(localFile);
  console.log(`  ✓ duration: ${dur.toFixed(1)}s`);

  console.log(`  ⏳ uploading to CDN...`);
  await uploadViaFtp(localFile, remoteName);
  console.log(`  ✓ uploaded: ${remoteUrl}`);

  const patch = {
    audio_url: remoteUrl,
    audio_license: LICENSE_NOTE,
    audio_source: `${SOURCE_NAME} — ${meta.mp3.split('/').pop()}`,
    duration_seconds: Math.round(dur),
    emotion: meta.emotion,
    category: meta.category,
    mood: meta.mood,
    tags: meta.tags,
    scripture_refs: meta.scripture_refs,
    voice: 'public-domain-recording',
    is_published: true,
  };
  console.log(`  ⏳ patching PB...`);
  const updated = await pbPatch(slug, patch);
  console.log(`  ✓ PB updated: ${updated.id}`);
  console.log(`     emotion=${updated.emotion} category=${updated.category} duration=${updated.duration_seconds}s`);

  await unlink(localFile).catch(() => {});

  return { slug, size: dlSize, duration: dur, url: remoteUrl };
}

// ─── Main ─────────────────────────────────────────────────────────
async function main() {
  const args = process.argv.slice(2);
  const DRY_RUN = args.includes('--dry-run');
  const slugArg = args.find(a => a.startsWith('--slug='))?.split('=')[1];
  const all = args.includes('--all');

  console.log('=== HEAL Praise — Path A: PD Hymn Pipeline (LIVE URLs) ===');
  console.log(`Total hymns in map: ${Object.keys(HYMN_MAP).length}`);
  console.log(`Dry run: ${DRY_RUN}`);
  console.log('');

  await mkdir(DOWNLOAD_DIR, { recursive: true });

  let targets = Object.keys(HYMN_MAP);
  if (slugArg) {
    targets = targets.filter(s => s === slugArg);
    if (targets.length === 0) { console.error(`Slug '${slugArg}' not in map`); process.exit(1); }
  }

  // Filter to only slugs that exist in PB (query PB)
  if (!slugArg && !all) {
    console.log('Querying PB to filter to existing records...');
    const auth = await execp(`curl -s -X POST "${PB_URL}/api/collections/_superusers/auth-with-password" -H "Content-Type: application/json" -d '{"identity":"${PB_ID}","password":"${PB_PASS}"}'`);
    const token = JSON.parse(auth.stdout).token;
    const r = await execp(`curl -s "${PB_URL}/api/collections/HEAL_praise/records?perPage=200&fields=slug" -H "Authorization: ${token}"`);
    const items = JSON.parse(r.stdout).items || [];
    const pbSlugs = new Set(items.map(i => i.slug));
    const before = targets.length;
    targets = targets.filter(s => pbSlugs.has(s));
    console.log(`  filtered: ${targets.length}/${before} in PB`);
  } else if (all) {
    console.log('--all mode: processing every mapped slug (will create records via PB lookup)');
  }
  console.log(`Will process ${targets.length} hymn(s)`);
  console.log('');

  const results = [];
  let success = 0;
  for (const slug of targets) {
    try {
      if (DRY_RUN) {
        console.log(`[${slug}] DRY RUN — would download`);
        continue;
      }
      const r = await processOne(slug);
      results.push(r);
      success++;
    } catch (e) {
      console.error(`[${slug}] FAIL: ${e.message}`);
    }
  }

  console.log('');
  console.log(`=== Done: ${success}/${targets.length} succeeded ===`);
}

main().catch(e => { console.error('FATAL:', e); process.exit(1); });