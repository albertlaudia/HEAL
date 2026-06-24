#!/usr/bin/env node
/**
 * HEAL — process a pre-generated content batch end-to-end.
 *
 * Inputs (data/content-batches/batch-NNN.json):
 *   {
 *     "content": [
 *       { "type": "meditation", "title", "slug", "body" (300-700 words), ...all fields for PB }
 *     ]
 *   }
 *
 * For each content item:
 *   1. Generate audio via TTS (if meditation has body)
 *   2. POST to PocketBase (HEAL_meditations / HEAL_prayers / HEAL_quotes / HEAL_essays / HEAL_praise)
 *   3. Upload audio to CDN (FTP) if generated
 *   4. PATCH PB with audio_url
 *
 * Run modes:
 *   node process-content-batch.mjs --batch=1
 *   node process-content-batch.mjs --batch=1 --content=meditations
 *
 * Required env:
 *   PB_URL, PB_IDENTITY, PB_PASSWORD
 *   FTP_HOST, FTP_USER, FTP_PASSWORD  (default: SmarterASP respc)
 *   CDN_BASE  (default: https://resources.positiveness.club/heal)
 *
 * Output:
 *   pipeline/queue/progress.json (append-only run history)
 *   pipeline/queue/state.json (next_batch pointer)
 */
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "url";
import { execFile } from "node:child_process";
import { promisify } from "util";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "..");
const BATCH_DIR = path.join(ROOT, "data/content-batches");
const PROGRESS_PATH = path.join(ROOT, "pipeline/queue/progress.json");
const STATE_PATH = path.join(ROOT, "pipeline/queue/state.json");

const execFileP = promisify(execFile);

const args = process.argv.slice(2);
const getArg = (name) => {
  const a = args.find((a) => a.startsWith(`--${name}=`));
  return a ? a.split("=").slice(1).join("=") : null;
};
const BATCH = parseInt(getArg("batch") || "1", 10);
const CONTENT_FILTER = getArg("content"); // e.g. "meditations"

const PB_URL = process.env.PB_URL || "https://pocketbase.scaleupcrm.com";
const PB_IDENTITY = process.env.PB_IDENTITY;
const PB_PASSWORD = process.env.PB_PASSWORD;
const FTP_HOST = process.env.FTP_HOST || "win8108.site4now.net";
const FTP_USER = process.env.FTP_USER || "respc";
const FTP_PASS = process.env.FTP_PASSWORD || process.env.FTP_PASS;
const CDN_BASE = process.env.CDN_BASE || "https://resources.positiveness.club/heal";

const log = (m) => console.log(`[${new Date().toISOString()}] ${m}`);

if (!PB_IDENTITY || !PB_PASSWORD) {
  console.error("Set PB_IDENTITY and PB_PASSWORD");
  process.exit(1);
}
if (!FTP_PASS) {
  console.error("Set FTP_PASSWORD env");
  process.exit(1);
}

// === Load batch file ===
const batchPath = path.join(BATCH_DIR, `batch-${String(BATCH).padStart(3, "0")}.json`);
let batch;
try {
  batch = JSON.parse(await fs.readFile(batchPath, "utf8"));
} catch (e) {
  log(`✗ Cannot read batch file ${batchPath}: ${e.message}`);
  process.exit(1);
}
log(`Loaded batch ${BATCH}: ${batch.content.length} items from ${batchPath}`);

let itemsToProcess = batch.content;
if (CONTENT_FILTER) {
  itemsToProcess = itemsToProcess.filter((it) => it.type === CONTENT_FILTER.replace(/s$/, ""));
  log(`Filtered to ${itemsToProcess.length} ${CONTENT_FILTER}`);
}

// === PB auth ===
const authRes = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ identity: PB_IDENTITY, password: PB_PASSWORD }),
});
const { token } = await authRes.json();
if (!token) {
  console.error("PB auth failed");
  process.exit(1);
}
const H = { "Content-Type": "application/json", Authorization: token };
const api = (p, init) => fetch(`${PB_URL}/api/${p}`, { ...init, headers: { ...H, ...(init?.headers || {}) } });
log("✓ PB authed");

// === Find collection IDs ===
const cols = await (await api("collections?perPage=200")).json();
const findCol = (n) => cols.items.find((c) => c.name === n);
const colMap = {
  meditation: findCol("HEAL_meditations"),
  prayer: findCol("HEAL_prayers"),
  quote: findCol("HEAL_quotes"),
  scripture: findCol("HEAL_scriptures"),
  essay: findCol("HEAL_essays"),
  praise: findCol("HEAL_praise"),
  breathwork: findCol("HEAL_breathwork"),
};
for (const [k, v] of Object.entries(colMap)) {
  if (v) log(`  ${k}: ${v.id}`);
}

// === Helper: FTP upload ===
async function ftpUpload(localPath, remotePath) {
  const url = `ftp://${FTP_HOST}/${remotePath}`;
  const cmd = `curl -s --user "${FTP_USER}:${FTP_PASS}" --limit-rate 200K --ftp-create-dirs --disable-epsv -T "${localPath}" "${url}"`;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      await execFileP("bash", ["-c", cmd], { timeout: 180000 });
      return true;
    } catch (e) {
      log(`  FTP upload attempt ${attempt}/3 failed for ${remotePath}: ${e.message?.slice(0, 200)}`);
      if (attempt < 3) await new Promise((r) => setTimeout(r, 1500 * attempt));
    }
  }
  return false;
}

