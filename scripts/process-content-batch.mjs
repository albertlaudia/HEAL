#!/usr/bin/env node
/**
 * HEAL Content Batch Pipeline
 * Usage: node scripts/process-content-batch.mjs --batch=1
 *
 * Env vars required:
 *   PB_URL, PB_PASSWORD, PB_IDENTITY, FTP_PASSWORD
 *   (or pass --pb-url, --pb-email, --pb-password, --ftp-password)
 */

import { createRequire } from 'module';
import { readFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

// --- CLI args ---
const args = Object.fromEntries(
  process.argv.slice(2).map(a => {
    const [k, v] = a.replace(/^--/, '').split('=');
    return [k, v];
  })
);

const BATCH_N = String(args.batch || args.b || '1').padStart(3, '0');
const BATCH_FILE = join(__dirname, '..', 'data', 'content-batches', `batch-${BATCH_N}.json`);

const PB_URL    = args['pb-url']    || process.env.PB_URL    || 'https://pocketbase.scaleupcrm.com';
const PB_EMAIL  = args['pb-email']  || process.env.PB_IDENTITY || 'minimax@scaleupcrm.com';
const PB_PASS   = args['pb-password']|| process.env.PB_PASSWORD || '8ik,9ol.Q123!';
const FTP_PASS  = args['ftp-password']|| process.env.FTP_PASSWORD;
const FTP_HOST  = 'win8108.site4now.net';
const FTP_USER  = 'respc';
const FTP_BASE  = 'ftp://' + FTP_HOST;
const CDN_BASE  = 'https://resources.positiveness.club';
const COLLECTION = 'HEAL_meditations';

const RETRY_MAX = 5;
const RETRY_DELAY = (n) => new Promise(r => setTimeout(r, n * 1000));

// ─── Helpers ────────────────────────────────────────────────────────────────

function log(msg) {
  console.log(`[${new Date().toISOString().slice(11,19)}] ${msg}`);
}

async function curl({ url, method = 'GET', headers = {}, body = null, auth = null, maxRetries = 2 }) {
  const opts = { method, headers: { 'Content-Type': 'application/json', ...headers } };
  if (auth) opts.headers['Authorization'] = auth;
  if (body) opts.body = JSON.stringify(body);
  for (let attempt = 1; attempt <= maxRetries + 1; attempt++) {
    const res = await fetch(url, opts);
    const text = await res.text();
    let json;
    try { json = JSON.parse(text); } catch { json = { _raw: text }; }
    if (!res.ok && attempt <= maxRetries) {
      log(`  ⚠ ${method} ${url} → ${res.status}, retry ${attempt}…`);
      await RETRY_DELAY(attempt);
      continue;
    }
    return { status: res.status, ok: res.ok, json };
  }
  throw new Error(`curl failed after ${maxRetries + 1} attempts`);
}

async function pbAuth() {
  log('Authenticating with PocketBase…');
  const { json } = await curl({
    url: `${PB_URL}/api/collections/_superusers/auth-with-password`,
    method: 'POST',
    body: { identity: PB_EMAIL, password: PB_PASS }
  });
  if (!json.token) throw new Error('PB auth failed: ' + JSON.stringify(json));
  log('  ✓ Authenticated');
  return json.token;
}

async function pbUpsert(token, record) {
  const filter = `slug='${record.slug}'`;
  const { json: existing } = await curl({
    url: `${PB_URL}/api/collections/${COLLECTION}/records?filter=${encodeURIComponent(filter)}&maxTotal=1`,
    headers: { Authorization: token }
  });

  const payload = {
    title: record.title,
    slug: record.slug,
    theme: record.theme,
    season: record.season || 'ordinary',
    scripture_ref: record.scripture_ref || '',
    translation: record.translation || '',
    scripture_text: record.scripture_text || '',
    reflection: record.reflection || '',
    body: record.body || '',
    prayer: record.prayer || '',
    duration_seconds: record.duration_seconds || 540,
    sort_order: record.sort_order || 0,
    is_published: record.is_published !== undefined ? record.is_published : false,
    tags: record.tags || [],
    audio_url: record.audio_url || ''
  };

  if (existing.items && existing.items[0]) {
    const id = existing.items[0].id;
    const { json } = await curl({
      url: `${PB_URL}/api/collections/${COLLECTION}/records/${id}`,
      method: 'PATCH',
      headers: { Authorization: token },
      body: payload
    });
    log(`  ✓ PATCH ${record.slug} (${id})`);
    return json;
  } else {
    const { json } = await curl({
      url: `${PB_URL}/api/collections/${COLLECTION}/records`,
      method: 'POST',
      headers: { Authorization: token },
      body: payload
    });
    log(`  ✓ POST  ${record.slug} → ${json.id}`);
    return json;
  }
}

async function ftpUpload(localPath, remotePath) {
  if (!existsSync(localPath)) {
    log(`  ✗ File not found: ${localPath}`);
    return false;
  }

  const destUrl = `${FTP_BASE}/${remotePath}`;
  const auth = `--user ${FTP_USER}:${FTP_PASS}`;

  // MKD parent dirs (one level at a time)
  const parts = remotePath.split('/').slice(0, -1);
  let cur = '';
  for (const part of parts) {
    cur += part + '/';
    // silent MKD — it may already exist
    await new Promise(res => setTimeout(res, 200));
    await new Promise((resolve) => {
      const { execSync } = require('child_process');
      try {
        execSync(`curl -s -Q "MKD ${cur}" ${auth} ${FTP_BASE}/`, { stdio: 'pipe' });
      } catch {}
      resolve();
    });
  }

  for (let attempt = 1; attempt <= RETRY_MAX; attempt++) {
    try {
      const { execSync } = require('child_process');
      const output = execSync(
        `curl -s -w "\\n%{http_code}" ${auth} --limit-rate 200K --ftp-create-dirs --disable-epsv --max-time 120 -T "${localPath}" "${destUrl}"`,
        { stdio: 'pipe' }
      ).toString();
      const http_code = output.trim().split('\n').pop();
      if (http_code === '226' || http_code === '150') {
        const filename = localPath.split('/').pop();
        log(`  ✓ Uploaded ${filename} (attempt ${attempt})`);
        return true;
      }
      log(`  ⚠ FTP attempt ${attempt} → HTTP ${http_code}`);
    } catch (e) {
      log(`  ⚠ FTP attempt ${attempt} failed: ${e.message.slice(0, 80)}`);
    }
    if (attempt < RETRY_MAX) await RETRY_DELAY(attempt);
  }
  log(`  ✗ FTP failed after ${RETRY_MAX} attempts: ${localPath}`);
  return false;
}

async function cdnVerify(slug) {
  const url = `${CDN_BASE}/heal/audio/meditations/${slug}.mp3`;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const res = await fetch(url, { method: 'HEAD' });
      if (res.ok) {
        log(`  ✓ CDN 200 ${url}`);
        return true;
      }
      log(`  ⚠ CDN ${res.status} (attempt ${attempt})`);
    } catch (e) {
      log(`  ⚠ CDN error ${attempt}: ${e.message}`);
    }
    if (attempt < 3) await RETRY_DELAY(attempt);
  }
  return false;
}

