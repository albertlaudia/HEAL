#!/usr/bin/env python3
"""
HEAL — daily-world.py
======================
Generates one "today in the world" piece per run, rotates across three flavours:

  challenge  — a real problem in the world (grief, war, loneliness, injustice, anxiety).
  grace      — something good already happening but easy to miss (a stranger's kindness,
               a child's laughter, a friend's patience, a sunrise).
  gratitude  — a thing worth giving thanks for (a meal, a roof, a memory, a season).

Each piece has FOUR parts, in this exact order:
  1. prompt       — 2-4 sentences describing the situation plainly.
  2. scripture    — one Bible verse (ref + text) that meets the moment.
  3. reflection   — 100-180 words on what the Bible says about this and why it matters.
  4. prayer       — 60-100 words, addressed to God, gentle and usable.
  5. expectation  — 30-60 words on how we could expect the best out of this situation.

The pieces feel like a quiet friend pointing out: "look, the world is heavy / good
/ lovely today. Here is what the Bible says. Here is a prayer. Here is one hopeful
thing we could do or expect."

Output: 1 PB record in HEAL_world, slug = `world-{yyyymmdd}`.
"""
import os, sys, json, random, hashlib, urllib.request, urllib.error
from datetime import datetime, timezone, timedelta

# ─── CONFIG ───────────────────────────────────────────────────────────────────
PB_URL       = os.environ.get('PB_URL', 'https://pocketbase.scaleupcrm.com')
PB_IDENTITY  = os.environ.get('PB_IDENTITY')
PB_PASSWORD  = os.environ.get('PB_PASSWORD')

CDN_BASE     = 'https://resources.positiveness.club/heal'
FTP_USER     = os.environ.get('SMARTERASP_FTP_USER', 'respc')
FTP_PASS     = os.environ['SMARTERASP_FTP_PASSWORD']

CACHE_DIR    = '/workspace/.mavis-cache/heal-world'
os.makedirs(CACHE_DIR, exist_ok=True)

USED_FILE    = f'{CACHE_DIR}/used-slugs.json'

# ─── DATE / MODE ───────────────────────────────────────────────────────────────
# Australia day-rollover: cron runs at 21:00 UTC = 06:00 in Sydney (AEST+10).
# But we want the piece's "day" to be the AUSTRALIA day, not UTC.
# So compute "today" in Australia first, then back-derive UTC.
def australia_today():
    # Cron fires at 21:00 UTC; that is 06:00 next-day in Sydney AEST (UTC+10)
    # in winter, and 07:00 in Sydney AEDT (UTC+11) in summer.
    # Australia doesn't observe DST in Queensland, WA, NT — they're fixed.
    # We want the most common case (AEST), and the day at 06:00 local is the
    # SAME calendar date as 21:00 UTC the previous day (for AEST+10).
    return datetime.now(timezone.utc).date()

TODAY         = australia_today()
SLUG          = f'world-{TODAY.isoformat()}'
DAY_OF_YEAR   = TODAY.timetuple().tm_yday

# Mode rotation — Mon: challenge, Tue: grace, Wed: gratitude, Thu: challenge, ...
MODE_ROTATION = ['challenge', 'grace', 'gratitude', 'challenge', 'grace', 'gratitude', 'grace']
# (Sun leans grace because gratitude is often Sunday's vibe from church & family.)

# Stable per-day seed → reproducible but varied across the year.
DAY_SEED      = int(hashlib.sha256(TODAY.isoformat().encode()).hexdigest(), 16)
random.seed(DAY_SEED)

MODE          = MODE_ROTATION[(TODAY.weekday()) % len(MODE_ROTATION)]
# But also: every ~10th day force a 'gratitude' so we never go too long without praise.
if DAY_OF_YEAR % 10 == 0:
    MODE = 'gratitude'

print(f"[daily-world] today={TODAY} doy={DAY_OF_YEAR} weekday={TODAY.weekday()} mode={MODE}")

# ─── MODE THEMES (seed material) ──────────────────────────────────────────────
# We curate a wide seed bank. The actual prompt/reflection/prayer text is
# procedurally templated by mode, with each theme having variations.

