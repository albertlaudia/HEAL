// Backfill description, tags, emotion, mood, voice, best_for for all 12 praise songs.
// Run once after the schema migration.
const PB_URL = process.env.PB_URL;
const PB_IDENTITY = process.env.PB_IDENTITY;
const PB_PASSWORD = process.env.PB_PASSWORD;

const BACKFILL = {
  'the-lord-is-my-shepherd-chant': {
    description: 'A simple chant on Psalm 23 — for the days you need to remember you are not alone, you are led. Sing it slowly, like a prayer.',
    tags: ['psalm-23', 'comfort', 'gentle', 'reassurance', 'shepherd', 'simplicity', 'short'],
    emotion: 'companioned',
    mood: 'contemplative',
    voice: 'Serene Woman',
    best_for: ['morning', 'before_prayer', 'tired', 'anxious', 'seeking_peace', 'with_children'],
  },
  'be-still-my-soul': {
    description: 'When the news is heavy and the heart is louder than the room — this is the hymn. Be still. He faithful will remain.',
    tags: ['comfort', 'be_still', 'steadfast', 'endurance', 'patience', 'cross', 'pain', 'classical'],
    emotion: 'settled',
    mood: 'reverent',
    voice: 'Sentimental Lady',
    best_for: ['evening', 'grief', 'waiting', 'uncertain_season', 'with_spouse', 'long_illness'],
  },
  'come-thou-fount-of-every-blessing': {
    description: 'A folk hymn that names what is constantly pouring down — mercy, never ceasing. Sing it like a thank-you you forgot to say.',
    tags: ['gratitude', 'mercy', 'folk', 'americana', 'joy', 'tune_my_heart', 'classic', 'lifted'],
    emotion: 'lifted',
    mood: 'joyful',
    voice: 'Upbeat Woman',
    best_for: ['morning', 'gratitude', 'with_family', 'sunday_table', 'after_good_news', 'walking'],
  },
  'it-is-well-with-my-soul-abridged': {
    description: 'Spafford wrote this after losing his daughters at sea. Whatever you have lost — you can say it, too.',
    tags: ['comfort', 'hope', 'loss', 'sea', 'spafford', 'steadfast', 'classic', 'sorrowful'],
    emotion: 'restored',
    mood: 'bittersweet',
    voice: 'Captivating Storyteller',
    best_for: ['grief', 'after_loss', 'long_illness', 'evening', 'alone', 'hospital'],
  },
  'great-is-thy-faithfulness': {
    description: 'Morning by morning — new mercies. The song to sing when you are tired of trying to be faithful on your own strength.',
    tags: ['faithfulness', 'morning', 'mercies', 'classic', 'steadfast', 'gentle', '12_8', 'gratitude'],
    emotion: 'settled',
    mood: 'gentle_warm',
    voice: 'Captivating Storyteller',
    best_for: ['morning', 'devotional', 'tired', 'discouraged', 'with_family', 'coffee_time'],
  },
  'how-great-thou-art-abridged': {
    description: 'A wonder psalm set to a folk melody. Sing it when you are outside, or when you need to remember how big the world is and how held you are in it.',
    tags: ['wonder', 'creation', 'stars', 'thunder', 'awe', 'classic', 'hymn', 'reverent'],
    emotion: 'awestruck',
    mood: 'reverent',
    voice: 'Passionate Warrior',
    best_for: ['outside', 'mountain', 'sunset', 'worship_community', 'sunday_morning', 'with_friends'],
  },
  'what-a-friend-we-have-in-jesus': {
    description: 'All our sins and griefs to bear — a hymn that just hands the phone over. For every worry you have been carrying alone.',
    tags: ['comfort', 'jesus', 'friend', 'prayer', 'burden', 'classic', 'gentle', 'pastoral'],
    emotion: 'companioned',
    mood: 'warm',
    voice: 'Gentle-voiced Man',
    best_for: ['evening', 'lonely', 'worry', 'with_spouse', 'before_prayer', 'anywhere'],
  },
  'amazing-grace-common-meter': {
    description: 'The hymn everyone knows. Newton — a slave-trader turned pastor — wrote it. If grace could save him, it can save you. Slow it down.',
    tags: ['grace', 'salvation', 'classic', 'hymn', 'folk', 'newton', 'gentle', 'simplicity'],
    emotion: 'lifted',
    mood: 'classic_warm',
    voice: 'Serene Woman',
    best_for: ['anywhere', 'morning', 'evening', 'grief', 'new_beginning', 'sunday_morning'],
  },
  'good-good-father': {
    description: 'A modern family-table song. Short, repeatable, easy to sing with kids. For the meal that needs to slow down.',
    tags: ['family', 'father', 'modern', 'kids', 'table', 'simple', 'joy', 'repetition'],
    emotion: 'companioned',
    mood: 'family_warm',
    voice: 'Upbeat Woman',
    best_for: ['family_table', 'kids', 'morning', 'bedtime', 'before_meal', 'sunday_school'],
  },
  'tremble-abridged': {
    description: 'A modern declaration — truth over atmosphere. For when the room is heavy and you want to re-name what is real.',
    tags: ['modern', 'declaration', 'truth', 'atmosphere', 'worship', 'contemporary', 'call_to_worship'],
    emotion: 'settled',
    mood: 'declarative',
    voice: 'Passionate Warrior',
    best_for: ['worship_community', 'heavy_room', 'evening', 'prayer_meeting', 'with_young_adults'],
  },
  'a-simple-communion-hymn': {
    description: 'For the table where bread is broken. Short enough to sing without rehearsal, slow enough to think about what is happening.',
    tags: ['communion', 'bread', 'wine', 'eucharist', 'simple', 'short', 'sacrament', 'reverent'],
    emotion: 'reverent',
    mood: 'reverent',
    voice: 'Serene Woman',
    best_for: ['communion', 'church', 'thursday', 'easter', 'lent', 'with_pastor'],
  },
  'a-song-of-lament-for-when-there-are-no-words': {
    description: 'For the mornings you cannot pray. How long, O Lord — and then, in the second half, I will sing of your strength.',
    tags: ['lament', 'psalm-13', 'protest', 'grief', 'honest', 'wordless', 'mournful', 'turning'],
    emotion: 'honest',
    mood: 'mournful_to_hopeful',
    voice: 'Sentimental Lady',
    best_for: ['grief', 'anger', 'wordless_morning', 'evening', 'after_bad_news', 'protest'],
  },
};

async function main() {
  const auth = await fetch(PB_URL + '/api/collections/_superusers/auth-with-password', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity: PB_IDENTITY, password: PB_PASSWORD }),
  });
  const a = await auth.json();
  if (!a.token) {
    console.log('auth failed:', JSON.stringify(a).slice(0, 200));
    return;
  }
  const token = a.token;

  const r = await fetch(PB_URL + '/api/collections/HEAL_praise/records?perPage=20&fields=id,slug', { headers: { Authorization: token } });
  const d = await r.json();

  let ok = 0;
  let err = 0;
  for (const item of d.items || []) {
    const fill = BACKFILL[item.slug];
    if (!fill) {
      console.log('  (skip) no backfill for', item.slug);
      continue;
    }
    const r2 = await fetch(PB_URL + '/api/collections/HEAL_praise/records/' + item.id, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: token },
      body: JSON.stringify(fill),
    });
    if (r2.ok) {
      console.log('  ✓', item.slug);
      ok++;
    } else {
      console.log('  ✗', item.slug, ':', (await r2.text()).slice(0, 200));
      err++;
    }
  }
  console.log('---');
  console.log('updated:', ok, '/ failed:', err, '/ total:', d.items.length);
}

main().catch((e) => console.error('fatal:', e));
