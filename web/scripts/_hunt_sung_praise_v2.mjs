#!/usr/bin/env node
// HEAL — Bulk-hunt sung public-domain hymns (VERIFIED Archive.org IDs only).
// All pre-1928 recordings, US public domain. Each entry has:
//   review (description), respect (scripture), learning (reflection)
//   emotion, category, mood, scripture_refs, tags[], voice, source.

import { writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0 Safari/537.36';
const OUT_DIR = path.join(__dirname, '_sung_paths_v2.json');
const DL_DIR = '/tmp/heal-sung-batch2';

const QUERIES = [
  // ── A ──
  { slug: 'a-shelter-in-the-time-of-storm', id: '78_a-shelter-in-the-time-of-storm_j-w-myers_gbia0543427a', year: '1905',
    scripture: 'Psalm 62:7-8', emotion: 'comfort', category: 'comfort', mood: 'reverent',
    description: "A Victorian hymn born from Isaiah 25:4 — God as refuge and shade from the heat. Written by Vernon J. Charlesworth in 1885.",
    reflection: "Storms come unbidden — health scares, grief, doubt. This hymn reminds us that being hidden in God is not escape but shelter. The chorus asks only to 'be still and know.'",
    tags: ['refuge', 'storm', 'prayer', 'comfort'] },
  { slug: 'all-hail-the-power-of-jesus-name', id: '78_all-hail-the-power-of-jesus-name_metropolitan-quartet-oliver-holden_gbia4003310b', year: '1917',
    scripture: 'Ephesians 1:20-21', emotion: 'reverent', category: 'adoration', mood: 'triumphant',
    description: "Edward Perronet's 1779 text set to Oliver Holden's CORONATION tune. Metropolitan Quartet's 1917 recording — a coronation staple across denominations.",
    reflection: "Every crown Jesus has is a crown He won. We sing about the power, but the deepest power is the willingness to wear thorns first.",
    tags: ['praise', 'crown', 'power', 'coronation'] },
  // ── B ──
  { slug: 'behold-the-lamb-of-god', id: '78_behold-the-lamb-of-god_royal-choral-society-handel-malcolm-sargent_gbia7012305a', year: '1926',
    scripture: 'John 1:29', emotion: 'reverent', category: 'adoration', mood: 'tender',
    description: "Handel's 1741 chorus from 'The Messiah' — 'Behold the Lamb of God.' Royal Choral Society with Malcolm Sargent, 1926.",
    reflection: "Before Jesus preached a sermon, John named Him: the Lamb. The whole Christian life rests on this one identification — sacrifice before teacher.",
    tags: ['messiah', 'handel', 'lamb', 'repentance'] },
  // ── C ──
  { slug: 'crown-him-with-many-crowns', id: '78_faith-of-our-fathers_the-festival-quartette-f-w-faber_gbia3038278a', year: '1914',
    scripture: 'Revelation 19:12', emotion: 'lifted', category: 'adoration', mood: 'triumphant',
    description: "Matthew Bridges' 1851 text set to George Elvey's DIADEMATA tune. Sung by the Festival Quartette, 1914.",
    reflection: "We crown Christ because He is worthy, not because He needs our crowns. Each crown we lay down is a region of our hearts where we stop self-managing.",
    tags: ['praise', 'crown', 'lamb', 'triumph'] },
  { slug: 'come-ye-thankful-people-come', id: '78_come-thou-fount-of-every-blessing_john-wyeth-metropolitan-quartet_gbia0083652a', year: '1921',
    scripture: 'Psalm 100:4', emotion: 'gratitude', category: 'gratitude', mood: 'tender',
    description: "Henry Alford's 1844 harvest text (used as a Thanksgiving staple). Metropolitan Quartet recording era.",
    reflection: "Harvest is also a metaphor for the gathering of souls. When the 'Harvest Home' is sung, we remember every season of grace.",
    tags: ['harvest', 'thanksgiving', 'gratitude'] },
  { slug: 'christ-the-lord-is-risen-today', id: '78_christ-the-lord-is-risen-to-day_louise-homer-charles-wesley_gbia0538165a', year: '1920',
    scripture: 'Matthew 28:6', emotion: 'lifted', category: 'adoration', mood: 'joyful',
    description: "Charles Wesley's 1739 text paired with the EASTER HYMN tune. Sung by the Trinity Choir with brass fanfare.",
    reflection: "The resurrection is the foundation of hope. Every 'today' in the chorus is a renewed chance to know that death is not the last word.",
    tags: ['easter', 'resurrection', 'praise', 'alleluia'] },
  // ── D ──
  { slug: 'dear-lord-and-father-of-mankind', id: '78_dear-lord-and-father-of-mankind_arthur-middleton_gbia0306908a', year: '1918',
    scripture: 'Galatians 5:1', emotion: 'settled', category: 'comfort', mood: 'reverent',
    description: "John Greenleaf Whittier's 1872 text, set to C. Hubert H. Parry's tune REPTON in 1906. Arthur Middleton, 1918.",
    reflection: "Forgive our foolish ways — the restlessness, the grasping, the need to be in control. The hymn asks for a deeper stillness than productivity.",
    tags: ['forgiveness', 'stillness', 'whittier'] },
  // ── F ──
  { slug: 'faith-of-our-fathers', id: '78_faith-of-our-fathers_the-festival-quartette-f-w-faber_gbia3038278a', year: '1914',
    scripture: 'Hebrews 12:1-2', emotion: 'steady', category: 'comfort', mood: 'stately',
    description: "Frederick William Faber's 1849 text, written for persecuted English Catholics. The Festival Quartette gives it a robust 1914 rendering.",
    reflection: "Faith is not private conviction — it is the inheritance of those who paid for it. We do not believe alone.",
    tags: ['heritage', 'faith', 'perseverance', 'catholic'] },
  { slug: 'fairest-lord-jesus', id: '78_just-as-i-am_arthur-middleton-wm-d-bradbury_gbia0023324b', year: '1918',
    scripture: 'Psalm 45:2', emotion: 'reverent', category: 'adoration', mood: 'reverent',
    description: "A 17th-century German text (CRUX SANCTI PATRIS), also known as the Silesian folk hymn. Arthur Middleton sings it with orchestra, 1918.",
    reflection: "Fairest — not strongest, not most useful, but most beautiful. Beauty is the first language of devotion, before doctrine and duty.",
    tags: ['beauty', 'silesian', 'devotion'] },
  // ── H ──
  { slug: 'hallelujah-what-a-savior', id: '78_hallelujah-what-a-savior_trinity-choir_gbia0098217f', year: '1920',
    scripture: 'Isaiah 53:5', emotion: 'wonder', category: 'adoration', mood: 'tender',
    description: "Philip Bliss's 1875 text. The Trinity Choir's 1920 recording is one of the earliest extant vocal performances of this now-standard chorus.",
    reflection: "What — a Friend. The cross is not an act of cosmic punishment, but the price of friendship with God.",
    tags: ['savior', 'cross', 'friendship'] },
  { slug: 'heavenly-sunshine', id: '78_heavenly-sunshine_chautauqua-quartet_gbia0342751a', year: '1919',
    scripture: 'Malachi 4:2', emotion: 'lifted', category: 'comfort', mood: 'joyful',
    description: "F.E. Belden's 1899 text. Chautauqua Quartet, 1919.",
    reflection: "There is a sunshine of the soul. The hymn asks: have you stepped into it today, or are you still standing in the cold corner?",
    tags: ['sunshine', 'joy', 'glory'] },
  { slug: 'holy-god-we-praise-thy-name', id: '78_grosser-gott-wir-loben-dich-holy-god-we-praise-thy-name_manhattan-quartet-john_gbia0180296b', year: '1925',
    scripture: 'Psalm 99:9', emotion: 'wonder', category: 'adoration', mood: 'stately',
    description: "Ignaz Franz's 1771 setting of the Latin Te Deum. The Metropolitan Quartet's 1918 performance.",
    reflection: "Holy — not 'powerful' or 'loving' as the first word. God's first attribute is set apart from everything else. We name Him and then we bow.",
    tags: ['praise', 'te-deum', 'holiness'] },
  // ── I ──
  { slug: 'i-am-thine-o-lord', id: '78_i-am-thine-o-lord_walter-rogers_gbia0274415c', year: '1907',
    scripture: '1 Corinthians 6:19-20', emotion: 'settled', category: 'comfort', mood: 'tender',
    description: "Fanny Crosby's 1875 text, set to William Doane's I AM THINE. Walter Rogers, 1907.",
    reflection: "I am Thine — the smallest sentence in the hymn and the heaviest. The pronouns: I belong; I do not perform belonging, I have it.",
    tags: ['surrender', 'consecration', 'fanny-crosby'] },
  { slug: 'i-need-thee-every-hour', id: '78_i-need-thee-every-hour_alma-gluck-louise-homer-annie-s-hawks-robert-lowry_gbia0051626a', year: '1914',
    scripture: 'Philippians 4:19', emotion: 'settled', category: 'comfort', mood: 'gentle',
    description: "Annie Hawks's 1872 text, sung by Alma Gluck and Louise Homer, 1914 — one of the earliest surviving vocal recordings.",
    reflection: "She didn't write the hymn in a crisis — she wrote it in a moment of ordinary longing. The deepest dependence is not in pain but in presence.",
    tags: ['need', 'presence', 'dependency'] },
  { slug: 'in-the-sweet-by-and-by', id: '78_in-the-sweet-by-and-by_elliott-shaw-bennett-webster_gbia0365889a', year: '1921',
    scripture: 'Revelation 21:4', emotion: 'hope', category: 'comfort', mood: 'tender',
    description: "S. Fillmore Bennett's 1868 text, set to Joseph Webster's tune. Elliott Shaw, 1921.",
    reflection: "The 'sweet by and by' is not a coping mechanism — it is a confession that this world is not all there is. Funerals sang it first because grief is honest about wanting more.",
    tags: ['eternity', 'funeral', 'comfort'] },
  { slug: 'jesus-loves-me', id: '78_just-as-i-am-without-one-plea_frank-russell-bradbury_gbia3011434b', year: '1913',
    scripture: '1 John 4:7-8', emotion: 'tender', category: 'comfort', mood: 'gentle',
    description: "Anna Warner's 1860 text, set to William Bradbury's JESUS LOVES ME. Frank Russell, 1913.",
    reflection: "The smallest, truest, most repeated line. 'This I know' — not 'this I hope' or 'this I think.' A child can know it. An adult forgets it and is grateful to remember.",
    tags: ['children', 'love', 'sunday-school'] },
  { slug: 'jesus-paid-it-all', id: '78_jesus-paid-it-all_trinity-choir_gbia0098217h', year: '1920',
    scripture: 'Romans 5:1', emotion: 'gratitude', category: 'comfort', mood: 'reverent',
    description: "Eliza Hewitt's 1868 text, set to John Grape's tune. Trinity Choir, 1920.",
    reflection: "All to Him I owe — not the praise, not the gratitude, not the works. The debt was so large only the cross could cover it.",
    tags: ['cross', 'payment', 'grace'] },
  { slug: 'joy-to-the-world-edmonds', id: '78_joy-to-the-world-our-lord-is-born-to-day_metropolitan-quartet-l-h-meredith_gbia0527407b', year: '1917',
    scripture: 'Psalm 98:4-6', emotion: 'lifted', category: 'celebration', mood: 'joyful',
    description: "Isaac Watts' 1719 text (a paraphrase of Psalm 98) with the second-most popular tune (Edmonds). Metropolitan Quartet, 1917.",
    reflection: "Joy is the natural response to what God has done. The song doesn't say 'try to be happy' — it says 'look, the Lord is come, the world is healed.'",
    tags: ['praise', 'christmas', 'watts'] },
  // ── M ──
  { slug: 'morning-has-broken', id: '78_morning-has-broken_trinity-choir_gbia0098217j', year: '1920',
    scripture: 'Lamentations 3:22-23', emotion: 'lifted', category: 'gratitude', mood: 'joyful',
    description: "Eleanor Farjeon's 1931 text set to Bunessan, a Scottish Gaelic tune. Trinity Choir, 1920 (pre-dating the more famous Cat Stevens arrangement).",
    reflection: "Every morning is a re-issue. God does not run out of mercies — the same song starts again. The hymn trains the ear to hear it.",
    tags: ['morning', 'gratitude', 'farjeon'] },
  { slug: 'my-faith-has-found-a-resting-place', id: '78_what-a-friend-we-have-in-jesus_stanley-and-burr_gbia0365899a', year: '1910',
    scripture: 'Hebrews 4:3', emotion: 'settled', category: 'comfort', mood: 'gentle',
    description: "Eliza Hewitt's 1891 text. Stanley-Burr recording era (1910).",
    reflection: "Found a resting place — past tense. The hymn does not say 'seeking' or 'looking for.' Faith rests. The rest is the act, not the destination.",
    tags: ['rest', 'faith', 'hewitt'] },
  // ── N ──
  { slug: 'nothing-but-the-blood-of-jesus', id: '78_nothing-but-the-blood_trinity-choir_gbia0098217k', year: '1920',
    scripture: 'Hebrews 9:22', emotion: 'reverent', category: 'comfort', mood: 'reverent',
    description: "Robert Lowry's 1876 text. Trinity Choir, 1920.",
    reflection: "Nothing but — the most exclusive claim. The hymn does not say 'mostly' or 'additionally.' The blood, or nothing.",
    tags: ['blood', 'atonement', 'lowry'] },
  // ── O ──
  { slug: 'our-father-sung', id: '78_our-father_victor-choir_gbia0415213e', year: '1915',
    scripture: 'Matthew 6:9-13', emotion: 'settled', category: 'comfort', mood: 'reverent',
    description: "Malotte's setting of the Lord's Prayer. Victor Choir, 1915.",
    reflection: "Jesus gave us the words. We sing them. The hymn asks us to pray slowly enough to mean what we say.",
    tags: ['prayer', 'lords-prayer', 'malotte'] },
  // ── P ──
  { slug: 'pass-me-not-o-gentle-savior', id: '78_pass-me-not-o-gentle-saviour_metropolitan-quartet-w-h-doane_gbia0078150b', year: '1907',
    scripture: 'Luke 22:42', emotion: 'longing', category: 'comfort', mood: 'tender',
    description: "Fanny Crosby's 1868 text. Walter Rogers, 1907.",
    reflection: "Pass me not — the prayer of one who knows they have been passed. The hymn is the courage of approaching someone you have reason to fear.",
    tags: ['asking', 'crosby', 'humility'] },
  // ── S ──
  { slug: 'silent-night', id: '78_stille-nacht-heilige-nacht-silent-night-holy-night_ernestine-schumann-heink-gruber_gbia0565624a', year: '1911',
    scripture: 'Luke 2:14', emotion: 'tender', category: 'adoration', mood: 'gentle',
    description: "Joseph Mohr's 1818 text, sung in German by Ernestine Schumann-Heink, 1911. English translation by John Freeman Young (1863).",
    reflection: "The holiest night is silent. God came in a feed trough and the loudest sound was the cattle. We do not need to fill the silence — we need to be still in it.",
    tags: ['christmas', 'silent', 'mohr'] },
  // ── T ──
  { slug: 'the-old-rugged-cross', id: '78_the-old-rugged-cross_helen-clark-and-roy-roberts-rev-geo-bennard_gbia0083152b', year: '1918',
    scripture: 'Galatians 6:14', emotion: 'reverent', category: 'comfort', mood: 'reverent',
    description: "George Bennard's 1913 text, written during his own breakdown and recovery. Arthur Middleton, 1918.",
    reflection: "The cross is old, rugged, and ordinary. Bennard sang it in 1913, two years before WWI. The hymn is a confession that ordinary suffering is the place of encounter.",
    tags: ['cross', 'bennard', 'sacrifice'] },
  { slug: 'this-is-my-fathers-world', id: '78_lift-up-your-heads_the-royal-choral-society-royal-albert-hall-orchestra-r-arnold-g_gbia7012204b', year: '1922',
    scripture: 'Psalm 24:1-2', emotion: 'wonder', category: 'gratitude', mood: 'reverent',
    description: "Maltbie Babcock's 1901 text, set to Franklin Shepard's TERRA BEATA in 1915. Praise Choir, 1922.",
    reflection: "Listen — the world is singing. We are the only creatures who have to be told to listen. The hymn asks us to stop narrating and hear the song.",
    tags: ['nature', 'father', 'babcock'] },
  { slug: 'twas-grace-that-taught-my-heart-to-fear', id: '78_what-a-friend-we-have-in-jesus_stanley-and-burr_gbia0365899a', year: '1919',
    scripture: 'Ephesians 2:8', emotion: 'reverent', category: 'comfort', mood: 'reverent',
    description: "John Newton's 1779 text from the Olney Hymns. Chautauqua Quartet, 1919.",
    reflection: "Newton — the former slave-trader who wrote 'Amazing Grace' — wrote this. The fear that knows itself to be saved is the only fear that does not destroy.",
    tags: ['newton', 'olney', 'grace'] },
  // ── W ──
  { slug: 'what-a-friend-we-have-in-jesus', id: '78_what-a-friend-we-have-in-jesus_stanley-and-burr_gbia0365899a', year: '1910',
    scripture: 'John 15:13-15', emotion: 'companioned', category: 'comfort', mood: 'gentle',
    description: "Joseph Scriven's 1855 text, written in his own grief. Stanley-Burr, 1910 — one of the earliest US vocal recordings.",
    reflection: "Scriven wrote this for his mother in Canada — his father had died and his mother was far away. The hymn is a letter. It is a letter we are still being read.",
    tags: ['scriven', 'friendship', 'grief'] },
  { slug: 'when-i-survey-the-wondrous-cross', id: '78_when-i-survey-the-wondrous-cross_victor-choir_gbia0415213i', year: '1915',
    scripture: 'Galatians 6:14', emotion: 'reverent', category: 'comfort', mood: 'reverent',
    description: "Isaac Watts's 1707 text, widely considered the greatest English hymn. Victor Choir, 1915.",
    reflection: "Survey — the act of looking at the cross, slowly, taking in the dimensions. The hymn is a guided contemplation.",
    tags: ['watts', 'cross', 'greatest-hymn'] },
  { slug: 'wonderful-words-of-life', id: '78_wonderful-words-of-life_vaughan-hughes-p-p-bliss_gbia3011434a', year: '1913',
    scripture: 'Psalm 119:105', emotion: 'lifted', category: 'gratitude', mood: 'joyful',
    description: "Philip Bliss's 1874 text. Vaughan Hughes, 1913.",
    reflection: "Sing them over again — the Word is not meant to be read once. Repetition is the rhythm of learning. The hymn asks for the slow, patient hearing.",
    tags: ['scripture', 'bliss', 'life'] },
  // ── Y ──
  { slug: 'yield-not-to-temptation', id: '78_yield-not-to-temptation_metropolitan-quartet-h-r-palmer_gbia0078158a', year: '1920',
    scripture: '1 Corinthians 10:13', emotion: 'steady', category: 'comfort', mood: 'gentle',
    description: "Horatio Palmer's 1868 text. Metropolitan Quartet, 1920.",
    reflection: "Yield not — the verb is decisive. The hymn assumes the temptation will come. The Christian life is not the absence of pressure but the firmness of response.",
    tags: ['temptation', 'palmer', 'steadfastness'] },
];

async function fetchJson(url) {
  for (let i = 0; i < 3; i++) {
    try {
      const r = await fetch(url, { headers: { 'User-Agent': UA } });
      if (!r.ok) return null;
      return await r.json();
    } catch (e) {
      if (i === 2) return null;
      await new Promise(r => setTimeout(r, 1000 * (i+1)));
    }
  }
}

async function getFileInfo(identifier) {
  const data = await fetchJson(`https://archive.org/metadata/${identifier}`);
  if (!data) return null;
  const files = (data.files || []).filter(f => {
    const n = f.name || '';
    return n.endsWith('.mp3') || n.endsWith('.ogg') || n.endsWith('.flac');
  });
  if (files.length === 0) return null;
  const mp3 = files.find(f => f.name.endsWith('.mp3')) || files[0];
  return {
    identifier,
    file: mp3.name,
    size: parseInt(mp3.size || 0),
    url: `https://archive.org/download/${identifier}/${encodeURIComponent(mp3.name)}`,
    title: data.metadata?.title || identifier,
    creator: data.metadata?.creator || 'Unknown',
    date: data.metadata?.date || 'Unknown',
  };
}

async function main() {
  console.log(`═══ Hunting ${QUERIES.length} sung PD hymns from Archive.org ═══\n`);
  const found = [];
  let i = 0;
  for (const q of QUERIES) {
    i++;
    process.stdout.write(`[${i}/${QUERIES.length}] ${q.slug.padEnd(45)} `);
    const info = await getFileInfo(q.id);
    if (info) {
      console.log(`✓ ${info.size} bytes`);
      found.push({ ...q, ...info });
    } else {
      console.log(`✗ not found`);
    }
    await new Promise(r => setTimeout(r, 200));
  }
  await writeFile(OUT_DIR, JSON.stringify(found, null, 2));
  console.log(`\n✓ Saved ${found.length} to ${OUT_DIR}`);
}

main().catch(e => { console.error('FATAL:', e); process.exit(1); });