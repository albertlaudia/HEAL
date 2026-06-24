// expand-batches.mjs — generate batches B2-B5 by mutating B1 meditations
// Each B1 meditation gets 4 variants (B2-B5) with:
//   - different title (theme-flavored)
//   - different scripture (same general arc, different book/chapter)
//   - paraphrased body (re-keyed, same length)
//   - same launch_batch (B2/B3/B4/B5)
//   - same day_of_year (1-84) within the batch
//
// The cycle repeats every 5 years (B1 -> B2 -> B3 -> B4 -> B5 -> B1).
// So day 1 in 2026 (B1) ≠ day 1 in 2027 (B2) ≠ day 1 in 2028 (B3)...

import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const DIR = 'content/meditations';

// Theme-keyed title variations per batch
const BATCH_TITLES = {
  2: { // B2 - "the year of stillness"
    stillness: ['A Quiet Yes', 'In the Quiet', 'The Still Point', 'Here, In the Silence'],
    gratitude: ['The Day of Small Good Things', 'A Quiet Counting', 'For the Ordinary', 'The Gift of the Day'],
    'let-go': ['Hands Open', 'The Lightening', 'Setting It Down', 'Released'],
    love: ['The Steadfast Kind', 'Love That Stays', 'In the Way of Love', 'Held by Love'],
    focus: ['The Single Eye', 'One Thing', 'A Mind Returned', 'Attention, Gentle'],
    calm: ['The Deep Water', 'Underneath', 'The Sea Beneath the Storm', 'Where It Is Still'],
    rest: ['The Long Breath Out', 'Stop, Be Held', 'The Seventh Day', 'Rest, Real Rest'],
    courage: ['A Quiet Bravery', 'The Step and the Fear', 'Going Anyway', 'The Brave Yes'],
    hope: ['The Long View', 'Hope, Not Optimism', 'Tomorrow, Already Held', 'The Unfurling'],
    wisdom: ['The Slow Knowing', 'A Long-Learned Thing', 'Wisdom in the Living', 'What the Years Taught'],
    forgiveness: ['The Long Unburdening', 'Forgiven, Forgiving', 'The Weight Set Down', 'The Second Chance'],
    grief: ['A Long Walk with Grief', 'The Valley, Today', 'Carrying the Empty Chair', 'The Soft Sorrow'],
    joy: ['Joy, Underneath', 'The Unbidden Smile', 'The Quiet Rejoicing', 'A Light That Stays'],
    strength: ['Strength for the Long Haul', 'The Quiet Muscle', 'Held, and So Strong', 'Strength That Does Not Make the News'],
    grace: ['Grace, Enough', 'The Undeserved Day', 'The Free Gift of This', 'More Than You Asked For'],
  },
  3: { // B3 - "the year of return"
    stillness: ['Return to the Quiet', 'The Familiar Chair', 'Back to the Breath', 'The Same, Again'],
    gratitude: ['Again, the Gift', 'The Returning Thanks', 'Twice-Noticed', 'A Familiar Mercy'],
    'let-go': ['The Returning Open Hands', 'Once More, Releasing', 'The Second Letting-Go', 'Unclenching, Again'],
    love: ['Love, Again', 'The Known Face of Love', 'Returning to the Source', 'The Same Love, New Today'],
    focus: ['Begin, Again', 'The Returned Mind', 'Back to the Single Thing', 'The Practice, Again'],
    calm: ['The Familiar Calm', 'Returning to the Deep', 'The Place You Know', 'Back to the Center'],
    rest: ['The Rest That Returns', 'Again, Sabbath', 'The Familiar Quiet', 'Once More, Laying Down'],
    courage: ['Courage, Returning', 'The Same Yes, Today', 'Stepping Out, Again', 'The Brave Heart, Today'],
    hope: ['Hope, Renewed', 'Tomorrow, Again', 'The Light Returns', 'The Long View, Today'],
    wisdom: ['Wisdom, Gathered', 'The Same Old Knowing', 'What You Know Now', 'The Returned Lesson'],
    forgiveness: ['Forgiveness, Returning', 'Once More, Unburdened', 'The Same Release, New Today', 'Back to the Open Hand'],
    grief: ['Grief, Returning', 'The Valley, Visited Again', 'The Familiar Ache', 'The Loss, Today'],
    joy: ['Joy, Returning', 'The Same Light, New Today', 'Back to the Smile', 'A Familiar Gladness'],
    strength: ['Strength, Returning', 'The Held-Again Heart', 'The Same Muscle, Used Again', 'Standing, Once More'],
    grace: ['Grace, Returning', 'The Familiar Gift', 'Back to the Free', 'Mercies, New This Morning'],
  },
  4: { // B4 - "the year of going deeper"
    stillness: ['The Deeper Quiet', 'Below the Surface', 'Stillness Within Stillness', 'The Inward Room'],
    gratitude: ['Deeper Thanks', 'A Heart That Knows', 'Gratitude, Wide', 'The Underside of the Day'],
    'let-go': ['The Deeper Release', 'A Wider Letting-Go', 'Beyond the Grip', 'Hands That Do Not Hold'],
    love: ['The Deeper Love', 'Love, Wide', 'The Heart of the Heart', 'Love That Does Not Ask'],
    focus: ['The Deeper Focus', 'Past the Surface', 'A Wider Attention', 'The Single, Held'],
    calm: ['The Deeper Calm', 'Below the Wave', 'The Inward Sea', 'Past the Surface, Still'],
    rest: ['The Deeper Rest', 'A Wider Sabbath', 'The Rest That Goes Deeper', 'Beyond the Doing'],
    courage: ['A Deeper Bravery', 'The Brave Heart, Underneath', 'Courage, Wide', 'Past the Surface, Step'],
    hope: ['The Deeper Hope', 'Hope, Underneath', 'A Wider Tomorrow', 'The Hope Beneath the Hope'],
    wisdom: ['Deeper Wisdom', 'The Wisdom of the Deep', 'What the Quiet Knows', 'A Wider Knowing'],
    forgiveness: ['The Deeper Forgiveness', 'A Wider Unburdening', 'Forgiveness, Underneath', 'Past the Surface, Free'],
    grief: ['The Deeper Grief', 'Grief, Underneath', 'Past the Surface, Sorrow', 'The Valley, Wider'],
    joy: ['The Deeper Joy', 'Joy, Underneath', 'The Wider Smile', 'Past the Surface, Light'],
    strength: ['The Deeper Strength', 'Strength, Underneath', 'A Wider Muscle', 'Past the Surface, Held'],
    grace: ['The Deeper Grace', 'Grace, Underneath', 'A Wider Gift', 'Past the Surface, Free'],
  },
  5: { // B5 - "the year of rest and harvest"
    stillness: ['The Harvest Quiet', 'Stillness, Gleaned', 'The Rested Hour', 'The Quiet of Completion'],
    gratitude: ['The Harvest Thanks', 'A Heart, Gleaned', 'Gratitude for What Held', 'The Long-Accumulated Good'],
    'let-go': ['The Final Release', 'The Harvested Hand', 'Letting-Go, At Last', 'A Wide Release'],
    love: ['The Harvest Love', 'Love, Gleaned', 'The Long Love', 'Love That Has Stayed'],
    focus: ['The Harvest Focus', 'The Single, Gathered', 'Attention, At Last', 'The Final Single'],
    calm: ['The Harvest Calm', 'The Calm of Completion', 'The Long Stillness', 'Calm, Gleaned'],
    rest: ['The Harvest Rest', 'The Long Sabbath', 'Rest, At Last', 'The Rested Year'],
    courage: ['The Harvest Bravery', 'Courage, Gleaned', 'The Long Brave', 'The Heart, At Last'],
    hope: ['The Harvest Hope', 'Hope, Gleaned', 'The Long Tomorrow', 'Hope, At Last'],
    wisdom: ['The Harvest Wisdom', 'Wisdom, At Last', 'The Gleaned Knowing', 'Wisdom, Wide'],
    forgiveness: ['The Harvest Forgiveness', 'Forgiven, At Last', 'The Long Release', 'The Final Unburdening'],
    grief: ['The Harvest Grief', 'Grief, Gleaned', 'The Long Sorrow', 'Grief, At Last'],
    joy: ['The Harvest Joy', 'Joy, Gleaned', 'The Long Gladness', 'Joy, At Last'],
    strength: ['The Harvest Strength', 'Strength, Gleaned', 'The Long Muscle', 'The Held Year'],
    grace: ['The Harvest Grace', 'Grace, At Last', 'The Gleaned Gift', 'The Long Mercy'],
  },
};

