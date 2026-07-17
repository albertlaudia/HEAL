-- HEAL — 10 new praise songs (2026-07-18)

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '0ede2c4d4633b8',
  'Not By Sight',
  'not-by-sight',
  'A walking song for the in-between',
  'hope',
  'anxious-but-hoping',
  'G',
  '4/4',
  84,
  '["in-between", "trust", "patience", "morning", "walking"]'::jsonb,
  '["morning", "anxiety", "waiting", "decision"]'::jsonb,
  '["2 Corinthians 5:7", "Habakkuk 2:3", "Psalm 37:7"]'::jsonb,
  '**[Verse 1]**
I cannot see the next horizon,
The road bends low where I can''t tell.
The map You drew is not yet open —
I walk by faith, and that is well.

**[Verse 2]**
The fog is thick, the lamp is steady,
The Shepherd knows the field by heart.
My hand in Yours is more than ready —
I do not need to play the part.

**[Chorus]**
I walk, I wait, I will not hurry.
The vision waits for its own hour.
You hold the morning, hold the mercy —
Lead on, lead on by love and power.

**[Verse 3]**
The bread is given for the walking,
The staff is comfort for the fear.
The dark is not the last thing talking —
Your voice has always been more near.

**[Verse 4]**
So I will set my face to follow,
One ordinary step at a time.
The cloud by day, the fire by swallow —
I am held, and I am Thine.

**[Chorus]**
I walk, I wait, I will not hurry.
The vision waits for its own hour.
You hold the morning, hold the mercy —
Lead on, lead on by love and power.

**[Bridge]**
Not by sight, not by sight,
The seen is not the light.
Not by sight, not by sight —
The unseen holds me right.',
  'Habakkuk 2:3 says the vision "is yet for an appointed time... though it
tarrys, wait for it." Some mornings the path doesn''t reveal itself because
it isn''t the path yet. We are not promised the whole map; we are promised
a companion who knows it by heart. Take one step today. The lamp that is
"steady" is enough.',
  '- Verse: G - Em - C - D (i - vii - IV - V in G)
- Chorus: C - G - D - Em - C - G - D
- Bridge: C - G - Am - Em (turnaround)',
  'A walking song for the in-between',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '714ef618f2aa45',
  'All My Years',
  'all-my-years',
  'A lament for what was lost and the God who stayed',
  'lament',
  'grieving',
  'D minor',
  '6/8',
  68,
  '["lament", "grief", "loss", "memory", "anniversary"]'::jsonb,
  '["grief", "anniversary-of-loss", "night", "memory"]'::jsonb,
  '["Psalm 13", "Psalm 88:1-2", "2 Samuel 12:23", "Revelation 21:4"]'::jsonb,
  '**[Verse 1]**
The chair is set, the chair is empty,
The cup is poured, the cup is still.
I keep the date inside my pocket —
What time it was, the room, the hill.

**[Verse 2]**
The Lord giveth, the Lord hath taken,
The voice said so, and it was true.
I do not understand the ledger,
But I will not stop loving You.

**[Chorus]**
All my years, all my years,
Bend toward a house I cannot see.
All my tears, all my tears,
You have held before they reached the sea.

**[Verse 3]**
The house has rooms — I heard You say it —
And if I go, I go prepared.
The love You set in me will not quit,
Though here the silence goes unguarded.

**[Verse 4]**
So I will set the chair a little longer,
And pour the cup and drink alone,
And let the grief do what it needs to,
And trust the seed beneath the stone.

**[Chorus]**
All my years, all my years,
Bend toward a house I cannot see.
All my tears, all my tears,
You have held before they reached the sea.

**[Outro]**
You have held them.
You have held them all.
You have held them.',
  'The Psalms do not flinch from the unanswerable. Psalm 88 ends without a