CHALLENGE_THEMES = [
    # (theme_label, prompt_template, scripture_pool, reflection_seeds, prayer_seeds, expectation_seeds)
    ('loneliness at the end of a long day',
     'It is the kind of evening where the lights of other houses look warm and the walls of your own room feel very far away. Many people are feeling this tonight.',
     ['Psalm 25:16', 'Isaiah 41:10', 'Matthew 11:28', 'Hebrews 13:5', 'Psalm 34:18'],
     ['God does not ask us to perform company. He offers to sit with us in it.',
      'Loneliness is not a verdict on your life. It is a doorway, and God knows the address.',
      'Even Christ in the garden asked for companionship; the absence of it is human, not cursed.'],
     ['Lord, be near to those who feel unseen tonight. Remind them that You are not a guest but a resident of the soul.',
      'God of the quiet hours, walk into this room. Sit. Stay. We do not need a speech, just a presence.'],
     ['You could expect one small kindness from yourself today — to turn off the screens for ten minutes and let the silence be your company.']),
    ('a city that feels unsafe',
     'There are streets where the news feels closer. People who must choose their route home with care. Children hearing raised voices. The world, today, has places like this.',
     ['Psalm 46:1', 'Proverbs 3:24', 'Isaiah 26:3', 'Romans 12:18', 'Psalm 4:8'],
     ['God is not blind to the broken places; He is closer there than the headlines suggest.',
      'Safety is a gift some people are still waiting to unwrap. We can pray for them as if they were in the room.',
      'Peace is not the absence of trouble. It is the presence of Someone larger than the trouble.'],
     ['Lord of the broken streets, be a fence tonight. Be a hand on a shoulder. Let sleep find the frightened, and let morning come gently.',
      'God of the city, walk every block we cannot. Stand in every doorway we cannot guard.'],
     ['You could expect to be the calm in one small moment today — a slow reply, a held door, a quiet voice in a loud room.']),
    ('grief that has no name yet',
     'Some losses are still finding their shape. A job, a season, a person who is alive but no longer the same. There are mornings the grief is a colour, not a thought.',
     ['Psalm 34:18', 'Matthew 5:4', '2 Corinthians 1:3-4', 'Revelation 21:4', 'Psalm 147:3'],
     ['To name grief is a kind of courage God honours. He does not require us to name it perfectly.',
      'The Lord is "close to the brokenhearted" — present tense, not past. The verse is true right now.',
      'Healing is not always forward. Sometimes it is sideways, then forward, then sideways again.'],
     ['Lord of the unnamed loss, hold what we cannot hold. Carry what we cannot say. We trust You with the inarticulate parts.',
      'God who keeps our tears in a bottle, do not let one be wasted. Turn each one into something living.'],
     ['You could expect one small honest sentence today — to a friend, a journal, a stranger — that lets the unsaid thing finally be said.']),
    ('worry that won\u2019t sit down',
     'The mind is making a list and checking it twice and it is not Christmas. There are bills, deadlines, conversations waiting to be hard. Sleep is a negotiation.',
     ['Philippians 4:6-7', 'Matthew 6:34', 'Psalm 94:19', 'Isaiah 26:3', '1 Peter 5:7'],
     ['Worry is what happens when tomorrow tries to come before its turn. God is asking us to put it back in the queue.',
      'Cast your anxiety on Him — not because He needs our problems, but because we need a place to set them down.',
      'The peace He offers is not the absence of concerns; it is the presence of a Person who outranks them.'],
     ['Lord of the restless mind, slow us down. Remind us that the things we dread are not here yet, and You are already with us in tomorrow.',
      'God of sleep, meet us at the edge of the bed. Quiet the list. Cover the worried head.'],
     ['You could expect one small unclenched moment today — three slow breaths before opening the inbox, a long walk after lunch, a song instead of a scroll.']),
    ('a world that feels divided',
     'In many places today, neighbour is not speaking to neighbour, country to country, even friend to friend. The news is a wall and the wall is loud.',
     ['Ephesians 4:3', 'Romans 12:18', 'Matthew 5:9', 'Psalm 133:1', 'Colossians 3:14'],
     ['Division is not new under the sun; the unity Christ prayed for is older still.',
      'The early church was a small, stubborn experiment in being one. We are part of that experiment.',
      'Peace-makers are not passive; they are doing some of the bravest work in the kingdom.'],
     ['Lord of every nation and every family table, soften what is hard. Bridge what is broken. Teach us to disagree without unseeing a neighbour.',
      'God of peace, give us the words that do not wound, and the silence that does not punish.'],
     ['You could expect to be the one who listens first today. To ask a kind question. To let someone finish a sentence.']),
    ('someone you love is far away',
     'There are people we love who are not in this room. They are across a city, a country, a decade. The connection is real, but the body is not here.',
     ['Psalm 139:7-10', 'Hebrews 13:5', '1 Corinthians 13:8', 'Romans 8:38-39', 'Deuteronomy 31:6'],
     ['Distance is not the same as absence. The love that formed the bond is the same love that holds it across any distance.',
      'Where two or three are gathered in His name, He is there — and that includes the two of you, even from a thousand miles apart.',
      'God has always been in the long-distance business. He is closer to both of you than you are to each other.'],
     ['Lord, be with the ones we love who are not beside us tonight. Hold them as we would hold them. Give us peace about the spaces between.',
      'God of long distances, please keep them safe, keep them well, keep them tender.'],
     ['You could expect to send one small thing today — a voice memo, a photo of nothing in particular, a line that says "I was just thinking of you."']),
    ('a season that has gone on too long',
     'Some seasons drag. Waiting for the job, the test result, the relationship to right itself, the cough to lift. The finish line has moved twice.',
     ['Galatians 6:9', 'James 1:2-4', 'Romans 5:3-4', 'Psalm 27:14', 'Habakkuk 2:3', 'Lamentations 3:25-26'],
     ['Long seasons are not wasted seasons. They are the soil; roots grow in them, mostly out of sight.',
      'Faithfulness is built more in waiting than in winning. The character forged here will outlast the problem.',
      'God is not behind on your timeline. He is doing something specific in the duration.'],
     ['Lord of the long road, walk with us in this stretch. Give us the small graces to keep going. We are tired but not quitting.',
      'God of waiting, do not let the waiting harden us. Keep us soft, keep us open, keep us Yours.'],
     ['You could expect one small visible sign of progress today — even if it is just that the next step is clearer than it was last week.']),
]