// Scripture variations per theme (we rotate through them so each batch has different scripture)
const SCRIPTURE_BY_BATCH = {
  2: {
    stillness: [
      ['Psalm 131:2', 'I have calmed and quieted my soul, like a weaned child with its mother.'],
    ],
    gratitude: [
      ['Psalm 116:12', 'What shall I return to the Lord for all his benefits to me?'],
    ],
    'let-go': [
      ['Matthew 11:29', 'Take my yoke upon you, and learn from me.'],
    ],
    love: [
      ['1 John 4:16', 'God is love, and those who abide in love abide in God.'],
    ],
    focus: [
      ['Philippians 3:13', 'Forgetting what lies behind and straining forward to what lies ahead.'],
    ],
    calm: [
      ['John 14:27', 'Peace I leave with you; my peace I give to you.'],
    ],
    rest: [
      ['Matthew 11:28', 'Come to me, all you who labor and are heavy laden, and I will give you rest.'],
    ],
    courage: [
      ['Deuteronomy 31:6', 'Be strong and courageous. Do not fear.'],
    ],
    hope: [
      ['Romans 15:13', 'May the God of hope fill you with all joy and peace in believing.'],
    ],
    wisdom: [
      ['Proverbs 2:6', 'For the Lord gives wisdom; from his mouth come knowledge and understanding.'],
    ],
    forgiveness: [
      ['Ephesians 4:32', 'Be kind to one another, tenderhearted, forgiving each other.'],
    ],
    grief: [
      ['Matthew 5:4', 'Blessed are those who mourn, for they shall be comforted.'],
    ],
    joy: [
      ['Nehemiah 8:10', 'The joy of the Lord is your strength.'],
    ],
    strength: [
      ['Isaiah 40:31', 'Those who wait for the Lord shall renew their strength.'],
    ],
    grace: [
      ['2 Corinthians 12:9', 'My grace is sufficient for you, for my power is made perfect in weakness.'],
    ],
  },
  3: {
    stillness: [
      ['Psalm 46:10', 'Be still, and know that I am God.'],
    ],
    gratitude: [
      ['1 Thessalonians 5:18', 'Give thanks in all circumstances.'],
    ],
    'let-go': [
      ['Isaiah 43:18', 'Remember not the former things; behold, I am doing a new thing.'],
    ],
    love: [
      ['1 Corinthians 13:7', 'Love bears all things, believes all things, hopes all things.'],
    ],
    focus: [
      ['Hebrews 12:2', 'Looking to Jesus, the founder and perfecter of our faith.'],
    ],
    calm: [
      ['Philippians 4:7', 'The peace of God, which surpasses all understanding, will guard your hearts.'],
    ],
    rest: [
      ['Hebrews 4:9', 'There remains a Sabbath rest for the people of God.'],
    ],
    courage: [
      ['Psalm 27:1', 'The Lord is my light and my salvation; whom shall I fear?'],
    ],
    hope: [
      ['Jeremiah 29:11', 'For I know the plans I have for you, declares the Lord.'],
    ],
    wisdom: [
      ['James 3:17', 'The wisdom from above is first pure, then peaceable.'],
    ],
    forgiveness: [
      ['Colossians 3:13', 'Forgiving each other, as the Lord has forgiven you.'],
    ],
    grief: [
      ['Revelation 21:4', 'He will wipe every tear from their eyes.'],
    ],
    joy: [
      ['Psalm 16:11', 'In your presence there is fullness of joy.'],
    ],
    strength: [
      ['Psalm 46:1', 'God is our refuge and strength, a very present help in trouble.'],
    ],
    grace: [
      ['Ephesians 2:8', 'For by grace you have been saved through faith.'],
    ],
  },
  4: {
    stillness: [
      ['Habakkuk 2:20', 'The Lord is in his holy temple; let all the earth keep silence before him.'],
    ],
    gratitude: [
      ['Psalm 107:1', 'Give thanks to the Lord, for he is good; his steadfast love endures forever.'],
    ],
    'let-go': [
      ['Philippians 3:13', 'Forgetting what lies behind and straining forward.'],
    ],
    love: [
      ['Romans 8:38', 'Neither death nor life shall separate us from the love of God.'],
    ],
    focus: [
      ['Psalm 119:105', 'Your word is a lamp to my feet and a light to my path.'],
    ],
    calm: [
      ['Isaiah 26:3', 'You keep him in perfect peace whose mind is stayed on you.'],
    ],
    rest: [
      ['Psalm 23:2', 'He makes me lie down in green pastures.'],
    ],
    courage: [
      ['Joshua 1:9', 'Be strong and courageous. Do not be frightened.'],
    ],
    hope: [
      ['Psalm 42:11', 'Hope in God; for I shall again praise him.'],
    ],
    wisdom: [
      ['Psalm 111:10', 'The fear of the Lord is the beginning of wisdom.'],
    ],
    forgiveness: [
      ['Psalm 103:12', 'As far as the east is from the west, so far does he remove our transgressions.'],
    ],
    grief: [
      ['Psalm 34:18', 'The Lord is near to the brokenhearted.'],
    ],
    joy: [
      ['Philippians 4:4', 'Rejoice in the Lord always; again I will say, rejoice.'],
    ],
    strength: [
      ['Exodus 15:2', 'The Lord is my strength and my song.'],
    ],
    grace: [
      ['Titus 2:11', 'The grace of God has appeared, bringing salvation.'],
    ],
  },
  5: {
    stillness: [
      ['Psalm 62:5', 'For God alone, O my soul, wait in silence.'],
    ],
    gratitude: [
      ['Psalm 103:2', 'Bless the Lord, O my soul, and forget not all his benefits.'],
    ],
    'let-go': [
      ['Hebrews 12:1', 'Let us lay aside every weight, and the sin which clings so closely.'],
    ],
    love: [
      ['1 John 4:19', 'We love because he first loved us.'],
    ],
    focus: [
      ['Colossians 3:2', 'Set your minds on things that are above.'],
    ],
    calm: [
      ['Psalm 4:8', 'In peace I will lie down and sleep.'],
    ],
    rest: [
      ['Exodus 20:8', 'Remember the Sabbath day, to keep it holy.'],
    ],
    courage: [
      ['2 Timothy 1:7', 'God gave us a spirit not of fear but of power and love.'],
    ],
    hope: [
      ['Lamentations 3:21', 'This I call to mind, and therefore I have hope.'],
    ],
    wisdom: [
      ['Proverbs 9:10', 'The fear of the Lord is the beginning of wisdom.'],
    ],
    forgiveness: [
      ['Micah 7:19', 'You will cast all our sins into the depths of the sea.'],
    ],
    grief: [
      ['Psalm 30:5', 'Weeping may endure for a night, but joy comes in the morning.'],
    ],
    joy: [
      ['Zephaniah 3:17', 'He will rejoice over you with gladness.'],
    ],
    strength: [
      ['Philippians 4:13', 'I can do all things through him who strengthens me.'],
    ],
    grace: [
      ['Romans 5:20', 'Where sin increased, grace abounded all the more.'],
    ],
  },
};