turn — the only psalm in the Bible that does. It is in the canon because
we need a song for the night that doesn''t end at dawn. He is there in the
unfinished music. He is there in the empty chair. The grief is not faith
lost; the grief is faith still walking, in the dark, holding a hand it
cannot see.',
  '- Verse: Dm - Bb - F - C (i - VI - III - VII in Dm)
- Chorus: Bb - F - C - Dm - Bb - F - C
- Outro: Dm - C - Bb - F - Dm (descending bass walk-down)',
  'A lament for what was lost and the God who stayed',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  'cd376069f7bda1',
  'Hundredfold',
  'hundredfold',
  'A small song for small mercies',
  'gratitude',
  'grateful',
  'C',
  '3/4',
  92,
  '["gratitude", "small-things", "ordinary-monday", "morning"]'::jsonb,
  '["morning", "ordinary-monday", "first-thing", "thankfulness"]'::jsonb,
  '["Mark 4:20", "Psalm 116:12", "Lamentations 3:22-23", "1 Thessalonians 5:18"]'::jsonb,
  '**[Verse 1]**
The bread is on the table, ordinary,
The sun came up, the second time.
I do not know which blessing carried me
Across the small hills of the night.

**[Verse 2]**
The friend who texted at a quiet hour,
The hand that brushed my sleeve in church,
The kettle and the long, unhurried morning —
These are the country of the search.

**[Chorus]**
Hundredfold, hundredfold,
What shall I render to the Lord?
I take the cup, I call it kindness,
I count the small things and call it more.

**[Verse 3]**
A hundred quiet things I did not earn,
A hundred I will not repay.
A hundred mornings set like little altars,
A hundred ordinary days.

**[Verse 4]**
The shadow at the door of every season,
The warmth that comes without a name,
The breath that asks for nothing but to keep going —
These, too, are part of the refrain.

**[Chorus]**
Hundredfold, hundredfold,
What shall I render to the Lord?
I take the cup, I call it kindness,
I count the small things and call it more.

**[Bridge]**
I will not be afraid of smallness,
I will not waste another day.
The kingdom comes in seeds and suppers,
The kingdom comes the small way.',
  '"What shall I render unto the Lord for all His benefits toward me?" Psalm
116 asks the question as if it were a math problem. The answer is
unsurprising: there is nothing we can render. The only honest response is
to take the cup and call it kindness. The hundredfold is a promise, not
a transaction. We count the small things not to pay back but to remember
that the count itself is a form of love.',
  '- Verse: C - Am - F - G (waltz, I - vi - IV - V)
- Chorus: F - C - G - Am - F - C - G
- Bridge: F - G - Am - Em (rising 5-6-7-3)',
  'A small song for small mercies',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '87a07b5e1a8290',
  'Lo, I Am With You',
  'lo-i-am-with-you',
  'A song for the work that is too much',
  'comfort',
  'overwhelmed',
  'A',
  '4/4',
  76,
  '["work", "calling", "tired", "called", "presence"]'::jsonb,
  '["work", "calling", "tired", "decision", "morning-of-something-big"]'::jsonb,
  '["Joshua 1:9", "Isaiah 41:10", "Exodus 3:12", "Matthew 28:20"]'::jsonb,
  '**[Verse 1]**
The task is set, the table wide,
The work is more than I can hold.
I do not know the road You chose me to,
But I am told I will be told.

**[Verse 2]**
The staff is Yours, the bread is Yours,
The courage is not mine to keep.
I have only the one obedience —
The next small step, the next hard leap.

**[Chorus]**
Lo, I am with you, lo, I am with you,
To the end of all the age, to the end.
Lo, I am with you, lo, I am with you,
Be strong, be still, begin.

**[Verse 3]**
Moses trembled, Joshua feared,
The boy brought loaves, the widow wept.
The work is always too big for the worker —
That is how the kingdom kept.

**[Verse 4]**
So here I am, and here the work,
The room, the table, the long day.
The promise underneath the promise:
I will not leave you on the way.