GRACE_THEMES = [
    ('a stranger\u2019s small kindness',
     'Today, somewhere, a stranger will hold a door a beat longer than needed. The wordless economy of small kindnesses is still operating, even when we forget to notice it.',
     ['Galatians 6:9-10', 'Hebrews 13:2', 'Colossians 3:12', '1 John 4:7', 'Matthew 25:40'],
     ['Kindness is one of the few things you can spend and still have. It does not deplete. It returns.',
      'Many of the Bible\u2019s most important encounters begin with a stranger — at a well, on a road, at a gate.',
      'The smallest kindnesses have the longest half-life. You will not see where yours landed today.'],
     ['Lord, thank You for the unnamed ones who slowed down for us this week. Make us more like them tomorrow.',
      'God of small mercies, open our eyes for the kindness already passing by.'],
     ['You could be the stranger\u2019s kindness for someone today. A held door. A returned smile. A sentence that costs nothing and lands warm.']),
    ('a child\u2019s laugh in a serious room',
     'Children are still laughing at things we have stopped noticing. The way the dog\u2019s ear flips. The mystery of a puddle. There is a sermon in every one of these.',
     ['Matthew 18:3', 'Mark 10:14-15', 'Psalm 8:2', 'Matthew 19:14', 'Luke 18:16'],
     ['Jesus did not say "become childlike in your theology." He said childlike in your wonder.',
      'Children live closer to the surface of things. Most adults learn to walk past the wonder; the kingdom calls us back.'],
     ['Lord, keep us soft enough to hear what only children can still hear. Forgive our serious faces.',
      'God of small wonders, do not let us grow too old for puddle theology.'],
     ['You could expect to be caught by something small today — a sound, a colour, an unexpected kindness — and to let it stop you.']),
    ('a sunrise nobody asked for',
     'The sunrise did not wait to be appreciated. It came anyway. There is something quietly defiant about a sunrise: it keeps happening whether you saw it or not.',
     ['Psalm 19:1-4', 'Lamentations 3:22-23', 'Genesis 1:3-5', 'Psalm 30:5', '2 Corinthians 4:6'],
     ['Every sunrise is a slow, ongoing announcement: the world is being re-made by a God who does not run out of mornings.',
      '"His mercies are new every morning" — the verse almost refuses to be small. It is an astronomical claim.'],
     ['Lord, thank You for the morning that came even when we did not deserve it, and especially the morning we did not notice.',
      'God of the early hours, be the first thing we look at, before the phone, before the noise.'],
     ['You could expect tomorrow\u2019s sunrise to be there waiting, patient as a parent outside a school.']),
    ('a friend\u2019s unexpected patience',
     'There is someone in your life who, recently, has been more patient with you than you have been with yourself. They have not made a thing of it. That is grace wearing a quiet coat.',
     ['1 Corinthians 13:4-7', 'Ephesians 4:2', 'Colossians 3:13', 'Proverbs 17:1', 'Galatians 6:2'],
     ['Patience is love measured in time. We rarely know how much of it the people around us have spent on us.',
      'God\u2019s patience with us is the longest-running project in the universe, and He does it without grudge.'],
     ['Lord, thank You for the patient ones — the ones who held the line while we figured ourselves out. Bless them openly, secretly, deeply.',
      'God who is slow to anger, give us Your same patience with the people who are still learning.'],
     ['You could expect to be told today, by text or voice or silence, that you matter. Look for it.']),
    ('a meal that was enough',
     'Today, somewhere, a plate of simple food was enough. No performance, no menu. Just rice, or bread, or soup. The smallest meal can carry the largest gratitude.',
     ['Psalm 145:15', 'Matthew 6:11', 'John 6:11', 'Acts 2:46', '1 Timothy 4:4-5'],
     ['Jesus fed people more than once. Most of the miracles He performed were dinner-table sized.',
      'Gratitude is one of the few feelings that grows the more you spend it. The meal is the seed.'],
     ['Lord, thank You for the meal that arrived on time today. For the bread that was warm and the water that was cold.',
      'God of every table, bless the hands that made the food, and the hands that will pass it on.'],
     ['You could expect to be part of someone\u2019s "enough" today — feeding a child, an elder, a tired friend.']),
    ('the persistence of beauty',
     'There are gardens growing quietly behind fences you have never seen. There are poems being written tonight that will outlast the headlines. Beauty, despite everything, is still in the work.',
     ['Ecclesiastes 3:11', 'Psalm 27:4', 'Song of Songs 2:1', 'Isaiah 35:1-2', '1 Peter 3:3-4'],
     ['Beauty is one of God\u2019s most reliable signatures. It survives empires. It does not argue with us; it simply waits.',
      'C.S. Lewis called joy "the serious business of heaven." Beauty is its emissary.'],
     ['Lord, thank You for not letting the world become ugly. For the music, the colour, the kindness that does not compute.',
      'God of beauty, sharpen our eyes for the small loveliness that is always on offer.'],
     ['You could expect to notice one beautiful thing today that you would have walked past yesterday.']),
    ('the body that woke you up',
     'You are alive this morning. The lungs did the thing. The heart did the thing. Whatever else is broken, the breath is back. That is grace in its purest form — undeserved, mechanical, miraculous.',
     ['Psalm 139:13-14', 'Job 33:4', 'Genesis 2:7', 'Lamentations 3:23', '2 Corinthians 5:1-4'],
     ['The body is not something we have earned. It is something we have been lent. Every morning is an installment of the loan.',
      'To wake up is, technically, a small resurrection. We are getting daily practice at the thing Christ did once for all.'],
     ['Lord, thank You for the lungs. For the eyes that opened this morning. For the body, in all its strange faithfulness.',
      'God of breath, every inhale is a fresh grace. Help us not to waste them on the small complaints.'],
     ['You could expect to be gentle with the body today — to walk a little, drink water, eat slowly, sleep on time.']),
]