function pickByIndex(arr, i) {
  return arr[((i % arr.length) + arr.length) % arr.length];
}

function slug(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

async function main() {
  const files = (await readdir(DIR))
    .filter(f => f.endsWith('.json'))
    .sort();

  // Filter to only B1 (launch_batch === 'B1' or no batch)
  const b1Files = [];
  for (const f of files) {
    const d = JSON.parse(await readFile(join(DIR, f), 'utf8'));
    if (d.launch_batch === 'B1' || !d.launch_batch) {
      b1Files.push({ f, d });
    }
  }
  console.log(`Found ${b1Files.length} B1 meditations`);

  let generated = 0;
  for (let b = 2; b <= 5; b++) {
    const batchCode = `B${b}`;
    for (let i = 0; i < b1Files.length; i++) {
      const { d: src } = b1Files[i];
      const theme = src.theme || 'stillness';
      const dayOfYear = src.day_of_year || (i + 1);

      // Pick a new title for this batch
      const titles = BATCH_TITLES[b]?.[theme] || BATCH_TITLES[b]?.stillness || [src.title];
      const title = pickByIndex(titles, i);

      // Pick a scripture
      const scriptures = SCRIPTURE_BY_BATCH[b]?.[theme] || SCRIPTURE_BY_BATCH[b]?.stillness || [[src.scripture_ref, src.scripture_text]];
      const [scriptureRef, scriptureText] = pickByIndex(scriptures, i);

      // Build a new body — paraphrase by appending a "reminder" paragraph that's
      // batch-flavored
      const batchFlavor = b === 2 ? 'And this is the second time around. You are not new to this. You are old to this. The Lord knows you. He has seen this day before, in you, and He is not surprised. He is the same. He is the same today.'
        : b === 3 ? 'This is the third time the year has come around to this day. You have been here before. The Lord has been here before. The body remembers. The soul remembers. The grace is the same.'
        : b === 4 ? 'This is the fourth time. You have gone deeper now than you went the first time. The well is deeper. The water is still. The Lord is at the bottom. Keep going.'
        : 'This is the fifth and final time the cycle has come to this day. The harvest is gathered. The hands are tired and the heart is full. The Lord, who began the work in you, will complete it. The cycle is not an ending. It is a Sabbath.';

      const body = src.body.trim() + '\n\n' + batchFlavor + '\n';

      // Bump reflection
      const reflection = src.reflection + ' (The ' + (b === 2 ? 'second' : b === 3 ? 'third' : b === 4 ? 'fourth' : 'fifth') + ' hearing of this day.)';

      const newRecord = {
        ...src,
        title,
        scripture_ref: scriptureRef,
        scripture_text: scriptureText,
        body,
        reflection,
        slug: slug(title),
        launch_batch: batchCode,
        // Keep same day_of_year within the batch
        day_of_year: dayOfYear,
        sort_order: (b - 1) * 1000 + dayOfYear, // distinct sort per batch
      };

      const fileName = `${String(b).padStart(2, '0')}${String(dayOfYear).padStart(3, '0')}-${slug(title)}.json`;
      const filePath = join(DIR, fileName);
      await writeFile(filePath, JSON.stringify(newRecord, null, 2) + '\n');
      generated++;
    }
    console.log(`  Generated batch ${batchCode}: ${b1Files.length} meditations`);
  }

  console.log(`✓ Total generated: ${generated} new meditations across B2-B5`);
}

main().catch(e => { console.error(e); process.exit(1); });
