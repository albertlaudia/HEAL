// Build prompt batches for missing content (illustrations, audio, music).
// Run: node scripts/build-missing-prompt-batches.mjs
// Output: /tmp/*-batches.json files ready for the image / audio / music generators.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const moodMap = {
  calm: 'muted sage greens, soft mist, contemplative',
  gratitude: 'warm amber, golden light, simple abundance',
  'let-go': 'soft white, release, washing clean',
  love: 'soft rose and cream, gentle embrace, warm',
  focus: 'deep teal, mirror-still water, horizon',
  stillness: 'muted sage greens, soft mist, contemplative',
  courage: 'mountain rock, golden hour, standing firm',
  rest: 'evening blues, soft pillow, sanctuary',
  hope: 'sunrise gradient, soft pink and gold, rising',
  wisdom: 'muted sage greens, soft mist, contemplative',
  grace: 'soft white, release, washing clean',
  strength: 'mountain rock, golden hour, standing firm',
  joy: 'warm sunlight, bright birdsong, lifted',
};

const HEAL_PREFIX = 'Soft watercolor meditation illustration. HEAL design language: hand-painted feel, loose washes, soft edges, no text, no people, no sharp details, calming negative space.';

function buildImagePrompt(title, theme) {
  return `${HEAL_PREFIX} Theme: ${title}. Mood: ${moodMap[theme] || moodMap.stillness}.`;
}

function readSlugsFromContent(contentDir) {
  const out = {};
  for (const f of fs.readdirSync(contentDir).filter((f) => f.endsWith('.json'))) {
    const data = JSON.parse(fs.readFileSync(path.join(contentDir, f), 'utf8'));
    if (data.slug) out[data.slug] = data;
  }
  return out;
}

function getLocalFiles(dir, prefix, ext) {
  if (!fs.existsSync(dir)) return new Set();
  return new Set(
    fs
      .readdirSync(dir)
      .filter((f) => f.startsWith(prefix) && f.endsWith(ext))
      .map((f) => f.slice(prefix.length, -ext.length))
  );
}

function chunk(list, size = 10) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

function buildIllustrationBatch(slug, data, outputDir, prefix, ext) {
  return {
    slug,
    title: data.title || slug,
    theme: data.theme || 'stillness',
    kind: 'meditation',
    fileName: `${prefix}${slug}${ext}`,
    outputDir,
    prompt: buildImagePrompt(data.title || slug, data.theme || 'stillness'),
  };
}

// ─── Meditations ─────────────────────────────────────────────
{
  const contentDir = path.join(ROOT, 'content', 'meditations');
  const imgDir = path.join(ROOT, 'public', 'images', 'meditations');
  const all = readSlugsFromContent(contentDir);
  const imgs = getLocalFiles(imgDir, 'illustration-', '.png');
  const missing = Object.keys(all).filter((s) => !imgs.has(s));
  const prompts = missing
    .map((s) => buildIllustrationBatch(s, all[s], 'public/images/meditations', 'illustration-', '.png'))
    .filter((p) => p);
  const batches = chunk(prompts, 10);
  fs.writeFileSync('/tmp/missing-meditation-batches.json', JSON.stringify(batches));
  console.log(`Meditations: ${prompts.length} missing → ${batches.length} batches`);
}

// ─── Prayers ─────────────────────────────────────────────────
{
  const contentDir = path.join(ROOT, 'content', 'prayers');
  const imgDir = path.join(ROOT, 'public', 'images', 'prayers');
  const all = readSlugsFromContent(contentDir);
  const imgs = getLocalFiles(imgDir, 'prayer-', '.png');
  const missing = Object.keys(all).filter((s) => !imgs.has(s));
  // prayers don't have theme; derive from title
  const prompts = missing
    .map((s) => {
      const data = all[s];
      return {
        slug: s,
        title: data.title || s,
        theme: data.category || 'stillness',
        kind: 'prayer',
        fileName: `prayer-${s}.png`,
        outputDir: 'public/images/prayers',
        prompt: `${HEAL_PREFIX} Theme: ${data.title || s}. Mood: ${moodMap.stillness}.`,
      };
    })
    .filter((p) => p);
  const batches = chunk(prompts, 10);
  fs.writeFileSync('/tmp/missing-prayer-batches.json', JSON.stringify(batches));
  console.log(`Prayers: ${prompts.length} missing → ${batches.length} batches`);
}