GRATITUDE_THEMES = [
    ('ordinary shelter',
     'Tonight there will be a roof over someone who did not earn one. The rain will not find them. The wind will not enter. There is no name for how rare that is, except: gift.',
     ['Psalm 4:8', 'Psalm 91:1-2', 'Proverbs 30:8-9', 'Matthew 6:26', 'Hebrews 13:5'],
     ['Shelter is one of the most ancient gifts of God to His people, mentioned in the second chapter of Genesis.',
      'A roof is the kind of mercy that disappears the moment you stop noticing it. We are not meant to outgrow noticing it.'],
     ['Lord, thank You for the walls around us tonight. For the door that locks. For the bed that holds us. Keep those without shelter tonight.',
      'God of every roof, bless the houses and the homes and the small rooms where people sleep safely.'],
     ['You could expect, today, to notice one quiet thing about where you live that you can be glad of — a window, a pillow, a person.']),
    ('the friend who stayed',
     'There is a person who has known you across multiple versions of yourself. They have seen your hard years and your better ones and they have not flinched. They are still there.',
     ['Proverbs 17:17', '1 Samuel 18:3', 'John 15:13', 'Ecclesiastes 4:9-10', '1 Thessalonians 5:11'],
     ['Friendship that survives time is among the rarest, most undervalued things on earth.',
      'Friendship is one of the few relationships where you can be known without being performed at.'],
     ['Lord, thank You for the one who stayed. Thank You for the texts, the calls, the long silences that did not mean the end.',
      'God of every long friendship, we bless the names in our heads right now. Keep them. Bless them back.'],
     ['You could expect, today, to be the friend who stays for someone else.']),
    ('the table and what is on it',
     'There is food today. Maybe not as much as we would like. But there is food. The hands that made it, the hands that bought it, the hands that shared it — every step of it was an answered prayer.',
     ['Psalm 145:15', '1 Timothy 4:4-5', 'Matthew 14:19-20', 'Acts 2:46', 'Deuteronomy 8:10'],
     ['Gratitude for food is older than the church. It was a manna-thing before it was a sacrament-thing.',
      'Every meal we eat, we eat on borrowed time. The chain from soil to plate is long and full of grace.'],
     ['Lord, thank You for today\u2019s food. For the hands that cooked it. For the table that held it. Bless those whose tables were empty today.',
      'God of every meal, we eat as people receiving. Remind us, often, that this is enough.'],
     ['You could expect to be part of feeding someone today — buying a coffee, sharing a meal, leaving groceries for a neighbour.']),
    ('the morning you almost missed',
     'You woke up. The day is here. It will contain some beautiful minutes and some hard minutes. Both are grace — the beautiful ones because they are gifts, the hard ones because they are growable.',
     ['Lamentations 3:22-23', 'Psalm 118:24', 'Psalm 30:5', '2 Corinthians 4:16', 'James 1:17'],
     ['Every good day is the Lord\u2019s gift. Every hard day is also His, because He does not leave us in either.',
      'To wake up is to be re-included in the story. The previous day closed. Today opened.'],
     ['Lord, thank You for the morning. Even the parts that woke us too early. Especially those.',
      'God of new days, make us gentle with what comes. Help us to be present for at least one true thing today.'],
     ['You could expect to find, somewhere between now and tonight, one small thing worth writing down.']),
    ('a season of mercy',
     'Look back: things are not as you feared. The thing you lost you have not yet lost. The thing you dreaded did not fully arrive. There has been mercy, distributed quietly, all along.',
     ['Psalm 103:1-4', 'Ephesians 2:4-5', 'Titus 3:4-7', 'Romans 8:28', 'Isaiah 30:18'],
     ['Mercy is what we receive without paying for. Most of our lives are made of it. We just rarely total it up.',
      'The gospel is not primarily about what we owe God. It is about what God has already given us, in spite of us.'],
     ['Lord, thank You for the mercy that does not get headlines. Thank You for the things that did not happen.',
      'God of second chances and quiet rescues, we receive what You have given. We will not take it for granted today.'],
     ['You could expect, today, to thank one person for something specific. Even quietly. Even in your head.']),
    ('the song you cannot stop humming',
     'There is music in your head right now. A hymn. A fragment. A line. Music is one of the ways the soul remembers it is a soul — the melody slips past every defence.',
     ['Psalm 98:1', 'Ephesians 5:19', 'Colossians 3:16', 'Psalm 13:6', 'Psalm 96:1'],
     ['Music is older than language. God invented it for the morning stars to sing, before any human ear could hear.',
      'When the words run out, the music is still there. That is a kindness built into the human heart.'],
     ['Lord, thank You for the song that did not let go. For the hymn that found us in the checkout line.',
      'God of every melody, sing in us today. Even the ones we cannot name.'],
     ['You could expect one moment today where you hear music, real or remembered, and let yourself stop and listen.']),
    ('something you once prayed for',
     'Somewhere in your life, there is an answered prayer you have stopped noticing. It came quietly, in disguise, and you have already begun to take it for granted. The heart that prayed for it would be glad to see it from here.',
     ['Psalm 66:20', 'James 5:16', '1 John 5:14-15', 'Philippians 1:3-6', 'Psalm 116:1-2'],
     ['God answers prayers slowly, sometimes, and sideways. The slow and sideways answers are often the best ones.',
      'Remembering an answered prayer is one of the healthiest things a soul can do — it rewires us toward trust.'],
     ['Lord, thank You for the thing You gave us that we asked for, and the thing You gave us we did not know to ask for.',
      'God who hears and answers, we remember. We are still surprised by how good You have been.'],
     ['You could expect, today, to tell someone: "Remember when we prayed for that?" It will do both of you good.']),
]

