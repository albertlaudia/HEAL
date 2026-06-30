#!/usr/bin/env node
/**
 * HEAL — Inject local media paths into meditation JSONs
 * After generating illustrations + audio, run this to add
 * `audio_file` and `illustration_file` keys to each meditation.
 * The seed script will replace the file names with B2 URLs after upload.
 */
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname + 'content/meditations';

const files = (await readdir(ROOT)).filter(f => /^\d{3}-.+\.json$/.test(f));
let updated = 0;
for (const f of files) {
  const p = join(ROOT, f);
  const m = JSON.parse(await readFile(p, 'utf8'));
  m.illustration_file = `illustration-${m.slug}.png`;
  m.audio_file = `audio-${m.slug}.mp3`;
  await writeFile(p, JSON.stringify(m, null, 2));
  updated++;
}
console.log(`✓ Updated ${updated} meditation JSONs with local media paths`);