**[Chorus]**
Lo, I am with you, lo, I am with you,
To the end of all the age, to the end.
Lo, I am with you, lo, I am with you,
Be strong, be still, begin.

**[Bridge]**
The mountain will not crush the path,
The flood will not outrun the ark.
The One who calls is not the One who leaves —
The same God lit the dark.',
  '"Lo, I am with you always, even unto the end of the age" is the only
promise Jesus made to the church in the abstract. He didn''t promise
success, or applause, or clarity of method. He promised presence. Most
of the work we are called to is too big for us. That is the design. The
work is the means by which we learn we are not alone. Do the next small
step; He is in the step.',
  '- Verse: A - F#m - D - E (I - vi - IV - V)
- Chorus: D - A - E - F#m - D - A - E
- Bridge: D - A - F#m - E (modal mixture at the end)',
  'A song for the work that is too much',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '80708816a010a8',
  'Wake, O Sleeper',
  'wake-o-sleeper',
  'A song for the first moment of morning',
  'adoration',
  'waking',
  'E',
  '4/4',
  96,
  '["morning", "waking", "new-beginnings", "light"]'::jsonb,
  '["first-thing", "morning", "after-sleep", "new-day"]'::jsonb,
  '["Ephesians 5:14", "Psalm 30:5", "Genesis 1:3", "Lamentations 3:23"]'::jsonb,
  '**[Verse 1]**
The first light comes without permission,
The first breath pulls without my will.
I did not earn the gift of waking,
But here I am, and here, and still.

**[Verse 2]**
The room is quiet, the room is waiting,
The kettle dreams of what it does.
The mercies are new at the windows,
The mercies are new because

**[Chorus]**
Wake, O sleeper, the light is given,
Lift your head, the dawn is sent.
This day is not the same as yesterday,
And I will meet you in it, gent.

**[Verse 3]**
I do not know what it will carry,
The road, the call, the broken friend.
But I am met, and I am carried,
And I will lean into the bend.

**[Verse 4]**
So let the morning have its order,
The bread, the water, the small prayer.
The kingdom comes through bread and water —
The kingdom is already here.

**[Chorus]**
Wake, O sleeper, the light is given,
Lift your head, the dawn is sent.
This day is not the same as yesterday,
And I will meet you in it, gent.

**[Outro]**
Gent, gent, gentle.
The Lord is gentle.
He will not break the bruised reed.',
  '"His mercies are new every morning" (Lam 3:23) is in the present tense on
purpose. The Hebrew doesn''t say "they were new"; it says "they are new,"
now, as you open your eyes. The first act of the day is to be given
something. The day is not what we make it; the day is what arrives. We
enter it as a guest, not a contractor. Wake, sleeper. The light has come
asking nothing of you yet.',
  '- Verse: E - C#m - A - B (I - vi - IV - V)
- Chorus: A - E - B - C#m - A - E - B
- Outro: E - C#m - A - B (slow half-time)',
  'A song for the first moment of morning',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '5d9614034ba5a8',
  'Table For The Stranger',
  'table-for-the-stranger',
  'A song for the door you opened',
  'celebration',
  'open-hearted',
  'D',
  '4/4',
  108,
  '["hospitality", "welcome", "stranger", "table", "celebration"]'::jsonb,
  '["evening", "welcome", "with-friends", "after-a-hard-week"]'::jsonb,
  '["Hebrews 13:2", "Romans 12:13", "Luke 14:13-14", "Genesis 18:1-8"]'::jsonb,
  '**[Verse 1]**
I set another place tonight,
The bread is broken, the wine is poured.
I do not know whose road brought them,
But they are at the table of the Lord.

**[Verse 2]**
The house was small before they came,
And smaller after, and somehow more.
The walls stretched out to hold the story,
The door I opened held the door.