THEME_BY_MODE = {
    'challenge':  CHALLENGE_THEMES,
    'grace':      GRACE_THEMES,
    'gratitude':  GRATITUDE_THEMES,
}

# ─── HELPERS ───────────────────────────────────────────────────────────────────
def _ua_headers(token=''):
    return {
        'Content-Type': 'application/json',
        'User-Agent':  'HEAL-daily-world/1.0 (https://heal.positiveness.club)',
        **({'Authorization': token} if token else {}),
    }

def http_post(url, body, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers=_ua_headers(token),
        method='POST',
    ), timeout=30)

def http_patch(url, body, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers=_ua_headers(token),
        method='PATCH',
    ), timeout=30)

def http_get(url, token=''):
    return urllib.request.urlopen(urllib.request.Request(
        url, headers=_ua_headers(token),
    ), timeout=20)

def pb_auth():
    r = http_post(f'{PB_URL}/api/collections/_superusers/auth-with-password',
                  {'identity': PB_IDENTITY, 'password': PB_PASSWORD})
    return json.loads(r.read())['token']

def load_used():
    if os.path.exists(USED_FILE):
        return set(json.load(open(USED_FILE)))
    return set()

def save_used(s):
    json.dump(sorted(s), open(USED_FILE, 'w'), indent=2)


