#!/usr/bin/env node
/**
 * HEAL — Audio batch
 * Reads /content/meditations/*.json and emits a manifest of TTS prompts
 * for batch_text_to_audio. We use a calm male English voice for v1.
 * The actual synthesis happens via the runtime tool from a session.
 */
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', 'content', 'meditations');

// Read HEAL_VOICE_ID from env so the same script works with a cloned
// voice once the user records a sample. Falls back to a calm default.
const VOICE = process.env.HEAL_VOICE_ID || 'English_CaptivatingStoryteller';
const SPEED = 0.92;     // slower, more contemplative
const PITCH = -1;       // slightly lower / warmer

function ttsScript(m) {
  // Reads the meditation slowly, with quiet pauses, the way a real
  // meditation guide would.
  const lines = [];
  lines.push(m.title + '.');
  lines.push('A short practice for today.');
  if (m.scripture_ref) lines.push('From ' + m.scripture_ref + '.');
  if (m.scripture_text) lines.push('"' + m.scripture_text + '"');
  lines.push('');
  lines.push('Find a comfortable position. Let the eyes close, or soften the gaze.');
  lines.push('Take three slow breaths.');
  lines.push('');
  for (const para of (m.body || '').split('\n\n')) {
    if (!para.trim()) { lines.push(''); continue; }
    lines.push(para.trim());
    lines.push('');
  }
  if (m.reflection) {
    lines.push('For reflection.');
    lines.push(m.reflection);
    lines.push('');
  }
  if (m.prayer) {
    lines.push('A prayer.');
    lines.push(m.prayer);
    lines.push('');
  }
  lines.push('Carry one word with you into the day.');
  lines.push('The word is: ' + (m.title || 'mercy') + '.');
  lines.push('Be still. And begin again.');
  return lines.join('\n');
}

async function main() {
  const files = (await readdir(ROOT)).filter(f => f.endsWith('.json') && !f.includes('manifest'));
  const manifest = [];
  for (const f of files) {
    const m = JSON.parse(await readFile(join(ROOT, f), 'utf8'));
    const text = ttsScript(m);
    const out = join(ROOT, `audio-${m.slug}.mp3`);
    manifest.push({
      slug: m.slug,
      day_of_year: m.day_of_year,
      title: m.title,
      text,
      voice: VOICE,
      speed: SPEED,
      pitch: PITCH,
      out,
    });
  }
  await writeFile(join(ROOT, '..', 'meditations-audio-manifest.json'), JSON.stringify(manifest, null, 2));
  console.log(`✓ Wrote audio manifest for ${manifest.length} meditations → content/meditations-audio-manifest.json`);
  console.log(`  Voice: ${VOICE} (set HEAL_VOICE_ID to override)`);
  console.log(`  Total est. duration: ${Math.round(manifest.reduce((a, m) => a + (m.text.length / 16), 0))} seconds`);
  console.log('  Next: call batch_text_to_audio with this manifest, write to /content/meditations/audio-<slug>.mp3');
  console.log('  Then: pnpm content:seed && pnpm media:upload');
}

main().catch(e => { console.error('💥', e); process.exit(1); });