**[Chorus]**
Table for the stranger, table for the friend,
The kitchen is a country without end.
Pull up a chair, the chair was always yours,
The bread is broken, the love won''t bend.

**[Verse 3]**
Abraham ran to meet the three,
He did not know who he would feed.
The ceiling cracked, the laughter came —
The promise was a stranger''s need.

**[Verse 4]**
So bring them in, the tired, the wary,
The ones who do not know the song.
We will not ask them for the answer,
We will not ask them to belong.

**[Chorus]**
Table for the stranger, table for the friend,
The kitchen is a country without end.
Pull up a chair, the chair was always yours,
The bread is broken, the love won''t bend.

**[Bridge]**
Some days the table is the answer
To the question the day forgot to ask.
Set it anyway. The bread will rise.
Set it anyway. The wine will last.',
  'Hebrews 13:2 — "Be not forgetful to entertain strangers: for thereby some
have entertained angels unawares." Abraham ran to the tent flap when the
three men appeared in the heat of the day. He didn''t ask who they were.
He set out bread, curds, and milk. The strangers turned out to be the
promise he had been waiting twenty-five years for. Hospitality is a form
of hope: you set the table for the version of the world you want, before
the world has caught up to it.',
  '- Verse: D - Bm - G - A (I - vi - IV - V)
- Chorus: G - D - A - Bm - G - D - A
- Bridge: Em - G - D - A (relative minor lift)',
  'A song for the door you opened',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '36a8f44fe22332',
  'The Long Obedience',
  'the-long-obedience',
  'A song for the years that don''t seem to change',
  'hope',
  'weary-but-faithful',
  'F# minor',
  '4/4',
  80,
  '["perseverance", "long-haul", "weary", "years", "discipline"]'::jsonb,
  '["after-a-long-time", "weary", "perseverance", "mid-life"]'::jsonb,
  '["Hebrews 12:1", "Galatians 6:9", "Hosea 2:15", "Ecclesiastes 3:1"]'::jsonb,
  '**[Verse 1]**
The same street, the same morning,
The same bread, the same cup.
The years have not moved the way I asked them,
And the prayer has not come up.

**[Verse 2]**
I asked for fire, I asked for thunder,
I asked to see the kingdom come.
I did not get the thing I wanted —
I got the next small thing, and some.

**[Chorus]**
The long obedience, the long obedience,
The patient, plodding, daily way.
The long obedience, the long obedience,
The seed is buried, and the dawn is gray.

**[Verse 3]**
But there is a kind of growing that is hidden,
A kind of root that goes down deep.
The oak is in the acorn working
While the farmer rolls in sleep.

**[Verse 4]**
I will not be afraid of sameness,
I will not despise the small.
The plodding saints have outlasted thunders —
The plodding saints have outlasted all.

**[Chorus]**
The long obedience, the long obedience,
The patient, plodding, daily way.
The long obedience, the long obedience,
The seed is buried, and the dawn is gray.

**[Bridge]**
Run with patience the race set before me,
Looking to Jesus, the author, the end.
The faith is not the shout but the staying,
The faith is not the start but the bend.',
  'Eugene Peterson paraphrases Hebrews 12:1 as "the long obedience in the
same direction." Most of what we are called to is not heroic but
perseverant. The plodding saint — the one who keeps getting up, keeps
praying, keeps loving, keeps the practice — has outlasted the spectacular
saints, because spectacular doesn''t survive Tuesday morning. The seed
is doing its slow work in the dark. You don''t have to see it. You only
have to keep planting.',
  '- Verse: F#m - D - A - E (i - VI - III - VII in F#m)
- Chorus: D - A - E - F#m - D - A - E
- Bridge: A - C#m - D - E (relative major lift, then back)',
  'A song for the years that don''t seem to change',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '446011343e4ceb',
  'He Counts The Sparrows',
  'he-counts-the-sparrows',
  'A song for when no one is watching',
  'comfort',
  'invisible',
  'G',
  '3/4',
  72,
  '["invisible", "watched", "unseen", "comfort", "loved"]'::jsonb,
  '["alone", "overlooked", "lonely", "midnight"]'::jsonb,
  '["Matthew 10:29-31", "Psalm 139:1-3", "Hebrews 4:13", "Luke 12:6-7"]'::jsonb,
  '**[Verse 1]**
