#!/usr/bin/env node
/**
 * HEAL — Illustration batch
 * Reads /content/meditations/*.json, asks the image_synthesize tool via
 * a small headless call to render a watercolor, writes
 * /content/meditations/illustration-<slug>.png.
 *
 * This is the "offline" version of the step: it generates a prompt
 * from each meditation and we can feed it to the image_synthesize
 * tool from a session. We pre-write the prompt manifest here so
 * generation is one click.
 */
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', 'content', 'meditations');

const STYLE_SUFFIX = 'Watercolor painting, soft bleeding edges, muted palette of warm bone, sage green, dawn gold, soft indigo. Loose brushwork, light texture, paper grain visible. No text, no people in sharp focus, no geometric shapes. Composition evokes stillness and breath. Aspect ratio 2:1.';

function promptFor(m) {
  const themeVisuals = {
    calm:        'a still body of water at dawn, mist rising, no wind',
    gratitude:   'an open hand cradling a single, soft flame',
    'let-go':    'an open window, curtains moving slowly in a soft breeze',
    love:        'two hands almost touching, framed by soft golden light',
    focus:       'a single, lit candle in a darkened room',
    stillness:   'a quiet forest clearing at first light, no birds in motion',
    courage:     'a single tree standing firm against a wide, soft sky',
    rest:        'a child asleep in soft cloth, gentle morning light',
  };
  const visual = themeVisuals[m.theme] || 'a quiet, contemplative landscape';
  const scripture = (m.scripture_ref || '').split(':')[0].replace(/\d/g, '').trim();
  return `${visual}, in the spirit of ${scripture || 'Christian contemplative art'}. ${STYLE_SUFFIX}`;
}

async function main() {
  const files = (await readdir(ROOT)).filter(f => f.endsWith('.json'));
  const manifest = [];
  for (const f of files) {
    const m = JSON.parse(await readFile(join(ROOT, f), 'utf8'));
    const prompt = promptFor(m);
    const out = join(ROOT, `illustration-${m.slug}.png`);
    manifest.push({ slug: m.slug, day_of_year: m.day_of_year, title: m.title, theme: m.theme, prompt, out });
  }
  await writeFile(join(ROOT, '..', 'meditations-illustration-manifest.json'), JSON.stringify(manifest, null, 2));
  console.log(`✓ Wrote illustration manifest for ${manifest.length} meditations → content/meditations-illustration-manifest.json`);
  console.log('  Next: run image_synthesize for each, write to /content/meditations/illustration-<slug>.png');
  console.log('  Then: pnpm content:seed && pnpm media:upload');
}

main().catch(e => { console.error('💥', e); process.exit(1); });
