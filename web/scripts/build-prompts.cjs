// build-prompts.cjs — generates HEAL-consistent watercolor prompts
// Single design language: soft watercolor, 3:2 landscape, theme mood.
// All meditations, prayers, praise, and essays use the same template
// to ensure visual consistency across the platform.

const fs = require('fs');
const path = require('path');

const THEME_PROMPTS = {
  stillness: 'muted sage greens, soft mist, contemplative',
  gratitude: 'warm amber, golden light, simple abundance',
  'let-go': 'open sky, dissolving clouds, spaciousness',
  love: 'soft rose and cream, gentle embrace, warm',
  focus: 'still water, single point of light, minimal',
  calm: 'deep teal, mirror-still water, horizon',
  rest: 'evening blues, soft pillow, sanctuary',
  courage: 'golden dawn light, mountain path, firm',
  hope: 'sunrise gradient, soft pink and gold, rising',
  wisdom: 'aged book and warm lamp light, deep browns',
  forgiveness: 'soft white, release, washing clean',
  grief: 'gentle rain, muted blues, holding space',
  joy: 'warm sunlight, bright birdsong, lifted',
  strength: 'mountain rock, golden hour, standing firm',
  grace: 'soft golden light falling, gentle, undeserved',
};

// HEAL design language — same for every post
const STYLE = 'Soft watercolor meditation illustration. HEAL design language: hand-painted feel, loose washes, soft edges, no text, no people, no sharp details, calming negative space.';

const prayers = [];

// Find all content needing illustrations
const targets = [];

// Meditations
for (const f of fs.readdirSync('content/meditations').filter(f => f.endsWith('.json'))) {
  const d = JSON.parse(fs.readFileSync('content/meditations/' + f, 'utf8'));
  const existing = new Set(fs.readdirSync('public/images/meditations').map(f => f.replace(/^illustration-/, '').replace(/\.png$/, '')));
  if (!existing.has(d.slug)) {
    targets.push({
      kind: 'meditation',
      slug: d.slug,
      title: d.title,
      theme: d.theme || 'stillness',
      outputDir: 'public/images/meditations',
      fileName: `illustration-${d.slug}.png`,
    });
  }
}

// Prayers
for (const f of fs.readdirSync('content/prayers').filter(f => f.endsWith('.json'))) {
  const d = JSON.parse(fs.readFileSync('content/prayers/' + f, 'utf8'));
  const existing = new Set(fs.readdirSync('public/images/prayers').map(f => f.replace(/^prayer-/, '').replace(/\.png$/, '')));
  const slug = d.slug || f.replace('.json', '');
  if (!existing.has(slug)) {
    targets.push({
      kind: 'prayer',
      slug,
      title: d.title,
      theme: mapPrayerCategory(d.category),
      outputDir: 'public/images/prayers',
      fileName: `prayer-${slug}.png`,
    });
  }
}

// Praise songs
for (const f of fs.readdirSync('content/praise').filter(f => f.endsWith('.json'))) {
  const d = JSON.parse(fs.readFileSync('content/praise/' + f, 'utf8'));
  const existing = new Set(fs.readdirSync('public/images/praise').map(f => f.replace(/^praise-/, '').replace(/\.png$/, '')));
  const slug = d.slug || f.replace('.json', '');
  if (!existing.has(slug)) {
    targets.push({
      kind: 'praise',
      slug,
      title: d.title,
      theme: mapPraiseCategory(d.category),
      outputDir: 'public/images/praise',
      fileName: `praise-${slug}.png`,
    });
  }
}

// Essays
for (const f of fs.readdirSync('content/essays').filter(f => f.endsWith('.json'))) {
  const d = JSON.parse(fs.readFileSync('content/essays/' + f, 'utf8'));
  const existing = new Set(fs.readdirSync('public/images/essays').map(f => f.replace(/^essay-/, '').replace(/\.png$/, '')));
  const slug = d.slug || f.replace('.json', '');
  if (!existing.has(slug)) {
    targets.push({
      kind: 'essay',
      slug,
      title: d.title,
      theme: 'wisdom', // essays default to wisdom aesthetic
      outputDir: 'public/images/essays',
      fileName: `essay-${slug}.png`,
    });
  }
}

function mapPrayerCategory(cat) {
  const map = {
    morning: 'hope', evening: 'rest', anxiety: 'calm', gratitude: 'gratitude',
    forgiveness: 'forgiveness', strength: 'strength', rest: 'rest', other: 'stillness',
  };
  return map[cat] || 'stillness';
}

function mapPraiseCategory(cat) {
  const map = {
    adoration: 'grace', gratitude: 'gratitude', lament: 'grief', hope: 'hope',
    comfort: 'rest', celebration: 'joy', repentance: 'forgiveness', other: 'stillness',
  };
  return map[cat] || 'stillness';
}

const out = targets.map(t => {
  const aesthetic = THEME_PROMPTS[t.theme] || THEME_PROMPTS.stillness;
  const prompt = `${STYLE} Theme: ${t.title}. Mood: ${aesthetic}.`;
  return { ...t, prompt };
});

fs.writeFileSync('/tmp/all-prompts.json', JSON.stringify(out, null, 2));
console.log('Total prompts:', out.length);
console.log('By kind:', out.reduce((s, x) => { s[x.kind] = (s[x.kind] || 0) + 1; return s; }, {}));