# A pool of Bible verses we know by heart — we don't want to invent text.
SCRIPTURE_TEXTS = {
    'Psalm 25:16':       'Turn to me and be gracious to me, for I am lonely and afflicted.',
    'Isaiah 41:10':      'Fear not, for I am with you; be not dismayed, for I am your God.',
    'Matthew 11:28':     'Come to me, all you who are weary and heavy laden, and I will give you rest.',
    'Hebrews 13:5':      'I will never leave you nor forsake you.',
    'Psalm 34:18':       'The Lord is close to the brokenhearted and saves those who are crushed in spirit.',
    'Psalm 46:1':        'God is our refuge and strength, a very present help in trouble.',
    'Proverbs 3:24':     'When you lie down, you will not be afraid; when you rest, your sleep will be sweet.',
    'Isaiah 26:3':       'You will keep in perfect peace those whose minds are steadfast, because they trust in you.',
    'Romans 12:18':      'If it is possible, as far as it depends on you, live at peace with everyone.',
    'Psalm 4:8':         'In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety.',
    'Matthew 5:4':       'Blessed are those who mourn, for they will be comforted.',
    '2 Corinthians 1:3-4': 'The God of all comfort, who comforts us in all our troubles, so that we can comfort those in any trouble.',
    'Revelation 21:4':   'He will wipe every tear from their eyes. There will be no more death or mourning or crying or pain.',
    'Psalm 147:3':       'He heals the brokenhearted and binds up their wounds.',
    'Philippians 4:6-7': 'Do not be anxious about anything... and the peace of God, which transcends all understanding, will guard your hearts.',
    'Matthew 6:34':      'Do not worry about tomorrow, for tomorrow will worry about itself.',
    'Psalm 94:19':       'When anxiety was great within me, your consolation brought me joy.',
    '1 Peter 5:7':       'Cast all your anxiety on him because he cares for you.',
    'Ephesians 4:3':     'Make every effort to keep the unity of the Spirit through the bond of peace.',
    'Matthew 5:9':       'Blessed are the peacemakers, for they will be called children of God.',
    'Psalm 133:1':       'How good and pleasant it is when God\u2019s people live together in unity!',
    'Colossians 3:14':   'Over all these virtues put on love, which binds them all together in perfect unity.',
    'Psalm 139:7-10':    'Where can I go from your Spirit? ... if I rise on the wings of the dawn, you are there.',
    '1 Corinthians 13:8': 'Love never fails.',
    'Romans 8:38-39':    'Neither death nor life... will be able to separate us from the love of God.',
    'Deuteronomy 31:6':  'Be strong and courageous. The Lord your God goes with you; he will never leave you.',
    'Galatians 6:9':     'Let us not become weary in doing good, for at the proper time we will reap a harvest.',
    'James 1:2-4':       'Consider it pure joy whenever you face trials... the testing of your faith produces perseverance.',
    'Romans 5:3-4':      'We also glory in our sufferings, because suffering produces perseverance; perseverance, character; and character, hope.',
    'Psalm 27:14':       'Wait for the Lord; be strong and take heart and wait for the Lord.',
    'Habakkuk 2:3':      'The vision awaits its appointed time... it will not be late. Wait for it.',
    'Lamentations 3:25-26': 'The Lord is good to those whose hope is in him, to the one who seeks him; it is good to wait quietly.',
    'Galatians 6:9-10': 'Let us not become weary in doing good... As we have opportunity, let us do good to all people.',
    'Hebrews 13:2':      'Do not forget to show hospitality to strangers, for by so doing some people have shown hospitality to angels.',
    'Colossians 3:12':   'Clothe yourselves with compassion, kindness, humility, gentleness and patience.',
    '1 John 4:7':         'Dear friends, let us love one another, for love comes from God.',
    'Matthew 25:40':     'Whatever you did for one of the least of these brothers and sisters of mine, you did for me.',
    'Matthew 18:3':      'Truly I tell you, unless you change and become like little children, you will never enter the kingdom of heaven.',
    'Mark 10:14-15':     'Let the little children come to me, and do not hinder them, for the kingdom of God belongs to such as these.',
    'Psalm 8:2':         'Through the praise of children and infants you have established a stronghold.',
    'Luke 18:16':        'Jesus called the children to him and said, "Let the little children come to me."',
    'Psalm 19:1-4':      'The heavens declare the glory of God; the skies proclaim the work of his hands.',
    'Lamentations 3:22-23': 'Because of the Lord\u2019s great love we are not consumed; his compassions never fail. They are new every morning.',
    'Genesis 1:3-5':     'Let there be light, and there was light. God saw that the light was good.',
    'Psalm 30:5':       'Weeping may endure for a night, but joy comes in the morning.',
    '2 Corinthians 4:6': 'God, who said "Let light shine out of darkness," made his light shine in our hearts.',
    '1 Corinthians 13:4-7': 'Love is patient, love is kind. It does not envy, it does not boast, it is not proud.',
    'Ephesians 4:2':     'Be completely humble and gentle; be patient, bearing with one another in love.',
    'Proverbs 17:1':     'Better a dry crust with peace than a house full of feasting, with strife.',
    'Galatians 6:2':     'Carry each other\u2019s burdens, and in this way you will fulfill the law of Christ.',
    'Psalm 145:15':      'The eyes of all look to you, and you give them their food at the proper time.',
    'Matthew 6:11':      'Give us today our daily bread.',
    'John 6:11':         'Jesus took the loaves, gave thanks, and distributed to those who were seated as much as they wanted.',
    'Acts 2:46':         'They broke bread in their homes and ate together with glad and sincere hearts.',
    '1 Timothy 4:4-5':   'Everything God created is good, and nothing is to be rejected if it is received with thanksgiving.',
    'Ecclesiastes 3:11': 'He has made everything beautiful in its time.',
    'Psalm 27:4':        'One thing I ask from the Lord... to gaze on the beauty of the Lord.',
    'Song of Songs 2:1': 'I am a rose of Sharon, a lily of the valleys.',
    'Isaiah 35:1-2':     'The desert and the parched land will be glad; the wilderness will rejoice and blossom.',
    '1 Peter 3:3-4':     'Your beauty should not come from outward adornment... rather, it should be that of your inner self.',
    'Psalm 139:13-14':   'For you created my inmost being; you knit me together in my mother\u2019s womb. I praise you.',
    'Job 33:4':          'The Spirit of God has made me; the breath of the Almighty gives me life.',
    'Genesis 2:7':       'The Lord God formed the man from the dust of the ground and breathed into his nostrils the breath of life.',
    '2 Corinthians 5:1-4': 'For we know that if the earthly tent we live in is destroyed, we have a building from God.',
    'Psalm 4:8':         'In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety.',
    'Psalm 91:1-2':      'Whoever dwells in the shelter of the Most High will rest in the shadow of the Almighty.',
    'Proverbs 30:8-9':   'Give me neither poverty nor riches, but give me only my daily bread.',
    'Matthew 6:26':      'Look at the birds of the air; they do not sow or reap or store away in barns, yet your heavenly Father feeds them.',
    'Hebrews 13:5':      'Keep your lives free from the love of money and be content with what you have.',
    'Proverbs 17:17':    'A friend loves at all times, and a brother is born for a time of adversity.',
    '1 Samuel 18:3':     'Jonathan and David made a covenant, because he loved him as his own soul.',
    'John 15:13':        'Greater love has no one than this: to lay down one\u2019s life for one\u2019s friends.',
    'Ecclesiastes 4:9-10': 'Two are better than one... if either of them falls down, one can help the other up.',
    '1 Thessalonians 5:11': 'Encourage one another and build each other up.',
    '1 Timothy 4:4-5':   'Everything God created is good, and nothing is to be rejected if it is received with thanksgiving.',
    'Matthew 14:19-20':  'Jesus directed the people to sit down... and they all ate and were satisfied.',
    'Deuteronomy 8:10':  'When you have eaten and are satisfied, praise the Lord your God for the good land he has given you.',
    'Lamentations 3:22-23': 'Because of the Lord\u2019s great love we are not consumed; his compassions never fail.',
    'Psalm 118:24':      'This is the day the Lord has made; let us rejoice and be glad in it.',
    'Psalm 30:5':        'Weeping may endure for a night, but joy comes in the morning.',
    '2 Corinthians 4:16': 'Though outwardly we are wasting away, yet inwardly we are being renewed day by day.',
    'James 1:17':        'Every good and perfect gift is from above, coming down from the Father of the heavenly lights.',
    'Psalm 103:1-4':     'Praise the Lord, my soul... who heals all your diseases and redeems your life from the pit.',
    'Ephesians 2:4-5':   'Because of his great love for us, God, who is rich in mercy, made us alive with Christ.',
    'Titus 3:4-7':       'When the kindness and love of God our Savior appeared, he saved us.',
    'Romans 8:28':       'In all things God works for the good of those who love him.',
    'Isaiah 30:18':      'Yet the Lord longs to be gracious to you; therefore he will rise up to show you compassion.',
    'Psalm 98:1':        'Sing to the Lord a new song, for he has done marvelous things.',
    'Ephesians 5:19':    'Speak to one another with psalms, hymns, and spiritual songs.',
    'Colossians 3:16':    'Let the word of Christ dwell in you richly... singing to God with gratitude in your hearts.',
    'Psalm 13:6':        'I will sing the Lord\u2019s praise, for he has been good to me.',
    'Psalm 96:1':        'Sing to the Lord a new song; sing to the Lord, all the earth.',
    'Psalm 66:20':       'Praise be to God, who has not rejected my prayer or withheld his love from me!',
    'James 5:16':        'The prayer of a righteous person is powerful and effective.',
    '1 John 5:14-15':    'If we ask anything according to his will, he hears us.',
    'Philippians 1:3-6': 'He who began a good work in you will carry it on to completion.',
    'Psalm 116:1-2':     'I love the Lord, for he heard my voice; he heard my cry for mercy.',
}