Not a sparrow falls without the knowing,
Not a hair, not a moment, not a sigh.
The God who set the constellations going
Has counted every tear your eye lets lie.

**[Verse 2]**
The room is quiet, the room is lonely,
The work is small, and no one is around.
You think that no one sees the cost of it —
You think the going-through is underground.

**[Chorus]**
He counts the sparrows, He counts the small,
He numbers every hair upon your head.
He holds the moment that you think is nothing,
And He will not forget the wine you bled.

**[Verse 3]**
The watcher in the window, He is faithful,
The watcher in the wheat, He does not sleep.
Your name is in the book before the ages,
And every cup of water you shall keep.

**[Verse 4]**
You are not small because you are unseen,
You are not lost because no one is looking.
The God of the unnoticed, the God of the kitchen,
Has been writing you in a book.

**[Chorus]**
He counts the sparrows, He counts the small,
He numbers every hair upon your head.
He holds the moment that you think is nothing,
And He will not forget the wine you bled.

**[Bridge]**
You are not forgotten.
You are not unseen.
You are not unloved —
You are only, finally, in between.',
  '"Are not two sparrows sold for a farthing? And one of them shall not fall
on the ground without your Father" (Matt 10:29). The argument is from the
smaller to the larger. If He attends to the sparrow, how much more to
you. The theology is not that you are special; the theology is that He
pays attention. The whole creation is held by attention. You are held by
attention. The tears you cry in the kitchen, the long shift, the small
year of work no one applauded — He was watching the whole time. He is
still.',
  '- Verse: G - Em - C - D (waltz, I - vi - IV - V)
- Chorus: C - G - D - Em - C - G - D
- Bridge: Am - Em - C - D (relative minor turn)',
  'A song for when no one is watching',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '616ff6910b4a53',
  'The Welcome At The Gate',
  'the-welcome-at-the-gate',
  'A song for the end of the day',
  'comfort',
  'worn-out',
  'D',
  '4/4',
  64,
  '["evening", "rest", "end-of-day", "come-home", "weary"]'::jsonb,
  '["evening", "end-of-day", "come-home", "weary", "tired"]'::jsonb,
  '["Psalm 4:8", "Matthew 11:28-30", "Revelation 3:20", "Psalm 139:9-10"]'::jsonb,
  '**[Verse 1]**
The day is done, the keys are down,
The door is shut, the lamp is low.
I have been out where the world is loud,
And now I am at the door I know.

**[Verse 2]**
The work is laid aside a moment,
The face is washed, the breath is slow.
The house is quiet, the house is waiting,
The welcome is the only show.

**[Chorus]**
Come in, come in, the day is over,
Lay down the weight you carried through.
The door was always, always open,
The welcome is the part that''s true.

**[Verse 3]**
The Lord of rest is at the threshold,
The Lord of evening, the Lord of bread.
He does not ask for any story,
He only asks that I be fed.

**[Verse 4]**
The bread is broken, the wine is poured,
The chair is set, the lamp is lit.
The Shepherd counts me as a member
Of the household I had quit.

**[Chorus]**
Come in, come in, the day is over,
Lay down the weight you carried through.
The door was always, always open,
The welcome is the part that''s true.

**[Outro]**
I lay me down.
I lay me down.
The Shepherd of the sheep is found.',
  '"In peace I will lay me down, and sleep; for thou, Lord, only makest me