// ─── Main ───────────────────────────────────────────────────────────────────

async function main() {
  log(`=== HEAL Batch ${BATCH_N} Pipeline ===`);

  // 1. Load batch
  if (!existsSync(BATCH_FILE)) {
    log(`✗ Batch file not found: ${BATCH_FILE}`);
    process.exit(1);
  }
  const batch = JSON.parse(readFileSync(BATCH_FILE, 'utf8'));
  if (!Array.isArray(batch) || batch.length === 0) {
    log('✗ Batch file is empty — nothing to process');
    process.exit(0);
  }
  log(`Loaded ${batch.length} meditations from batch-${BATCH_N}.json`);

  // 2. Auth
  const token = await pbAuth();

  // 3. Upload audio + PB upsert for each
  for (const med of batch) {
    const audioPath = `/workspace/.tmp-audio/heal/${med.slug}.mp3`;
    const cdnSlug = med.slug;

    // Upload to FTP if audio exists locally
    if (existsSync(audioPath)) {
      await ftpUpload(audioPath, `heal/audio/meditations/${cdnSlug}.mp3`);
    }

    // PB upsert (use CDN URL as audio_url)
    const record = { ...med, audio_url: `${CDN_BASE}/heal/audio/meditations/${cdnSlug}.mp3` };
    try {
      await pbUpsert(token, record);
    } catch (e) {
      log(`✗ PB upsert failed for ${med.slug}: ${e.message}`);
    }
  }

  // 4. CDN verify all
  log('Verifying CDN…');
  for (const med of batch) {
    await cdnVerify(med.slug);
  }

  log('=== Pipeline complete ===');
}

main().catch(e => {
  log(`FATAL: ${e.message}`);
  process.exit(1);
});
