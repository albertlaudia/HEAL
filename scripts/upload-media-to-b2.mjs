#!/usr/bin/env node
/**
 * HEAL — Upload local media files to Backblaze B2 under HEAL/ root.
 * Uses B2 Native API (S3-compatible path-style is also fine, this uses the
 * native b2_authorize_account + b2_upload_file + b2_get_upload_url flow).
 *
 * Files are read from /content/meditations/illustration-*.{png,webp,jpg}
 * and /content/meditations/audio-*.mp3 (or any *.mp3 in any content subdir)
 * and uploaded preserving the relative path under HEAL/.
 *
 * Env: B2_KEY_ID, B2_APPLICATION_KEY, B2_BUCKET_ID, B2_BUCKET_NAME, B2_PUBLIC_URL
 */

import { readdir, readFile, stat } from 'node:fs/promises';
import { join, relative, dirname, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';

const __dirname = dirname(fileURLToPath(import.meta.url));
const CONTENT_DIR = join(__dirname, '..', 'content');

const KEY_ID = process.env.B2_KEY_ID;
const APP_KEY = process.env.B2_APPLICATION_KEY;
const BUCKET_ID = process.env.B2_BUCKET_ID;
const BUCKET_NAME = process.env.B2_BUCKET_NAME || 'heal-media';
const PUBLIC_URL = process.env.B2_PUBLIC_URL || `https://f004.backblazeb2.com/file/${BUCKET_NAME}`;

if (!KEY_ID || !APP_KEY || !BUCKET_ID) {
  console.error('❌ Set B2_KEY_ID, B2_APPLICATION_KEY, B2_BUCKET_ID');
  process.exit(1);
}

const MIME = {
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.m4a': 'audio/mp4',
  '.json': 'application/json',
};

let auth = null;
let uploadUrl = null;
let uploadToken = null;
const urlCache = new Map();

async function b2api(path, opts = {}) {
  const url = `https://api.backblazeb2.com${path}`;
  const r = await fetch(url, opts);
  const text = await r.text();
  if (!r.ok) throw new Error(`B2 ${path} → ${r.status}: ${text}`);
  return text.startsWith('{') || text.startsWith('[') ? JSON.parse(text) : text;
}

async function authorize() {
  const cred = Buffer.from(`${KEY_ID}:${APP_KEY}`).toString('base64');
  auth = await b2api('/b2api/v2/b2_authorize_account', {
    headers: { Authorization: `Basic ${cred}` },
  });
  console.log(`  ✓ authorized (apiUrl=${auth.apiUrl})`);
}

async function getUploadUrl() {
  const r = await b2api('/b2api/v2/b2_get_upload_url', {
    method: 'POST',
    headers: { Authorization: auth.authorizationToken, 'Content-Type': 'application/json' },
    body: JSON.stringify({ bucketId: BUCKET_ID }),
  });
  uploadUrl = r.uploadUrl;
  uploadToken = r.authorizationToken;
}

async function walkFiles(dir) {
  const out = [];
  let entries;
  try { entries = await readdir(dir, { withFileTypes: true }); }
  catch (e) { if (e.code === 'ENOENT') return out; throw e; }
  for (const e of entries) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...await walkFiles(p));
    else if (e.isFile()) {
      const s = await stat(p);
      if (s.size > 0) out.push(p);
    }
  }
  return out;
}

async function uploadOne(localPath) {
  const rel = relative(CONTENT_DIR, localPath).replaceAll('\\', '/');
  const b2Name = `HEAL/${rel}`;
  const ext = extname(localPath).toLowerCase();
  const mime = MIME[ext] || 'application/octet-stream';
  const body = await readFile(localPath);
  const sha1 = crypto.createHash('sha1').update(body).digest('hex');

  if (urlCache.has(b2Name)) {
    // Re-use upload url token (per file we get a new one usually, but B2 allows reuse)
  }
  await getUploadUrl();
  const r = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      Authorization: uploadToken,
      'X-Bz-File-Name': encodeURIComponent(b2Name).replace(/%2F/g, '/'),
      'Content-Type': mime,
      'Content-Length': String(body.length),
      'X-Bz-Content-Sha1': sha1,
      'X-Bz-Info-src_last_modified_millis': String(Date.now()),
    },
    body,
  });
  const text = await r.text();
  if (!r.ok) {
    if (text.includes('duplicate')) {
      return { url: `${PUBLIC_URL}/${b2Name}`, dedup: true };
    }
    throw new Error(`upload ${b2Name} → ${r.status}: ${text}`);
  }
  return { url: `${PUBLIC_URL}/${b2Name}`, dedup: false };
}

async function main() {
  console.log('🌿 HEAL — B2 media upload');
  await authorize();
  const files = await walkFiles(CONTENT_DIR);
  const media = files.filter(f => /\.(png|jpg|jpeg|webp|svg|mp3|wav|m4a)$/i.test(f));
  if (!media.length) { console.log('  (no media files in /content)'); return; }
  console.log(`  uploading ${media.length} files under HEAL/...`);
  let ok = 0, dedup = 0, err = 0;
  const urlMap = {};
  for (const f of media) {
    try {
      const { url, dedup: d } = await uploadOne(f);
      ok++;
      if (d) dedup++;
      const rel = relative(CONTENT_DIR, f).replaceAll('\\', '/');
      urlMap[rel] = url;
      process.stdout.write(d ? '·' : '↑');
    } catch (e) {
      err++;
      console.error(`\n  ❌ ${f}: ${e.message}`);
    }
  }
  // Write URL map
  const mapPath = join(CONTENT_DIR, '.url-map.json');
  await readFile(mapPath).catch(() => null);
  const { writeFile } = await import('node:fs/promises');
  await writeFile(mapPath, JSON.stringify(urlMap, null, 2));
  console.log(`\n  ✓ ${ok} uploaded (${dedup} dedup), ${err} errors`);
  console.log(`  ✓ URL map: ${mapPath}`);
}

main().catch(e => { console.error('💥', e); process.exit(1); });