// ─── Praise (illustrations + audio) ─────────────────────────
{
  const contentDir = path.join(ROOT, 'content', 'praise');
  const imgDir = path.join(ROOT, 'public', 'images', 'praise');
  fs.mkdirSync(imgDir, { recursive: true });
  const all = readSlugsFromContent(contentDir);
  const imgs = getLocalFiles(imgDir, 'praise-', '.png');
  const missing = Object.keys(all).filter((s) => !imgs.has(s));
  const prompts = missing.map((s) => {
    const data = all[s];
    return {
      slug: s,
      title: data.title || s,
      theme: data.category || 'praise',
      kind: 'praise',
      fileName: `praise-${s}.png`,
      outputDir: 'public/images/praise',
      prompt: `${HEAL_PREFIX} Theme: ${data.title || s}. Mood: warm amber, golden light, soft radiance.`,
    };
  });
  const batches = chunk(prompts, 10);
  fs.writeFileSync('/tmp/missing-praise-batches.json', JSON.stringify(batches));
  console.log(`Praise illustrations: ${prompts.length} missing → ${batches.length} batches`);
}

// ─── Essays ──────────────────────────────────────────────────
{
  const contentDir = path.join(ROOT, 'content', 'essays');
  const imgDir = path.join(ROOT, 'public', 'images', 'essays');
  fs.mkdirSync(imgDir, { recursive: true });
  const all = readSlugsFromContent(contentDir);
  const imgs = getLocalFiles(imgDir, 'essay-', '.png');
  const missing = Object.keys(all).filter((s) => !imgs.has(s));
  const prompts = missing.map((s) => {
    const data = all[s];
    return {
      slug: s,
      title: data.title || s,
      kind: 'essay',
      fileName: `essay-${s}.png`,
      outputDir: 'public/images/essays',
      prompt: `${HEAL_PREFIX} Theme: ${data.title || s}. Mood: ${moodMap.wisdom}.`,
    };
  });
  fs.writeFileSync('/tmp/missing-essay-batches.json', JSON.stringify(chunk(prompts, 5)));
  console.log(`Essay illustrations: ${prompts.length} missing → ${chunk(prompts, 5).length} batches`);
}

// ─── Voice meditations (audio) ──────────────────────────────
{
  const contentDir = path.join(ROOT, 'content', 'meditations');
  const audioDir = path.join(ROOT, 'public', 'audio', 'meditations');
  const all = readSlugsFromContent(contentDir);
  const audios = getLocalFiles(audioDir, 'audio-', '.mp3');
  const missing = Object.keys(all).filter((s) => !audios.has(s));
  const items = missing.map((s) => {
    const data = all[s];
    const tts = (data.body || '').slice(0, 2000);
    return {
      slug: s,
      title: data.title || s,
      kind: 'meditation',
      text: tts,
      outputDir: 'public/audio/meditations',
      fileName: `audio-${s}.mp3`,
      voice_id: 'English_CaptivatingStoryteller',
      speed: 0.92,
      pitch: -1,
    };
  });
  // Save flat list (TTS batches of 10)
  const batches = chunk(items, 10);
  fs.writeFileSync('/tmp/missing-audio-batches.json', JSON.stringify(batches));
  console.log(`Audio: ${items.length} missing → ${batches.length} batches`);
}

// ─── Praise music (suno-style music gen) ────────────────────
{
  const contentDir = path.join(ROOT, 'content', 'praise');
  const all = readSlugsFromContent(contentDir);
  const items = Object.keys(all).map((s) => {
    const data = all[s];
    return {
      slug: s,
      title: data.title || s,
      kind: 'praise-music',
      prompt: `A soft, devotional ${data.tempo_bpm ? data.tempo_bpm + 'bpm ' : ''}instrumental arrangement in ${data.key_signature || 'D'} major, ${data.meter || '4/4'} time, in the style of contemplative folk hymn. Piano, light acoustic guitar, soft strings, no vocals. Peaceful, sacred, suitable for meditation and worship. Inspired by "${data.title}".`,
      outputDir: 'public/audio/praise',
      fileName: `praise-${s}.mp3`,
      lyrics: data.lyrics || '',
    };
  });
  const batches = chunk(items, 5);
  fs.writeFileSync('/tmp/missing-music-batches.json', JSON.stringify(batches));
  console.log(`Praise music: ${items.length} songs → ${batches.length} batches`);
}
