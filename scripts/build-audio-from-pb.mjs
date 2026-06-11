// Build audio generation list for meditations that exist in PB but are missing audio.
// We must read from PB because the content/meditations/ dir has 420 records but PB only has 264.

import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import PocketBase from 'pocketbase';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const PB_URL = process.env.PB_URL || 'https://pocketbase.scaleupcrm.com';
const IDENTITY = process.env.PB_IDENTITY;
const PASSWORD = process.env.PASSWORD || process.env.PB_PASSWORD;

if (!IDENTITY || !PASSWORD) {
  console.error('❌ PB_IDENTITY and PB_PASSWORD must be set');
  process.exit(1);
}

const pb = new PocketBase(PB_URL);
pb.autoCancellation(false);
try {
  await pb.collection('_superusers').authWithPassword(IDENTITY, PASSWORD);
} catch {
  try { await pb.admins.authWithPassword(IDENTITY, PASSWORD); } catch { console.error('auth failed'); process.exit(1); }
}

const audioDir = path.join(ROOT, 'public', 'audio', 'meditations');
await fs.mkdir(audioDir, { recursive: true });

const audioSet = new Set(
  (await fs.readdir(audioDir))
    .filter((f) => f.endsWith('.mp3'))
    .map((f) => f.replace(/^audio-/, '').replace(/\.mp3$/, ''))
);

const meditations = await pb.collection('HEAL_meditations').getFullList({ filter: 'is_published = true' });
const missing = meditations.filter((m) => !audioSet.has(m.slug));

const items = missing.map((m) => ({
  slug: m.slug,
  title: m.title,
  kind: 'meditation',
  text: m.body,
  outputDir: 'public/audio/meditations',
  fileName: `audio-${m.slug}.mp3`,
  voice_id: 'English_CaptivatingStoryteller',
  speed: 0.92,
  pitch: -1,
  // Sub-batch to keep TTS in groups of 10
}));

const batches = [];
for (let i = 0; i < items.length; i += 10) batches.push(items.slice(i, i + 10));
await fs.writeFile('/tmp/missing-audio-batches.json', JSON.stringify(batches));
console.log(`Audio: ${items.length} missing → ${batches.length} batches of 10`);
