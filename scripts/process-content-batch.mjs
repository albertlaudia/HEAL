/**
 * process-content-batch.mjs
 * Reads batch-N.json, upserts into PocketBase HEAL_meditations,
 * then uploads audio via FTP using curl.
 *
 * Usage: PB_URL=https://... PB_PASSWORD=... FTP_PASSWORD=... \
 *        node scripts/process-content-batch.mjs --batch=N
 */

import { readFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ── CLI args ──────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const batchArg = args.find(a => a.startsWith('--batch='));
const batchNum = parseInt(batchArg?.split('=')[1], 10);
if (!batchNum) { console.error('[ERROR] Missing --batch=N'); process.exit(1); }

// ── Env ───────────────────────────────────────────────────────────────────────
const PB_URL   = process.env.PB_URL     || 'https://pocketbase.scaleupcrm.com';
const PB_USER  = 'minimax@scaleupcrm.com';
const PB_PASS  = process.env.PB_PASSWORD || '8ik,9ol.Q123!';
const FTP_HOST = 'win8108.site4now.net';
const FTP_USER = 'scaleupcrm';
const FTP_PASS = process.env.FTP_PASSWORD || 'R3sourceSc4leupCRM!';
const BATCH_FILE = resolve(__dirname, '..', 'data', 'content-batches',
  `batch-${String(batchNum).padStart(3,'0')}.json`);
const AUDIO_DIR  = '/workspace/.tmp-audio/heal';

// ── Helpers ───────────────────────────────────────────────────────────────────
const log = (msg) => console.log(`[${new Date().toISOString()}] ${msg}`);
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function pbFetch(path, method, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${PB_URL}${path}`, { method, headers, body: body ? JSON.stringify(body) : undefined });
  return res;
}

async function pbAuth() {
  const res = await pbFetch('/api/collections/_superusers/auth-with-password', 'POST',
    { identity: PB_USER, password: PB_PASS });
  if (!res.ok) throw new Error(`Auth failed (${res.status}): ${await res.text()}`);
  const data = await res.json();
  return data.token;
}

async function upsertMeditation(token, med) {
  // Check if exists by slug
  let existingId = null;
  try {
    const res = await pbFetch(
      `/api/collections/HEAL_meditations/records?filter=slug='${med.slug}'&limit=1`,
      'GET', null, token);
    if (res.ok) {
      const data = await res.json();
      if (data.items?.length > 0) existingId = data.items[0].id;
    }
  } catch (e) { /* ignore */ }

  const payload = {
    title: med.title, slug: med.slug, theme: med.theme, season: med.season,
    scripture_ref: med.scripture_ref, translation: med.translation,
    scripture_text: med.scripture_text, reflection: med.reflection,
    body: med.body, prayer: med.prayer, duration_seconds: med.duration_seconds,
    sort_order: med.sort_order, is_published: med.is_published, tags: med.tags,
  };

  const path = existingId
    ? `/api/collections/HEAL_meditations/records/${existingId}`
    : '/api/collections/HEAL_meditations/records';
  const method = existingId ? 'PATCH' : 'POST';

  const res = await pbFetch(path, method, payload, token);
  if (!res.ok) throw new Error(`${method} failed (${res.status}): ${await res.text()}`);
  const result = await res.json();
  return result.id || existingId;
}

function curlFTP(localPath, remotePath) {
  // Use curl with --disable-epsv and --limit-rate to avoid broken pipe issues
  return new Promise((resolve, reject) => {
    const child = spawn('curl', [
      '--user', `${FTP_USER}:${FTP_PASS}`,
      '--disable-epsv',
      '--limit-rate', '80K',
      '--ftp-create-dirs',
      '-T', localPath,
      `ftp://${FTP_HOST}${remotePath}`,
      '--silent', '--show-error',
    ]);
    let stderr = '';
    child.stderr.on('data', d => stderr += d.toString());
    child.on('close', code => {
      if (code === 0) resolve(remotePath);
      else reject(new Error(`curl FTP failed (${code}): ${stderr.trim()}`));
    });
    child.on('error', reject);
  });
}

// ── Main ──────────────────────────────────────────────────────────────────────
log(`Starting batch ${batchNum}`);
log(`Batch file: ${BATCH_FILE}`);

let batchData;
try {
  const raw = readFileSync(BATCH_FILE, 'utf8');
  batchData = JSON.parse(raw);
} catch (e) {
  console.error(`[ERROR] Cannot read/parse ${BATCH_FILE}: ${e.message}`);
  process.exit(1);
}
if (!Array.isArray(batchData)) { console.error('[ERROR] Batch must be array'); process.exit(1); }
log(`Loaded ${batchData.length} meditations`);

// Auth
let token;
try {
  token = await pbAuth();
  log('PB auth: OK');
} catch (e) {
  console.error(`[ERROR] PB auth: ${e.message}`);
  process.exit(1);
}

// Upsert
const upsertResults = [];
for (const med of batchData) {
  let ok = false;
  for (let attempt = 1; attempt <= 2 && !ok; attempt++) {
    try {
      const id = await upsertMeditation(token, med);
      upsertResults.push({ slug: med.slug, id, attempt });
      log(`  UPSERT OK  [attempt ${attempt}]: ${med.slug} → ${id}`);
      ok = true;
    } catch (e) {
      if (attempt === 1) {
        console.warn(`  UPSERT FAIL [1]: ${med.slug} — ${e.message}`);
        console.log(`  RETRYING ${med.slug}...`);
        await sleep(2000);
      } else {
        console.error(`  UPSERT FAIL [2]: ${med.slug} — ${e.message}`);
        upsertResults.push({ slug: med.slug, error: e.message });
      }
    }
  }
}

// FTP upload
for (const med of batchData) {
  const audioPath = `${AUDIO_DIR}/${med.slug}.mp3`;
  if (!existsSync(audioPath)) {
    log(`  FTP SKIP: ${med.slug}.mp3 not found`);
    continue;
  }
  const remotePath = `/heal/audio/meditations/${med.slug}.mp3`;
  try {
    await curlFTP(audioPath, remotePath);
    log(`  FTP OK: ${med.slug}.mp3`);
  } catch (e) {
    console.warn(`  FTP WARN: ${med.slug}.mp3 — ${e.message}`);
  }
}

log(`Batch ${batchNum} done.`);
console.log(JSON.stringify({ batch: batchNum, results: upsertResults }));