// === Helper: measure audio duration ===
async function measureAudio(filePath) {
  try {
    const { stdout } = await execFileP("ffprobe", [
      "-v", "error", "-show_entries", "format=duration",
      "-of", "default=noprint_wrappers=1:nokey=1", filePath,
    ], { timeout: 10000 });
    return Math.round(parseFloat(stdout.trim()));
  } catch {
    return 0;
  }
}

// === TTS: write TTS placeholder, then run via shell ===
// We can't call TTS from inside Node directly. The cron agent will pre-generate
// audio into /workspace/.tmp-audio/heal/<slug>.mp3 BEFORE running this script.
// This script just uploads the local files + POSTs to PB.
async function checkLocalAudio(slug) {
  const p = `/workspace/.tmp-audio/heal/${slug}.mp3`;
  try {
    const stat = await fs.stat(p);
    return stat.size > 1000 ? p : null;
  } catch {
    return null;
  }
}

// === Helper: check if item already in PB ===
async function findExistingPBItem(collectionId, slug) {
  const r = await api(`collections/${collectionId}/records?filter=${encodeURIComponent(`slug="${slug}"`)}&perPage=1`);
  const data = await r.json();
  return data.items?.[0] || null;
}

// === Main orchestration ===
const results = [];
for (const item of itemsToProcess) {
  const itemResult = { type: item.type, slug: item.slug, title: item.title, status: "pending", errors: [] };
  try {
    log(`\n=== Processing: ${item.type} / ${item.slug} ===`);

    const collection = colMap[item.type];
    if (!collection) {
      throw new Error(`No PB collection found for type "${item.type}"`);
    }

    // Check existing
    const existing = await findExistingPBItem(collection.id, item.slug);
    let pbId;
    if (existing) {
      pbId = existing.id;
      log(`  → Reusing existing PB record: ${pbId}`);
    } else {
      // POST new
      const pbPayload = { ...item };
      // Strip audio_url from POST — we'll set it after audio upload
      delete pbPayload.audio_url;
      delete pbPayload.illustration_url;

      const postRes = await api(`collections/${collection.id}/records`, {
        method: "POST",
        body: JSON.stringify(pbPayload),
      });
      if (!postRes.ok) {
        const err = await postRes.text();
        // If duplicate slug, look it up and reuse
        if (err.includes("unique") || err.includes("VALIDATION")) {
          const lookup = await findExistingPBItem(collection.id, item.slug);
          if (lookup) {
            pbId = lookup.id;
            log(`  → Slug collision, reusing: ${pbId}`);
          } else {
            throw new Error(`PB POST failed and lookup returned nothing: ${err.slice(0, 200)}`);
          }
        } else {
          throw new Error(`PB POST failed: ${err.slice(0, 200)}`);
        }
      } else {
        const created = await postRes.json();
        pbId = created.id;
        log(`  ✓ Created PB record: ${pbId}`);
      }
    }

    // Upload audio if it's a meditation with body
    if (item.type === "meditation" && item.body) {
      const localAudio = await checkLocalAudio(item.slug);
      if (localAudio) {
        const remoteAudio = `heal/audio/meditations/${item.slug}.mp3`;
        const ok = await ftpUpload(localAudio, remoteAudio);
        if (ok) {
          const audioDuration = await measureAudio(localAudio);
          const audioUrl = `${CDN_BASE}/audio/meditations/${item.slug}.mp3`;
          // PATCH PB with audio_url + duration_seconds
          await api(`collections/${collection.id}/records/${pbId}`, {
            method: "PATCH",
            body: JSON.stringify({
              audio_url: audioUrl,
              duration_seconds: item.duration_seconds || audioDuration,
            }),
          });
          log(`  ✓ Audio uploaded + PB patched: ${audioUrl} (${audioDuration}s)`);
        } else {
          itemResult.errors.push("FTP upload failed");
        }
      } else {
        log(`  · No local audio for ${item.slug}, skipping audio upload`);
        itemResult.errors.push("no local audio");
      }
    }

    itemResult.status = "ok";
    itemResult.pbId = pbId;
  } catch (e) {
    itemResult.status = "error";
    itemResult.errors.push(e.message);
  }
  results.push(itemResult);
}

log("\n=== SUMMARY ===");
let okCount = 0;
let errCount = 0;
for (const r of results) {
  if (r.status === "ok") okCount++;
  else errCount++;
  log(`  ${r.type}/${r.slug}: ${r.status}${r.errors.length ? " (" + r.errors.join("; ") + ")" : ""}`);
}
log(`\nTOTAL: ${okCount} ok, ${errCount} errors, ${results.length} items processed`);

// Save progress
await fs.mkdir(path.dirname(PROGRESS_PATH), { recursive: true });
let progress = [];
try {
  progress = JSON.parse(await fs.readFile(PROGRESS_PATH, "utf8"));
} catch {}
progress.push({
  timestamp: new Date().toISOString(),
  batch: BATCH,
  total: results.length,
  ok: okCount,
  errors: errCount,
  results,
});
await fs.writeFile(PROGRESS_PATH, JSON.stringify(progress, null, 2));
log(`Progress saved to ${PROGRESS_PATH}`);

// Update state.json with next_batch
try {
  let state = {};
  try { state = JSON.parse(await fs.readFile(STATE_PATH, "utf8")); } catch {}
  state.next_batch = BATCH + 1;
  state.last_run = new Date().toISOString();
  state.last_batch_results = { ok: okCount, errors: errCount };
  await fs.writeFile(STATE_PATH, JSON.stringify(state, null, 2));
  log(`State updated: next_batch=${BATCH + 1}`);
} catch (e) {
  log(`! Could not update state.json: ${e.message}`);
}