def build_record():
    themes = THEME_BY_MODE[MODE]
    # Pick a theme not used in the last 14 days
    used = load_used()
    pool = [(label, t, s, r, p, e) for label, t, s, r, p, e in themes
            if f'{MODE}:{label}' not in used]
    if not pool:
        pool = themes  # all used — recycle
    chosen = random.choice(pool)
    theme_label, prompt, scripture_pool, reflection_pool, prayer_pool, expectation_pool = chosen

    # Pick one scripture from pool that we have the text for
    available = [s for s in scripture_pool if s in SCRIPTURE_TEXTS]
    if not available:
        # fallback to a generic one
        available = ['Psalm 23:1', 'Matthew 11:28']
    scripture_ref = random.choice(available)
    scripture_text = SCRIPTURE_TEXTS[scripture_ref]

    reflection  = random.choice(reflection_pool)
    prayer      = random.choice(prayer_pool)
    expectation = random.choice(expectation_pool)

    # Title depends on mode
    if MODE == 'challenge':
        title = f'For {theme_label}'
    elif MODE == 'grace':
        title = f'For {theme_label}'
    else:  # gratitude
        title = f'For {theme_label}'

    # Update used
    used.add(f'{MODE}:{theme_label}')
    save_used(used)

    return {
        'slug':         SLUG,
        'title':        title,
        'prompt':       prompt,
        'prompt_kind':  MODE,
        'tone':         random.choice(['tender','honest','awestruck','hopeful','rejoicing','steady']),
        'scripture_ref':  scripture_ref,
        'scripture_text': scripture_text,
        'prayer':       prayer,
        'reflection':   reflection,
        'expectation':  expectation,
        'tags':         [MODE, 'daily', f'doy-{DAY_OF_YEAR}'],
        'illustration_url': '',  # no illustration yet; user can add later
        'day_of_year':  DAY_OF_YEAR,
        'is_published': True,
        'published_at': TODAY.isoformat() + 'T00:00:00.000Z',
    }