to dwell in safety" (Psalm 4:8). The day has extracted what it wanted
from us. We do not have to give it more by reliving it in the dark. The
evening is not a courtroom; it is a threshold. The Lord of the Sabbath
is the Lord of the threshold too. He stands at the door. We do not have
to knock. We have only to come in. The bread is already broken. The lamp
is already lit. The chair is already set.',
  '- Verse: D - Bm - G - A (I - vi - IV - V, slow)
- Chorus: G - D - A - Bm - G - D - A
- Outro: D - Bm - G - A (single pass, then soft to rest)',
  'A song for the end of the day',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

INSERT INTO heal_praise (id, title, slug, subtitle, category, emotion,
  key_signature, meter, tempo_bpm, tags, best_for, scripture_refs,
  lyrics, reflection, chords, description, is_published, sort_order) VALUES (
  '04ca8d72295023',
  'The Stone Was Rolled',
  'the-stone-was-rolled',
  'A resurrection song for ordinary Sunday',
  'celebration',
  'joyful',
  'E',
  '4/4',
  112,
  '["resurrection", "easter", "joy", "celebration", "morning"]'::jsonb,
  '["sunday", "celebration", "after-good-news", "easter", "morning"]'::jsonb,
  '["Matthew 28:6", "Mark 16:4", "1 Peter 1:3", "Romans 6:9"]'::jsonb,
  '**[Verse 1]**
The dawn was early, the dawn was heavy,
The spices cold, the road was long.
We came to mourn a thing that was finished,
We came to find a finished song.

**[Verse 2]**
But there was no body in the garden,
The grave-clothes lay like a folded plan,
The angel sat where the dead had lain —
He is not here; behold the man.

**[Chorus]**
The stone was rolled, the stone was rolled,
The keeper of the keys is free.
The stone was rolled, the stone was rolled,
Come out, come out, and we shall see.

**[Verse 3]**
The locked rooms opened with His breathing,
The fish was cooked upon the coals.
The wounds were still the wounds of Friday,
The hands still bore the doubled holes.

**[Verse 4]**
The Spirit fell like a rushing fountain,
The tongues of flame, the lifted heads.
The Lord was made of bread and laughter,
The Lord was made of wine and bread.

**[Chorus]**
The stone was rolled, the stone was rolled,
The keeper of the keys is free.
The stone was rolled, the stone was rolled,
Come out, come out, and we shall see.

**[Bridge]**
Death is dead.
The dead is risen.
The garden is awake.
The garden is awake.
The garden is awake.

**[Outro]**
He is not here.
He is not here.
The gardener is everywhere.',
  '"He is not here: for he is risen, as he said. Come, see the place where
the Lord lay" (Matt 28:6). The resurrection is not a doctrine; it is a
place you go to. The women came expecting a closed thing and were met by
an open one. The folded grave-clothes were the sermon: the body did not
escape; the body was unfolded into a new kind of life. Death is not
destroyed by argument. Death is destroyed by being outlasted. The stone
is still being rolled, on every ordinary Sunday, every time bread is
broken, every time a locked room is entered by breathing. The gardener
is everywhere.',
  '- Verse: E - C#m - A - B (I - vi - IV - V)
- Chorus: A - E - B - C#m - A - E - B
- Bridge: C#m - A - E - B (modular, repeats)
- Outro: E - C#m - A - B (single pass, soft, then lift on "everywhere")',
  'A resurrection song for ordinary Sunday',
  true,
  100
) ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, subtitle = EXCLUDED.subtitle,
  category = EXCLUDED.category, emotion = EXCLUDED.emotion,
  key_signature = EXCLUDED.key_signature, meter = EXCLUDED.meter,
  tempo_bpm = EXCLUDED.tempo_bpm, tags = EXCLUDED.tags,
  best_for = EXCLUDED.best_for, scripture_refs = EXCLUDED.scripture_refs,
  lyrics = EXCLUDED.lyrics, reflection = EXCLUDED.reflection,
  chords = EXCLUDED.chords, description = EXCLUDED.description;

