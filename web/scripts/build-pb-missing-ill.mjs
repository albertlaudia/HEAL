// Build a list of meditations in PB that are missing illustrations
// Output: /tmp/pb-missing-ill-batches.json
import fs from 'node:fs';
import path from 'node:path';
import PocketBase from 'pocketbase';

const PB_URL = process.env.PB_URL || 'https://pocketbase.scaleupcrm.com';
const IDENTITY = process.env.PB_IDENTITY;
const PASSWORD = process.env.PASSWORD || process.env.PB_PASSWORD;

const pb = new PocketBase(PB_URL);
pb.autoCancellation(false);
try { await pb.collection('_superusers').authWithPassword(IDENTITY, PASSWORD); } catch { try { await pb.admins.authWithPassword(IDENTITY, PASSWORD); } catch { console.error('auth failed'); process.exit(1); } }

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
  grief: 'gentle rain, muted blues, holding space',
  forgiveness: 'soft white, release, washing clean',
};

const all = await pb.collection('HEAL_meditations').getFullList();
const items = [];
for (const m of all) {
  const imgPath = '/workspace/HEAL/public/images/meditations/illustration-' + m.slug + '.png';
  if (!fs.existsSync(imgPath)) {
    items.push({
      slug: m.slug,
      title: m.title,
      theme: m.theme || 'stillness',
      outputFile: 'public/images/meditations/illustration-' + m.slug + '.png',
      prompt: `Soft watercolor meditation illustration. HEAL design language: hand-painted feel, loose washes, soft edges, no text, no people, no sharp details, calming negative space. Theme: ${m.title}. Mood: ${moodMap[m.theme] || moodMap.stillness}.`,
    });
  }
}
const batches = [];
for (let i = 0; i < items.length; i += 10) batches.push(items.slice(i, i + 10));
fs.writeFileSync('/tmp/pb-missing-ill-batches.json', JSON.stringify(batches));
console.log(`PB missing: ${items.length} → ${batches.length} batches of 10`);