def already_exists(token):
    url = f'{PB_URL}/api/collections/HEAL_world/records?perPage=1&filter=slug%3D"{SLUG}"'
    try:
        r = http_get(url, token)
        data = json.loads(r.read())
        return len(data.get('items', [])) > 0
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False
        raise


def upsert(record, token):
    # Check by slug
    list_url = f'{PB_URL}/api/collections/HEAL_world/records?perPage=1&filter=slug%3D"{record["slug"]}"'
    r = http_get(list_url, token)
    items = json.loads(r.read()).get('items', [])
    if items:
        rid = items[0]['id']
        http_patch(f'{PB_URL}/api/collections/HEAL_world/records/{rid}', record, token)
        print(f"[daily-world] updated existing record {rid}")
        return 'updated'
    else:
        http_post(f'{PB_URL}/api/collections/HEAL_world/records', record, token)
        print(f"[daily-world] created new record {record['slug']}")
        return 'created'


def main():
    if not PB_IDENTITY or not PB_PASSWORD:
        print("[daily-world] FATAL: PB_IDENTITY/PB_PASSWORD env vars not set", file=sys.stderr)
        sys.exit(1)
    token = pb_auth()
    if already_exists(token):
        print(f"[daily-world] record for {SLUG} already exists, skipping (idempotent)")
        return
    record = build_record()
    print('--- record preview ---')
    print(json.dumps(record, indent=2, ensure_ascii=False))
    action = upsert(record, token)
    print(f"[daily-world] {action} {record['slug']}")


if __name__ == '__main__':
    main()
