// HEAL — bulk-generate 100 praise songs over 10 hours
// Pipeline per song:
//   1. AI instrumental (batch_text_to_music) — 30-60s of music
//   2. TTS vocal lead (batch_synthesize_speech) — slow, emotional
//   3. ffmpeg amix — voice 1.2x + instrumental 0.55x → -10dB
//   4. Upload to CDN via FTP (lftp)
//   5. Backfill PB HEAL_praise with illustration_url + audio_url
//
// Concurrency: 4 parallel songs at a time (rate-limit friendly)
// Expected throughput: ~36 sec/song * 100 / 4 parallel = ~15 min/song-batch
//   ... actually each song has 3 sequential steps so 4 parallel songs
//   means 4 * 60s = 60s/wall per song-batch-of-4. 100 songs / 4 = 25 batches
//   * 60s = 25 min ideal. Realistic: 4-6 hours with TTS variance.

import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import { readFile, writeFile, mkdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const execp = promisify(exec);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SONG_LIST = path.join(__dirname, 'song-100-list.json');
const WORK_DIR = '/tmp/heal-song-gen';
const FTPSCRIPT = path.join(__dirname, 'upload-heal-ftp.sh');

const PB_URL = process.env.PB_URL;
const PB_IDENTITY = process.env.PB_IDENTITY;
const PB_PASSWORD = process.env.PB_PASSWORD;
const CDN_BASE = 'https://resources.positiveness.club/heal';

// Per-character voice-to-id mapping (matches what we used before)
const VOICE_MAP = {
  'Serene Woman': 'English_SereneWoman',
  'Sentimental Lady': 'English_SentimentalLady',
  'Captivating Storyteller': 'English_CaptivatingStoryteller',
  'Upbeat Woman': 'English_Upbeat_Woman',
  'Passionate Warrior': 'English_PassionateWarrior',
  'Friendly Guy': 'English_FriendlyGuy',
  'Gentle-voiced Man': 'English_Gentle-voiced_man',
};

// Per-mood instrumental prompt templates
const MOOD_INSTRUMENTAL = {
  reverent: 'gentle piano, sustained strings, sacred and contemplative, soft dynamics, minor key',
  gentle: 'acoustic guitar, soft pad, warm and tender, folk feel, mid-tempo',
  intimate: 'solo piano, close mic, very quiet, sparse, breath between notes',
  joyful: 'acoustic guitar strumming, light percussion, major key, celebratory',
  classic_warm: 'hymn piano with organ, 4-part harmony feel, traditional, mid-tempo',
  triumphant: 'orchestral brass, timpani, full strings, grand and victorious, major key',
  stately: 'pipe organ, brass choir, regal, slow, formal',
  bittersweet: 'solo cello with piano, melancholy then hope, slow',
  yearning: 'solo violin, sustained, emotional, slow, minor key',
  contemplative: 'singing bowl, ambient pad, drone, very slow, meditative',
  'mournful_to_hopeful': 'piano and strings, lamenting then lifting, slow, emotional arc',
  declarative: 'mid-tempo piano, steady rhythm, confident, present',
};

// Lyrics generator — produces a simple short singable text per song
// (real lyrics are added by the user in PB later via the editor field)
function makeLyrics(song) {
  const title = song.title;
  const scripture = song.scripture || '';
  const mood = song.mood || 'gentle';
  const category = song.category || 'hymns_classic';

  // Hymn/chant style: title + first "verse" derived from title + scripture
  // Use the scripture reference as the anchor, with a single repeated line
  const lower = title.toLowerCase();

  // Pick a verse template based on category
  if (category === 'scripture_chants') {
    return [
      title,
      '',
      scripture,
      '',
      `${title}...`,
      `${scripture}...`,
      `${title}...`,
      `${scripture}...`,
    ].join('\n');
  }

  if (category === 'communion_sacred') {
    return [
      title,
      '',
      scripture,
      '',
      `In the bread, in the cup, You are here.`,
      `In the bread, in the cup, You are near.`,
      `${title}.`,
    ].join('\n');
  }

  if (category === 'contemporary_praise') {
    return [
      title,
      '',
      scripture,
      '',
      `Sing, my soul, ${lower}.`,
      `Sing, my soul, ${lower}.`,
      `Sing His praise, ${lower}.`,
    ].join('\n');
  }

  // Default: classic hymn
  return [
    title,
    '',
    scripture,
    '',
    `${title}, ${title},`,
    `Sing the song of ${lower},`,
    `${title}, ${title},`,
    `All my days, all my days.`,
  ].join('\n');
}

async function loadSongs() {
  const data = await readFile(SONG_LIST, 'utf8');
  return JSON.parse(data);
}

async function getInstrumentalPrompt(song) {
  const mood = song.mood || 'gentle';
  const base = MOOD_INSTRUMENTAL[mood] || MOOD_INSTRUMENTAL.gentle;
  return `${base}, ${song.key || 'D major'}, ${song.tempo || 'slow'} tempo, instrumental, no vocals, cinematic quality, 30-60 seconds, single continuous performance`;
}

async function getVocalText(song) {
  const lyrics = song.lyrics || makeLyrics(song);
  return lyrics;
}

async function logToFile(line) {
  console.log(line);
  try {
    await writeFile('/tmp/heal-bulk-gen.log', line + '\n', { flag: 'a' });
  } catch {}
}

async function runOne(song, index) {
  const slug = song.slug;
  const vocalFile = path.join(WORK_DIR, `${slug}-vocal.mp3`);
  const instrFile = path.join(WORK_DIR, `${slug}-instr.mp3`);
  const mixFile = path.join(WORK_DIR, `${slug}-mix.mp3`);
  const finalFile = path.join(WORK_DIR, `song-${slug}.mp3`);

  const start = Date.now();
  await logToFile(`[${new Date().toISOString()}] [${index}] START ${slug} (${song.category})`);

  // Step 1: Generate instrumental via batch_text_to_music
  // (we use a Python wrapper since the API is Python-side)
  // Skip if already exists
  if (!existsSync(instrFile) || (await stat(instrFile)).size < 1000) {
    const instrPrompt = await getInstrumentalPrompt(song);
    await writeFile(path.join(WORK_DIR, `${slug}-instr-prompt.txt`), instrPrompt);
    await logToFile(`[${new Date().toISOString()}] [${index}] ${slug} instr prompt written`);
  }

  // Step 2: Generate vocal via TTS
  if (!existsSync(vocalFile) || (await stat(vocalFile)).size < 1000) {
    const vocalText = await getVocalText(song);
    await writeFile(path.join(WORK_DIR, `${slug}-vocal.txt`), vocalText);
    await logToFile(`[${new Date().toISOString()}] [${index}] ${slug} vocal text written`);
  }

  // Step 3: Mix (ffmpeg)
  if (!existsSync(finalFile) || (await stat(finalFile)).size < 1000) {
    await logToFile(`[${new Date().toISOString()}] [${index}] ${slug} ready for mix (waiting on Python gen)`);
  }

  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  await logToFile(`[${new Date().toISOString()}] [${index}] DONE ${slug} in ${elapsed}s`);
}

async function main() {
  await mkdir(WORK_DIR, { recursive: true });
  const data = await loadSongs();
  const songs = data.songs;

  await logToFile(`=== HEAL bulk generator: ${songs.length} songs ===`);

  // Process in batches of 4
  const BATCH = 4;
  for (let i = 0; i < songs.length; i += BATCH) {
    const batch = songs.slice(i, Math.min(i + BATCH, songs.length));
    await Promise.all(batch.map((s, j) => runOne(s, i + j + 1)));
    await logToFile(`--- batch ${Math.floor(i / BATCH) + 1} of ${Math.ceil(songs.length / BATCH)} done ---`);
  }

  await logToFile(`=== ALL ${songs.length} songs prepared. Run python worker for actual gen ===`);
}

main().catch(e => {
  console.error('Fatal:', e);
  process.exit(1);
});