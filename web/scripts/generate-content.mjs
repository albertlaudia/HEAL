#!/usr/bin/env node
/**
 * HEAL — Content generation driver
 * ─────────────────────────────────
 * 1. Generate 30 meditation JSON records (curated, hand-tuned — not LLM,
 *    to lock in the calm reverent voice from day one)
 * 2. Generate 60 quote/motivation records (one batch file)
 * 3. Generate 20 prayer records
 * 4. Generate 3 essay records
 *
 * Output: /content/{meditations,quotes,prayers,essays}/*.json
 * After running, the next steps are:
 *   pnpm content:seed          # → PB
 *   pnpm media:upload          # → B2
 *   scripts/illustrate-batch   # → /content/meditations/illustration-*.png
 *   scripts/audio-batch        # → /content/meditations/audio-*.mp3
 */
import { mkdir, writeFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', 'content');

const meditations = [
  // 30 launch meditations — short, reverent, scripture-anchored
  { day_of_year: 1, title: 'Begin Again', theme: 'stillness', season: 'ordinary',
    scripture_ref: 'Lamentations 3:22-23', translation: 'NRSV',
    scripture_text: "The steadfast love of the Lord never ceases, his mercies never come to an end; they are new every morning; great is your faithfulness.",
    reflection: "You do not have to carry yesterday into today. Each morning is a small mercy, handed to you without you having earned it. Begin again.",
    body: "Find a comfortable seat. Let the shoulders drop. Close the eyes, or soften the gaze.\n\nTake three slow breaths. In through the nose, out through the mouth. Let the exhale be longer than the inhale.\n\nNotice, without changing anything: the body sitting. The breath moving. The mind doing what minds do — wandering, returning, wandering, returning. This is normal. This is the practice.\n\nRead the words slowly. The steadfast love of the Lord never ceases. His mercies are new every morning. You are not behind. You are not failing. You are simply here, in a body, in a day, in the long kindness of God.\n\nPlace a hand on your chest if that feels right. Feel the warmth. That warmth is older than you are.\n\nWhen you're ready, open the eyes. Carry one word with you into the day. For me, the word is mercy. For you, it might be something else. Let it find you.",
    prayer: "Lord, let this day be enough. Let the mercy that is new this morning be enough for whatever comes. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 2, title: 'The Quiet Before', theme: 'calm', season: 'ordinary',
    scripture_ref: 'Psalm 46:10', translation: 'NRSV',
    scripture_text: "Be still, and know that I am God.",
    reflection: "Stillness is not the absence of noise. It is the presence of something more than noise. Today, see if you can let the noise pass through you, like wind through an open window.",
    body: "Sit. Hands open. Let the eyes close.\n\nTake one long, slow breath. Then another.\n\nImagine a quiet room. Not empty — quiet. The kind of room where, if you spoke, the words would land softly on the floor.\n\nInto this room, place whatever you are carrying. Do not analyze it. Do not try to fix it. Just let it sit in the room with you.\n\nThe Psalmist says: be still, and know. Stillness is not something you achieve. It is something you stop fighting. Stop fighting for thirty seconds. That's the whole practice.\n\nNotice: are you breathing shallow or deep? Soften the belly. Let the breath come all the way down.\n\nStay a little longer than feels comfortable. The discomfort is the point — it is the noise you are finally meeting.\n\nWhen you open the eyes, do so slowly. The room is still there. So are you.",
    prayer: "God of the quiet room, meet me here. Teach me that I do not have to fight for my worth today. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 3, title: 'The Long Exhale', theme: 'rest', season: 'ordinary',
    scripture_ref: 'Matthew 11:28', translation: 'NRSV',
    scripture_text: "Come to me, all you that are weary and are carrying heavy burdens, and I will give you rest.",
    reflection: "The body knows how to rest. It has been doing it your whole life. The mind sometimes forgets. The breath is a small, kind reminder.",
    body: "Sit or lie down. Whichever the body wants.\n\nBegin to lengthen the exhale. Inhale for four counts through the nose. Exhale for six or eight counts through the mouth, like a soft sigh.\n\nLet the body soften with each exhale — the jaw, the shoulders, the hands, the belly.\n\nThe invitation today is from Jesus, to the weary, to those carrying something heavy. He does not say fix yourself first. He does not say earn it. He says come.\n\nSo come. As you are. Tired, distracted, half-believing, half-hoping. Come.\n\nLet the breath keep lengthening. The nervous system is listening. It has been waiting for this signal — the signal that it is safe, now, to rest.\n\nStay with it for a few more rounds. Notice what softens. Notice what does not. Both are okay.\n\nWhen you are ready, sit up slowly. You have just given yourself a small, real gift.",
    prayer: "Tired Christ, meet me in the tiredness. Let the rest You offer be enough. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 4, title: 'Naming the Weight', theme: 'let-go', season: 'ordinary',
    scripture_ref: '1 Peter 5:7', translation: 'NRSV',
    scripture_text: "Cast all your anxiety on him, because he cares for you.",
    reflection: "Anxiety is the body holding a question it cannot answer. Naming the question is a kind of answer. Handing the question to God is another kind of answer.",
    body: "Sit. Hands resting.\n\nBegin to ask yourself, very gently: what am I carrying today? Not the big abstract things. The specific ones. The email you haven't answered. The conversation you're postponing. The small dread.\n\nLet a word or a phrase come. It doesn't have to be a complete sentence. It might be a single word — or a name, or a number, or a knot in the chest.\n\nNow — very gently — imagine placing that word in God's hands. Not throwing it. Placing it. The way you would place a tired child on a soft bed.\n\nRead the verse: cast all your anxiety on him, because he cares for you. The 'because' is important. The reason you can let go is not that you are strong, or that you've earned it, or that you've thought your way to peace. The reason is that He cares.\n\nLet the breath help. A long, slow exhale is the body saying: I am handing this over, just for now.\n\nSit a moment longer. Notice the hands. Are they tighter or looser than when you began?\n\nCarry the looseness with you.",
    prayer: "Father, I name the weight: [your word here]. I do not have the strength for it today. You do. Receive it. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 5, title: 'Gratitude, Named', theme: 'gratitude', season: 'ordinary',
    scripture_ref: 'Colossians 3:15', translation: 'NRSV',
    scripture_text: "Let the peace of Christ rule in your hearts, to which indeed you were called in the one body. And be thankful.",
    reflection: "Gratitude is not a feeling. It is a practice. The practice of noticing what was always there.",
    body: "Sit. Soften the body.\n\nTake three slow breaths.\n\nNow, gently, call to mind three small things from the last twenty-four hours. Not big things. Small. The taste of a drink. The way the light came in this morning. A text you received. A moment someone laughed.\n\nHold each one, gently, like a small stone in your palm. There is no rush. The mind wants to move on. Let it stay a little longer with the small thing.\n\nNotice — gratitude is not a feeling you have to manufacture. It is a way of seeing. You are not making something up. You are remembering what was always true.\n\nLet the verse settle in: let the peace of Christ rule in your hearts. And be thankful. The peace and the thanks are not two things. They are the same gesture, from two sides.\n\nOne more small thing. One more. Let it land.\n\nWhen you are ready, bow the head. A small bow, to the day. To the giver of the day.",
    prayer: "Lord, thank You for the small things I named. Thank You for the small things I cannot yet name. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 6, title: 'Held', theme: 'love', season: 'ordinary',
    scripture_ref: 'Romans 8:38-39', translation: 'NRSV',
    scripture_text: "For I am convinced that neither death, nor life, nor angels, nor rulers, nor things present, nor things to come, nor powers, nor height, nor depth, nor anything else in all creation, will be able to separate us from the love of God in Christ Jesus our Lord.",
    reflection: "Nothing has separated you yet. Nothing will. The love that holds you is older than your worst day.",
    body: "Sit. Hands open on the knees.\n\nBreathe in. Breathe out. The breath is a small liturgy.\n\nRead the verse slowly. Nor death, nor life. Nor angels, nor rulers. Nor things present, nor things to come. Nor height, nor depth. The list is exhaustive on purpose.\n\nThere is no category of experience the writer forgot. There is no version of your day, your year, your lifetime, that is outside the scope of this love.\n\nWhatever is on your mind right now — see if you can hold it inside this promise rather than the promise inside it. The promise is bigger. The promise is the room.\n\nLet the hands rest, open. Not grasping. Not pushing away. Open. The way a hand is open when it's not trying to hold anything.\n\nStay a moment longer. There is nowhere else to be. Nothing else to do. Just this — being held.\n\nWhen you're ready, gently close the hands. Carry the heldness with you.",
    prayer: "Lover of my soul, thank You that I am held even when I cannot feel it. Especially then. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 7, title: 'A Single Step', theme: 'courage', season: 'ordinary',
    scripture_ref: 'Joshua 1:9', translation: 'NRSV',
    scripture_text: "Be strong and courageous; do not be frightened or dismayed, for the Lord your God is with you wherever you go.",
    reflection: "Courage is rarely the big leap. It is the small, unglamorous next step, taken anyway.",
    body: "Sit. Notice the body. Notice the breath.\n\nBring to mind one thing you have been avoiding. Not the biggest thing. The next thing. The phone call. The email. The decision. The conversation you've been postponing.\n\nYou do not have to do it now. You are not being asked to do it now.\n\nBut see if you can name it. Just the name. Just the shape of it.\n\nNow — see if you can take one breath into the courage you would need for the smallest version of the next step. Not the whole thing. The smallest version. The first five minutes. The first sentence.\n\nThe verse today is not a command to be unafraid. It is a promise: you are not alone in the fear. The Lord your God is with you wherever you go — including the place you have been avoiding.\n\nLet the breath help. One breath for the fear. One breath for the next step. One breath for the promise.\n\nYou are not behind. You are not too late. The next step is enough. Today, the next step is enough.",
    prayer: "Courageous Christ, walk with me into the thing I have been avoiding. Just the next step. Just today. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 8, title: 'The Mind, Returning', theme: 'focus', season: 'ordinary',
    scripture_ref: 'Philippians 4:8', translation: 'NRSV',
    scripture_text: "Finally, beloved, whatever is true, whatever is honorable, whatever is just, whatever is pure, whatever is lovely, whatever is gracious, if there is any excellence and if there is anything worthy of praise, think about these things.",
    reflection: "The mind wanders a thousand times an hour. The practice is not to stop the wandering. The practice is the gentle return.",
    body: "Sit. Hands at rest.\n\nSet a timer for three minutes. For three minutes, your only job is to follow the breath.\n\nIn. Out. The mind will leave. It always does. Notice, without judgment, that it has left. Gently bring it back. Like calling a small child by name. Not harshly. Just: there you are.\n\nThe returning is the practice. There is no version of this where the mind behaves. There is only the version where you keep returning.\n\nWhen the timer ends, notice: you have just practiced the muscle that Paul is asking for. Whatever is true, whatever is lovely. The mind can be trained — not by force, but by gentle, repeated, patient return.\n\nThe breath is the training partner. Use it today whenever the mind goes somewhere you'd rather it didn't. One breath. One return. That's enough.\n\nCarry the practice out the door with you.",
    prayer: "Lord of the returning mind, meet me each time I come back. Especially then. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 9, title: 'The Green Pasture', theme: 'rest', season: 'ordinary',
    scripture_ref: 'Psalm 23:1-3', translation: 'NRSV',
    scripture_text: "The Lord is my shepherd, I shall not want. He makes me lie down in green pastures; he leads me beside still waters; he restores my soul.",
    reflection: "Sometimes the most spiritual act is to lie down. To be led. To stop producing.",
    body: "If you can, lie down. If not, sit with the eyes closed and imagine lying in a wide, soft place.\n\nThe Psalmist is not writing about a personality. He is writing about a posture. The posture of being led. Of not having to be the one in charge, just for now.\n\nHe makes me lie down. Notice — the shepherd does not ask. The sheep do not lie down on their own. They have to be led to a place where the body says: it is safe now. You can rest.\n\nWhere in your life is the shepherd trying to lead you to a green pasture, but you keep standing up? Where is the body being told: just lie down here, just for a moment?\n\nLet yourself be led. Let the breath be the still water. Drink slowly.\n\nHe restores my soul. Restoration is not a productivity hack. It is the slow, kind work of being brought back to yourself.\n\nStay a few more minutes. The pasture is not going anywhere. Neither is the shepherd.",
    prayer: "Good Shepherd, lead me to the still water. I will not argue today. I will lie down. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 10, title: 'The Quiet "Yes"', theme: 'stillness', season: 'ordinary',
    scripture_ref: '1 Samuel 3:10', translation: 'NRSV',
    scripture_text: "And the Lord came and stood there, calling as before, 'Samuel! Samuel!' And Samuel said, 'Speak, for your servant is listening.'",
    reflection: "The most spiritual word in the Bible is sometimes a small, quiet 'yes' — followed by listening.",
    body: "Sit. Hands open. Eyes closed.\n\nTake three slow breaths. Each exhale, a little longer than the inhale.\n\nNow — for a few moments — just listen. Not to the world. To whatever is underneath the world. To the small, still voice that has been there all along, underneath the noise.\n\nSamuel's answer is one of the most beautiful in all of scripture. Speak, for your servant is listening. He does not say: tell me what to do. He does not say: solve my problem. He says: I am here. I am listening. Use me.\n\nThat posture — open, listening, available — is the whole practice. You don't have to hear anything specific. You don't have to figure it out. You just have to be in the posture.\n\nWhat if today, every time you pause, you say that small sentence? Speak, Lord, for your servant is listening. Let it become a refrain. A breathing prayer.\n\nStay a few more minutes. Whatever you hear — a word, an image, a quiet — let it land softly.",
    prayer: "Speak, Lord. Your servant is listening. Even now. Especially now. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 11, title: 'Peace, Not as the World Gives', theme: 'calm', season: 'ordinary',
    scripture_ref: 'John 14:27', translation: 'NRSV',
    scripture_text: "Peace I leave with you; my peace I give to you. I do not give to you as the world gives. Do not let your hearts be troubled, and do not let them be afraid.",
    reflection: "The world's peace is the absence of trouble. Christ's peace is the presence of something stronger than trouble.",
    body: "Sit. Notice the body. Notice the breath.\n\nRead the verse slowly. Especially this part: I do not give to you as the world gives.\n\nThere is a different kind of peace being offered. Not the peace of everything going right. The peace of something going right inside you, even when nothing outside is going right.\n\nLet the breath become the prayer. In — I receive the peace. Out — I let go of the trouble.\n\nStay a few more minutes. The peace is patient.",
    prayer: "Prince of Peace, I receive Your peace today — the kind that does not depend on the day. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 12, title: 'Do Not Worry About Tomorrow', theme: 'calm', season: 'ordinary',
    scripture_ref: 'Matthew 6:34', translation: 'NRSV',
    scripture_text: "Do not worry about tomorrow, for tomorrow will bring worries of its own. Today's trouble is enough for today.",
    reflection: "Tomorrow is a country you have not yet visited. Worrying about it is the slowest form of travel.",
    body: "Sit. Hands resting. Shoulders soft.\n\nRead the verse once. Then again, more slowly. Today's trouble is enough for today.\n\nWorry is the mind doing laps. The body sitting still while the mind runs a marathon. Today, we step off the track.\n\nOne breath. In. Out. If a thought about tomorrow comes, see it, name it — that's a tomorrow thought — and gently return. You are not dismissing it. You are just letting it be a thought, not a tyrant.\n\nCarry this small practice out the door. The whole of today is enough.",
    prayer: "Lord of today, deliver me from the tyranny of tomorrow. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 13, title: 'Power in Weakness', theme: 'courage', season: 'ordinary',
    scripture_ref: '2 Corinthians 12:9', translation: 'NRSV',
    scripture_text: "My grace is sufficient for you, for power is made perfect in weakness.",
    reflection: "Weakness is not the opposite of grace. Weakness is the place where grace has room to land.",
    body: "Sit. Notice where the body feels tired today. Do not try to fix it. Just notice.\n\nRead the verse slowly. Power is made perfect in weakness. Not in spite of weakness. Through it.\n\nThe world's logic says: get stronger, then you can do the thing. The gospel's logic says: be honest about the weakness, and see what shows up.\n\nThis is the most counter-intuitive form of courage: the courage to say, today, I cannot do this alone. The courage to be small.\n\nLet the breath soften. Let the shoulders drop. The grace does not arrive after the weakness is gone. The grace arrives now.",
    prayer: "Lord, let my weakness be the doorway through which Your grace enters. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 14, title: 'Kindness, First', theme: 'love', season: 'ordinary',
    scripture_ref: 'Ephesians 4:32', translation: 'NRSV',
    scripture_text: "Be kind to one another, tenderhearted, forgiving one another, as God in Christ forgave you.",
    reflection: "Kindness is rarely loud. It is the small, soft gesture that the loud world does not even notice.",
    body: "Sit. Hands open. Soften the face.\n\nRead the verse slowly. Be kind. Tenderhearted. Forgiving. As God in Christ forgave you.\n\nNotice the structure: it does not say, be kind when they deserve it. Be kind — the way you have been forgiven.\n\nSo kindness is not a strategy. It is a memory. The memory of being forgiven, of being received, of being loved without having earned it.\n\nYou will meet people today. Strangers, perhaps. Be kind to them — not because they have earned it, but because you have been shown a kindness that does not run out.",
    prayer: "Lord, let me be kind today, even in the small ways. Especially in the small ways. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 15, title: 'Near to the Brokenhearted', theme: 'hope', season: 'ordinary',
    scripture_ref: 'Psalm 34:18', translation: 'NRSV',
    scripture_text: "The Lord is near to the brokenhearted, and saves the crushed in spirit.",
    reflection: "If you are broken today, this verse is for you. Especially then, the Lord is near.",
    body: "Sit, or lie down. Whichever the body wants.\n\nIf today is a hard day, do not try to be brave. Let the body feel what it feels. Let the tears come if they come.\n\nThe verse does not promise you will not be broken. It promises the Lord is near to the broken. Near. Not solving. Not fixing. Near.\n\nImagine someone sitting next to you. Not saying anything. Just sitting. That is the image.\n\nPlace a hand on your chest. Feel the heartbeat. That is the Lord's nearness, in pulse form.\n\nStay as long as you need.",
    prayer: "Lord, I am broken today. Meet me here. Be near. That is enough. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 16, title: 'Trust, Not Sight', theme: 'wisdom', season: 'ordinary',
    scripture_ref: 'Proverbs 3:5-6', translation: 'NRSV',
    scripture_text: "Trust in the Lord with all your heart, and do not rely on your own insight. In all your ways acknowledge him, and he will make straight your paths.",
    reflection: "Trust is the muscle that atrophies fastest in a noisy world. Today, we stretch it gently.",
    body: "Sit. Hands at rest.\n\nRead the verse. Trust in the Lord with all your heart. Not with the part of you that has it all figured out. With all of it — including the part that is confused, the part that doubts.\n\nDo not rely on your own insight. The verse is not anti-thinking. It is just saying: thinking is not enough. There is something older, deeper, more reliable than your own reasoning.\n\nLet the breath be the place where you stop trying to figure it out. In. Out. The breath does not plan. The breath just arrives, and is enough.",
    prayer: "Lord, I do not have the answers today. Help me to trust the One who does. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 17, title: 'A Gift, Not a Wage', theme: 'grace', season: 'ordinary',
    scripture_ref: 'Ephesians 2:8-9', translation: 'NRSV',
    scripture_text: "For by grace you have been saved through faith, and this is not your own doing; it is the gift of God.",
    reflection: "The most Christian thing in the world is that you cannot earn what you have already been given.",
    body: "Sit. Hands open.\n\nRead the verse slowly. It is the gift of God. Not the result of works.\n\nWhat would today look like if you stopped earning what has already been given? What would the next hour look like? The next decision?\n\nIf you are like most people, much of your day is a small, quiet performance. The verse is interrupting that performance. You are already enough. The gift has already been given. There is nothing to earn.\n\nLet the breath carry the relief. The body understands gifts better than the mind does.",
    prayer: "Lord, I receive. I do not earn. I do not perform. I receive. Thank You. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 18, title: 'A Renewed Mind', theme: 'focus', season: 'ordinary',
    scripture_ref: 'Romans 12:2', translation: 'NRSV',
    scripture_text: "Do not be conformed to this world, but be transformed by the renewing of your minds.",
    reflection: "The mind is not a thing to be mastered. It is a garden to be tended. Today, we just pull one small weed.",
    body: "Sit. Notice the mind. No judgment.\n\nThe mind is doing its mind thing — thinking, planning, rehearsing. This is what minds do. The verse is not asking you to stop the mind. It is asking you to give it a new shape.\n\nRenewing is slow. It is not a renovation. It is a slow, patient cultivation. The gardener does not rip out the weeds in anger. She pulls one, then another.\n\nToday, just notice one thought that has been returning uninvited. Do not argue with it. Just see it. See it as a thought, not a truth.\n\nThe breath is the place where thoughts are seen, not obeyed.",
    prayer: "Lord, renew my mind — one breath, one thought at a time. Be patient with me. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 19, title: 'Let the Peace Rule', theme: 'gratitude', season: 'ordinary',
    scripture_ref: 'Colossians 3:15', translation: 'NRSV',
    scripture_text: "Let the peace of Christ rule in your hearts. And be thankful.",
    reflection: "Gratitude is the atmosphere in which the peace of Christ can be felt.",
    body: "Sit. Hands open. Soften the face.\n\nRead the verse twice. Let the peace of Christ rule. Rule, not visit. Rule.\n\nWhat would it look like to let the peace rule — in the small decisions of the day? The decision to pause. The decision to look up instead of down.\n\nAnd: be thankful. The gratitude is not a separate step. It is the atmosphere in which the peace can be felt.\n\nNotice three small things you are thankful for, right now. The breath. The chair. The friend.",
    prayer: "Lord, thank You. Let the peace rule in me today. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 20, title: 'The Hand That Holds', theme: 'courage', season: 'ordinary',
    scripture_ref: 'Isaiah 41:10', translation: 'NRSV',
    scripture_text: "Do not fear, for I am with you. I will strengthen you, I will help you, I will uphold you with my victorious right hand.",
    reflection: "You do not have to be strong enough on your own. The hand is already there.",
    body: "Sit. Hands on the knees, palms up. Open.\n\nRead the verse, very slowly. I will strengthen you. I will help you. I will uphold you. Notice the threefold promise.\n\nIf you are afraid today — of something specific, or something vague, or something you cannot name — the verse is not asking you to stop being afraid. It is asking you to notice who is with you in the fear.\n\nImagine a hand. Not yours. A larger, older hand, holding yours. It does not have to be visible. The hand is there.\n\nWhen you stand up, take the hand with you.",
    prayer: "Lord, I am afraid. Be with me in the fear. I do not have to be unafraid. I only have to be held. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 21, title: 'Quietness and Trust', theme: 'rest', season: 'ordinary',
    scripture_ref: 'Isaiah 30:15', translation: 'NRSV',
    scripture_text: "In returning and rest you shall be saved; in quietness and in trust shall be your strength.",
    reflection: "Strength is often a quieter thing than we were taught. It is sometimes just the willingness to stop.",
    body: "Sit. Or lie down. Whatever the body needs.\n\nRead the verse twice. In returning and rest. In quietness and in trust.\n\nThe verse is not asking you to be loud in your faith. It is asking you to be still in it. To let the strength come from somewhere other than your own effort.\n\nNotice how much of your day is a kind of striving. A doing. A making-it-happen. The verse is offering a different way: in returning, in rest, in quietness, in trust.\n\nLet the breath slow. Let the body remember that strength is not always in the muscles. Sometimes it is in the willingness to be held.\n\nCarry this with you today. The quiet way. The trust way.",
    prayer: "Lord, teach me the strength of quietness today. Teach me to stop, and to trust. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 22, title: 'The Fruit, in Season', theme: 'love', season: 'ordinary',
    scripture_ref: 'Galatians 5:22-23', translation: 'NRSV',
    scripture_text: "The fruit of the Spirit is love, joy, peace, patience, kindness, generosity, faithfulness, gentleness, and self-control.",
    reflection: "Fruit does not grow on demand. It grows in season, slowly, in the dark of the soil. So do we.",
    body: "Sit. Hands open. Read the verse slowly.\n\nLove, joy, peace, patience, kindness, generosity, faithfulness, gentleness, self-control. Read each word as a small gift, not a demand.\n\nThese are not qualities you are required to produce. They are fruit. And fruit grows in its own time, in the right conditions.\n\nThe conditions are these: staying close to the Vine. Staying in the quiet. Letting the gardener do the pruning and the watering.\n\nWhich of these words is most needed today? Love, if you are tired. Patience, if you are frustrated. Kindness, if you are angry. Self-control, if you are overwhelmed.\n\nPick one. Carry it. The others will come in their season.",
    prayer: "Lord, make me a fruitful branch. Today, especially, grow in me the fruit I most need. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 23, title: 'I Can, Through Him', theme: 'strength', season: 'ordinary',
    scripture_ref: 'Philippians 4:13', translation: 'NRSV',
    scripture_text: "I can do all things through him who strengthens me.",
    reflection: "All things does not mean everything. It means the things you are actually being asked to do today. The next small thing.",
    body: "Sit. Notice the body.\n\nRead the verse. I can do all things through him who strengthens me.\n\nIt is tempting to read this as a superhero verse — the verse for accomplishing anything. But that is not what Paul meant. He was writing from prison, having lost almost everything. All things, for him, was the next small thing. The next letter. The next conversation. The next breath.\n\nToday, the verse is for the next small thing. Not the whole day. Not the whole life. The next small thing.\n\nLet the breath be the place where the strength arrives. In — I receive. Out — I let go.\n\nThe strength is not yours. It is the One who strengthens. The verse does not say I am strong. It says I can do all things through him who strengthens me.\n\nCarry that distinction with you today. You are not the source. You are the channel.",
    prayer: "Lord, give me strength for the next small thing. The rest is in Your hands. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 24, title: 'Joy Comes in the Morning', theme: 'hope', season: 'ordinary',
    scripture_ref: 'Psalm 30:5', translation: 'NRSV',
    scripture_text: "Weeping may linger for the night, but joy comes with the morning.",
    reflection: "If it is night now, morning is coming. If it is morning, you have already been carried through.",
    body: "Sit. Let the body feel what it feels.\n\nRead the verse. Weeping may linger for the night, but joy comes with the morning.\n\nThe verse is not dismissing the night. It is not saying cheer up. It is saying: the night is real, and the morning is coming.\n\nWhere are you today? In the night? In the morning? Somewhere in between?\n\nIf you are in the night, hear this: the morning is not your job. You do not have to make the morning come. The morning is promised. Your only job tonight is to not give up on the dawn.\n\nIf you are in the morning, give thanks. The night passed. You are still here. That is the joy.\n\nEither way, sit. Breathe. The verse is true. Morning is on its way.",
    prayer: "Lord of morning, meet me in the night. Carry me until the dawn. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 25, title: 'A Very Present Help', theme: 'courage', season: 'ordinary',
    scripture_ref: 'Psalm 46:1', translation: 'NRSV',
    scripture_text: "God is our refuge and strength, a very present help in trouble.",
    reflection: "Not a distant help. A very present help. The kind that is here, right now, before you have even asked.",
    body: "Sit. Hands on the chest, if that feels right.\n\nRead the verse. God is our refuge and strength, a very present help in trouble.\n\nVery present. Not eventually present. Not after you have sorted yourself out. Present. Right now. In the trouble, not after it.\n\nWhat is the trouble today? Name it, if you can. Just a word. Just a shape. The verse does not promise the trouble will go away. It promises Someone is in it with you.\n\nRefuge is not escape. Refuge is a place to stand, a place to breathe, while the trouble moves around you.\n\nLet the breath help. In: I am not alone. Out: I do not have to do this alone.\n\nStay a few more minutes. The help is very present. It is not going anywhere.",
    prayer: "Lord, be my refuge today. I will stand here, with You, in the trouble. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 26, title: 'Where Two or Three', theme: 'love', season: 'ordinary',
    scripture_ref: 'Matthew 18:20', translation: 'NRSV',
    scripture_text: "Where two or three are gathered in my name, I am there among them.",
    reflection: "Even the smallest gathering — two, three — is a temple. The presence is not waiting for a crowd.",
    body: "Sit. Hands open. Read the verse slowly.\n\nWhere two or three are gathered in my name, I am there among them.\n\nThe verse is a quiet revolution. It says: you do not need a cathedral. You do not need a stadium. You do not need a perfect congregation. Two or three. That is the threshold.\n\nWho are the two or three in your life today? The friend you are going to call. The person you are going to sit with. Even the stranger you are going to smile at — you are gathering.\n\nYou do not have to do this alone. That is the whole invitation.\n\nLet the breath be a small gathering. In: the One. Out: you. The One and you. The two. The temple.\n\nCarry this with you. The presence is in the small gathering, not the large crowd.",
    prayer: "Lord, thank You for being in the small things. In the two, in the three. In me. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 27, title: 'The Face That Shines', theme: 'gratitude', season: 'ordinary',
    scripture_ref: 'Numbers 6:24-25', translation: 'NRSV',
    scripture_text: "The Lord bless you and keep you; the Lord make his face to shine upon you, and be gracious to you.",
    reflection: "Some blessings are old. Some are older than the morning. Let them find you today.",
    body: "Sit. Hands on the knees, palms up. Open.\n\nRead the verse slowly. The Lord bless you and keep you. The Lord make his face to shine upon you. Be gracious to you.\n\nThis is one of the oldest blessings in the world. Older than the morning, older than you, older than your worry.\n\nThe verse is a small window into how you are seen. Not as a project to be fixed. Not as a problem to be solved. As someone upon whom a face is shining. With grace. With kindness. With the long, slow tenderness of the One who made you.\n\nLet that be the truth underneath all the other truths today. Beneath the work, beneath the family, beneath the noise, beneath the small daily failures: a face is shining upon you. With grace.\n\nStay a few more minutes. The face is not going anywhere. Let it find you.",
    prayer: "Lord, let Your face shine upon me. I receive the blessing, old as it is, true as it is. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 28, title: 'The Light of the World', theme: 'courage', season: 'ordinary',
    scripture_ref: 'Matthew 5:14', translation: 'NRSV',
    scripture_text: "You are the light of the world. A city built on a hill cannot be hid.",
    reflection: "You do not have to make yourself shine. You only have to stop hiding.",
    body: "Sit. Hands at rest. Notice the breath.\n\nRead the verse. You are the light of the world.\n\nThe verse is not a demand to be brighter. It is a recognition. The light is already there. The verse is not asking you to generate the light. It is asking you to stop covering it up.\n\nWhat covers your light today? The fear of being seen. The fear of being wrong. The small, daily habits of hiding. The verse is asking, gently, to put those down.\n\nLet the breath be the place where the covering thins. In: I am the light. Out: I do not have to hide it.\n\nYou are not the source of the light. You are the window. The light is on the other side. Your only job is to stay clean enough to let it through.\n\nCarry this with you. The light is not yours to generate. It is yours to reveal.",
    prayer: "Lord, let Your light come through me today. I will stop hiding it. Amen.",
    duration_seconds: 240, launch_batch: 'B1' },

  { day_of_year: 29, title: 'Everlasting Love', theme: 'love', season: 'ordinary',
    scripture_ref: 'Jeremiah 31:3', translation: 'NRSV',
    scripture_text: "I have loved you with an everlasting love; I have drawn you with loving-kindness.",
    reflection: "Everlasting means before. Before your doubt, before your failure, before the morning.",
    body: "Sit. Hands on the chest. Eyes closed.\n\nRead the verse, very slowly. I have loved you with an everlasting love.\n\nEverlasting. The love is not new. It is not contingent on your performance. It is not a reward for getting it right. It is older than your doubt, older than your failure, older than the morning.\n\nI have drawn you. Not pushed. Not demanded. Drawn. The way the sun draws a flower. The way the tide draws the shore. Slowly. Gently. Without force.\n\nYou are not being chased. You are being drawn. There is a difference. The chase makes you run. The drawing lets you be still, and come toward.\n\nLet the breath be the drawing. In: the love that is everlasting. Out: the resistance, let it go.\n\nStay a few more minutes. The drawing is not finished. The love is not finished. They are still in motion.",
    prayer: "Lord, I receive the everlasting love. I stop running. I let myself be drawn. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },

  { day_of_year: 30, title: 'My Light, My Salvation', theme: 'courage', season: 'ordinary',
    scripture_ref: 'Psalm 27:1', translation: 'NRSV',
    scripture_text: "The Lord is my light and my salvation; whom shall I fear? The Lord is the stronghold of my life; of whom shall I be afraid?",
    reflection: "The question is rhetorical. The answer is no one. The One who is your light is bigger than the fear.",
    body: "Sit. Hands at rest. Read the verse. Twice.\n\nThe Lord is my light and my salvation. Whom shall I fear?\n\nThe Lord is the stronghold of my life. Of whom shall I be afraid?\n\nNotice the questions. They are not really questions. They are answers, looking for the agreement of your heart. Of whom shall I be afraid. The answer the verse expects is: no one. Of no one.\n\nNot because there is nothing to be afraid of. There is. But because the One who is your light is bigger than the fear.\n\nLet the breath be the place where the answer lands. In: the Lord is my light. Out: whom shall I fear?\n\nYou are not the source of the courage. The One who is your light is the source. The courage is borrowed. The fear is real. The borrowed courage is bigger.\n\nCarry this with you today. Whom shall I fear. The answer is no one.",
    prayer: "Lord, You are my light. The fear is real, but You are bigger. I will not be afraid today. Amen.",
    duration_seconds: 300, launch_batch: 'B1' },
];

const quotes = [
  { text: "Be still, and know that I am God.", attribution: "Psalm 46:10", category: "stillness", is_motivation: true, day_of_year: 1 },
  { text: "The Lord is my shepherd, I shall not want.", attribution: "Psalm 23:1", category: "rest", is_motivation: true, day_of_year: 2 },
  { text: "Come to me, all you that are weary, and I will give you rest.", attribution: "Matthew 11:28", category: "rest", is_motivation: true, day_of_year: 3 },
  { text: "Cast all your anxiety on him, because he cares for you.", attribution: "1 Peter 5:7", category: "let-go", is_motivation: true, day_of_year: 4 },
  { text: "The steadfast love of the Lord never ceases; his mercies are new every morning.", attribution: "Lamentations 3:22-23", category: "gratitude", is_motivation: true, day_of_year: 5 },
  { text: "Nothing will be able to separate us from the love of God.", attribution: "Romans 8:39", category: "love", is_motivation: true, day_of_year: 6 },
  { text: "Be strong and courageous; do not be frightened, for the Lord your God is with you wherever you go.", attribution: "Joshua 1:9", category: "courage", is_motivation: true, day_of_year: 7 },
  { text: "Whatever is true, whatever is lovely, whatever is gracious — think about these things.", attribution: "Philippians 4:8", category: "focus", is_motivation: true, day_of_year: 8 },
  { text: "He restores my soul. He leads me in paths of righteousness for his name's sake.", attribution: "Psalm 23:3", category: "rest", is_motivation: true, day_of_year: 9 },
  { text: "Speak, Lord, for your servant is listening.", attribution: "1 Samuel 3:9", category: "stillness", is_motivation: true, day_of_year: 10 },
  { text: "Peace I leave with you; my peace I give to you.", attribution: "John 14:27", category: "calm", is_motivation: true, day_of_year: 11 },
  { text: "Do not worry about tomorrow, for tomorrow will bring worries of its own.", attribution: "Matthew 6:34", category: "calm", is_motivation: true, day_of_year: 12 },
  { text: "My grace is sufficient for you, for power is made perfect in weakness.", attribution: "2 Corinthians 12:9", category: "courage", is_motivation: true, day_of_year: 13 },
  { text: "Be kind to one another, tenderhearted, forgiving one another, as God in Christ forgave you.", attribution: "Ephesians 4:32", category: "love", is_motivation: true, day_of_year: 14 },
  { text: "The Lord is near to the brokenhearted, and saves the crushed in spirit.", attribution: "Psalm 34:18", category: "hope", is_motivation: true, day_of_year: 15 },
  { text: "Trust in the Lord with all your heart, and do not rely on your own insight.", attribution: "Proverbs 3:5", category: "wisdom", is_motivation: true, day_of_year: 16 },
  { text: "For by grace you have been saved through faith, and this is not your own doing; it is the gift of God.", attribution: "Ephesians 2:8-9", category: "grace", is_motivation: true, day_of_year: 17 },
  { text: "Do not be conformed to this world, but be transformed by the renewing of your minds.", attribution: "Romans 12:2", category: "wisdom", is_motivation: true, day_of_year: 18 },
  { text: "Let the peace of Christ rule in your hearts. And be thankful.", attribution: "Colossians 3:15", category: "gratitude", is_motivation: true, day_of_year: 19 },
  { text: "Do not fear, for I am with you; I will strengthen you, I will help you.", attribution: "Isaiah 41:10", category: "courage", is_motivation: true, day_of_year: 20 },
  { text: "In returning and rest you shall be saved; in quietness and in trust shall be your strength.", attribution: "Isaiah 30:15", category: "rest", is_motivation: true, day_of_year: 21 },
  { text: "The fruit of the Spirit is love, joy, peace, patience, kindness, generosity, faithfulness, gentleness, self-control.", attribution: "Galatians 5:22-23", category: "love", is_motivation: true, day_of_year: 22 },
  { text: "I can do all things through him who strengthens me.", attribution: "Philippians 4:13", category: "strength", is_motivation: true, day_of_year: 23 },
  { text: "Weeping may linger for the night, but joy comes with the morning.", attribution: "Psalm 30:5", category: "hope", is_motivation: true, day_of_year: 24 },
  { text: "God is our refuge and strength, a very present help in trouble.", attribution: "Psalm 46:1", category: "courage", is_motivation: true, day_of_year: 25 },
  { text: "Where two or three are gathered in my name, I am there among them.", attribution: "Matthew 18:20", category: "love", is_motivation: true, day_of_year: 26 },
  { text: "The Lord bless you and keep you; the Lord make his face to shine upon you.", attribution: "Numbers 6:24-25", category: "gratitude", is_motivation: true, day_of_year: 27 },
  { text: "You are the light of the world. A city built on a hill cannot be hid.", attribution: "Matthew 5:14", category: "courage", is_motivation: true, day_of_year: 28 },
  { text: "I have loved you with an everlasting love; I have drawn you with loving-kindness.", attribution: "Jeremiah 31:3", category: "love", is_motivation: true, day_of_year: 29 },
  { text: "The Lord is my light and my salvation; whom shall I fear?", attribution: "Psalm 27:1", category: "courage", is_motivation: true, day_of_year: 30 },
  { text: "Be patient, therefore, beloved, until the coming of the Lord.", attribution: "James 5:7", category: "rest", is_motivation: true, day_of_year: 31 },
  { text: "Set your minds on things that are above, not on things that are on the earth.", attribution: "Colossians 3:2", category: "focus", is_motivation: true, day_of_year: 32 },
  { text: "If any of you is lacking in wisdom, ask God, who gives to all generously and ungrudgingly.", attribution: "James 1:5", category: "wisdom", is_motivation: true, day_of_year: 33 },
  { text: "Draw near to God, and he will draw near to you.", attribution: "James 4:8", category: "stillness", is_motivation: true, day_of_year: 34 },
  { text: "Every good and perfect gift is from above, coming down from the Father of lights.", attribution: "James 1:17", category: "gratitude", is_motivation: true, day_of_year: 35 },
  { text: "The Lord is compassionate and merciful, slow to anger and abounding in steadfast love.", attribution: "Psalm 103:8", category: "love", is_motivation: true, day_of_year: 36 },
  { text: "Wait for the Lord; be strong, and let your heart take courage.", attribution: "Psalm 27:14", category: "courage", is_motivation: true, day_of_year: 37 },
  { text: "Delight yourself in the Lord, and he will give you the desires of your heart.", attribution: "Psalm 37:4", category: "gratitude", is_motivation: true, day_of_year: 38 },
  { text: "Blessed are the pure in heart, for they will see God.", attribution: "Matthew 5:8", category: "stillness", is_motivation: true, day_of_year: 39 },
  { text: "The Lord is close to all who call on him, to all who call on him in truth.", attribution: "Psalm 145:18", category: "stillness", is_motivation: true, day_of_year: 40 },
  // Non-scripture motivation words (secular, more accessible)
  { text: "You do not have to figure it all out today. You only have to take the next kind step.", attribution: "HEAL", category: "calm", is_motivation: true, day_of_year: 41 },
  { text: "Stillness is not the absence of motion. It is the presence of something more than motion.", attribution: "HEAL", category: "stillness", is_motivation: true, day_of_year: 42 },
  { text: "The breath is the oldest prayer. It costs nothing. It requires no belief. It is always with you.", attribution: "HEAL", category: "calm", is_motivation: true, day_of_year: 43 },
  { text: "You are allowed to be a work in progress and a good person at the same time.", attribution: "HEAL", category: "grace", is_motivation: true, day_of_year: 44 },
  { text: "Rest is not a reward for the work. It is the foundation of the work.", attribution: "HEAL", category: "rest", is_motivation: true, day_of_year: 45 },
  { text: "What you pay attention to grows. Today, pay attention to mercy.", attribution: "HEAL", category: "focus", is_motivation: true, day_of_year: 46 },
  { text: "The most spiritual act is sometimes to sit down and stop.", attribution: "HEAL", category: "rest", is_motivation: true, day_of_year: 47 },
  { text: "Forgiveness is something you do for yourself, not for them.", attribution: "HEAL", category: "let-go", is_motivation: true, day_of_year: 48 },
  { text: "Courage is a small, quiet decision, made again and again.", attribution: "HEAL", category: "courage", is_motivation: true, day_of_year: 49 },
  { text: "Gratitude is not a feeling. It is a way of seeing.", attribution: "HEAL", category: "gratitude", is_motivation: true, day_of_year: 50 },
  { text: "You are not your worst day. You are not your loudest thought.", attribution: "HEAL", category: "grace", is_motivation: true, day_of_year: 51 },
  { text: "Let the next hour be small. Small is enough.", attribution: "HEAL", category: "calm", is_motivation: true, day_of_year: 52 },
  { text: "Hope is the practice of imagining a future you cannot yet see.", attribution: "HEAL", category: "hope", is_motivation: true, day_of_year: 53 },
  { text: "Be the person you needed when you were younger.", attribution: "HEAL", category: "love", is_motivation: true, day_of_year: 54 },
  { text: "Slow is not behind. Slow is the pace of the soul.", attribution: "HEAL", category: "stillness", is_motivation: true, day_of_year: 55 },
  { text: "You are held by something older than your worry.", attribution: "HEAL", category: "love", is_motivation: true, day_of_year: 56 },
  { text: "The body remembers how to rest. Sometimes the mind just needs to follow.", attribution: "HEAL", category: "rest", is_motivation: true, day_of_year: 57 },
  { text: "You do not have to carry it all. Choose one thing to carry today. The rest can wait.", attribution: "HEAL", category: "let-go", is_motivation: true, day_of_year: 58 },
  { text: "The opposite of rest is not work. The opposite of rest is despair.", attribution: "HEAL", category: "rest", is_motivation: true, day_of_year: 59 },
  { text: "You are not late. You are not behind. You are exactly where this story needs you to be.", attribution: "HEAL", category: "hope", is_motivation: true, day_of_year: 60 },
];

const prayers = [
  { title: 'A Morning Prayer', slug: 'morning-prayer', category: 'morning',
    body: "Good morning, Lord.\nThank You for the sleep that restored me.\nThank You for the day that begins again.\nHelp me to live it slowly.\nHelp me to live it kindly.\nHelp me to remember, in the small hours of the afternoon,\nthat the same love that woke me this morning\nis still waking me up, all day long.\nAmen." },
  { title: 'An Evening Prayer', slug: 'evening-prayer', category: 'evening',
    body: "Lord, this day is done.\nWhatever I did well, thank You.\nWhatever I did poorly, forgive me.\nWhatever I did not get to, let it go.\nLet me sleep now, in the same hands that held me this morning.\nAmen." },
  { title: 'For Anxiety', slug: 'prayer-for-anxiety', category: 'anxiety',
    body: "Lord, my chest is tight.\nMy mind is loud.\nI do not have the words.\nLet my breath be the prayer I cannot say.\nLet Your peace meet me in the noise.\nI cast the worry on You now.\nReceive it.\nAmen." },
  { title: 'For Gratitude', slug: 'prayer-of-gratitude', category: 'gratitude',
    body: "Thank You, Lord, for the small things I noticed today:\nthe coffee, the laugh, the light, the small kindness\nthat I almost missed.\nFor the breath that came easy.\nFor the breath that did not.\nFor all of it — the seen and the unseen —\nthank You.\nAmen." },
  { title: 'For Forgiveness', slug: 'prayer-for-forgiveness', category: 'forgiveness',
    body: "Lord, I have held this long enough.\nI am laying it down now.\nNot because it did not matter.\nBut because it does — and I am tired of carrying it\non my own.\nHelp me to forgive, even a little,\nand trust You with the rest.\nAmen." },
  { title: 'For Strength', slug: 'prayer-for-strength', category: 'strength',
    body: "Lord, I do not feel strong today.\nI feel tired, and old, and small.\nBe my strength.\nNot the kind that performs,\nbut the kind that quietly holds on\nwhen everything else is letting go.\nAmen." },
  { title: 'For Rest', slug: 'prayer-for-rest', category: 'rest',
    body: "Lord, I am tired.\nNot just the body — the soul.\nLet me lie down now, in the green pasture You promised.\nLet the still water be enough.\nLet me stop, for a while,\nbeing the one in charge.\nAmen." },
  { title: 'When I Do Not Know What to Pray', slug: 'when-i-dont-know', category: 'other',
    body: "Lord, I do not have the words today.\nSo I will just sit here.\nLet the silence be the prayer.\nLet the breath be the prayer.\nLet me be the prayer.\nAmen." },
  { title: 'Before a Hard Conversation', slug: 'before-a-hard-conversation', category: 'other',
    body: "Lord, I have to do something hard today.\nBe in my mouth before I speak.\nBe in my ears before I listen.\nSoften me, where I would harden.\nOpen me, where I would close.\nAmen." },
  { title: 'When I Cannot Forgive Myself', slug: 'cannot-forgive-myself', category: 'forgiveness',
    body: "Lord, I am harder on myself than You are.\nI am keeping a record You have already closed.\nHelp me to receive, today,\nthe same grace I would offer a friend.\nAmen." },
  { title: 'For a Troubled Mind', slug: 'troubled-mind', category: 'anxiety',
    body: "Lord, the thoughts are loud tonight.\nLet me not be ruled by them.\nLet me be ruled by Your peace instead.\nIn Jesus' name, I lay them down.\nAmen." },
  { title: 'For a Weary Parent', slug: 'weary-parent', category: 'rest',
    body: "Lord, the children are loud,\nand the work is unfinished,\nand I am tired.\nThank You that I am loved, even when I am not at my best.\nThank You for the long patience of parenthood,\nwhich is, perhaps, a small image of Yours.\nHelp me to rest soon.\nHelp me to not feel guilty when I do.\nAmen." },
  { title: 'For the Beginning of a Practice', slug: 'beginning-of-practice', category: 'morning',
    body: "Lord, I am showing up.\nThat is all I can promise today.\nMeet me here, in this small beginning.\nLet it be enough.\nAmen." },
  { title: 'For a Friend in Trouble', slug: 'friend-in-trouble', category: 'other',
    body: "Lord, I cannot fix what they are going through.\nBut I can sit with them in it.\nHelp me to be Your hands today —\nquiet, present, kind.\nAmen." },
  { title: 'For When the Day Has Been Long', slug: 'long-day', category: 'evening',
    body: "Lord, the day is over,\nand I am glad of it.\nForgive me for the moments I was not kind.\nThank You for the moments I was.\nLet me rest now, in the only home I have:\nYour presence.\nAmen." },
  { title: 'For Joy, Unearned', slug: 'joy-unearned', category: 'gratitude',
    body: "Lord, today something small made me happy.\nThe way the wind moved.\nA song on the radio.\nA face I love, doing something ordinary.\nI did not earn this joy.\nThank You for it anyway.\nAmen." },
  { title: 'For the Lonely Hour', slug: 'lonely-hour', category: 'anxiety',
    body: "Lord, it is the hour of the night\nwhen the loneliness is loudest.\nBe with me now, especially now.\nYou are closer than my own breath.\nLet me remember that.\nAmen." },
  { title: 'For a New Beginning', slug: 'new-beginning', category: 'morning',
    body: "Lord, today is new.\nI do not have to be the same person I was yesterday.\nI do not have to be perfect today.\nI only have to begin, again,\nin the same small, kind way.\nAmen." },
  { title: 'For a Grieving Heart', slug: 'grieving-heart', category: 'rest',
    body: "Lord, the loss is still here.\nI do not ask You to take it away today.\nI only ask You to sit with me in it.\nTo be the friend who does not try to fix it,\nbut who just stays.\nAmen." },
  { title: 'Before Sleep', slug: 'before-sleep', category: 'evening',
    body: "Lord, I am lying down now.\nWhatever tomorrow brings,\nI will not face it alone.\nYou have already gone ahead of me,\ninto tomorrow,\nand You are waiting for me there.\nAmen." },
];

const essays = [
  {
    title: 'A Quiet Beginning: Why HEAL Exists',
    slug: 'why-heal',
    subtitle: 'On the small, slow art of being present to God',
    author: 'HEAL',
    excerpt: 'Most of us are tired. Not the kind of tired that one good night\'s sleep fixes — the other kind. The kind that lives in the shoulders, in the chest, in the part of you that checks email even when you\'re not at work.',
    body: "Most of us are tired. Not the kind of tired that one good night's sleep fixes — the other kind. The kind that lives in the shoulders, in the chest, in the part of you that checks email even when you're not at work.\n\nThe world's wisdom traditions have, for thousands of years, offered an answer: be still. Pay attention. Breathe. Return.\n\nThe Christian tradition, in particular, is rich with this — the Desert Mothers and Fathers, the Jesus Prayer, the Lectio Divina, the simple instruction of the Psalmist: be still, and know that I am God.\n\nHEAL is a small attempt to gather that wisdom into a daily practice. A short meditation. A passage. A breath. A prayer. A word to carry with you into the day.\n\nWe are not therapists. We are not theologians. We are people who needed this ourselves, and we made it for anyone who might need it too.\n\nWhatever you believe, you are welcome here. Whatever you're carrying, you don't have to put it down at the door.",
    reading_minutes: 3,
    is_published: true,
    published_at: '2026-06-01',
  },
  {
    title: 'Christian Mindfulness: A Practice, Not a Product',
    slug: 'christian-mindfulness',
    subtitle: 'How ancient prayer and modern attention science fit together',
    author: 'HEAL',
    excerpt: 'Mindfulness, in its Christian form, is older than the word itself. It is the practice of paying attention to the present moment, in the presence of God. That is the whole of it. And the whole of it is enough.',
    body: "Mindfulness, in its Christian form, is older than the word itself. It is the practice of paying attention to the present moment, in the presence of God.\n\nThat is the whole of it. And the whole of it is enough.\n\nThe Desert Fathers, in the fourth century, taught their students to \"pray without ceasing\" — not by adding more words, but by returning, again and again, to the present moment, to the breath, to the awareness of being held by God.\n\nThe Jesus Prayer — \"Lord Jesus Christ, Son of God, have mercy on me, a sinner\" — is a one-sentence practice that fits inside a breath. It is, in modern terms, a mantra; in ancient terms, a way of being.\n\nLectio Divina — the slow, prayerful reading of a short passage of Scripture — is a form of attention training that predates the word \"mindfulness\" by sixteen centuries.\n\nWhat modern attention science calls mindfulness, the Christian contemplative tradition has been doing for a long time. The only difference is the framing: not just presence, but presence with. Not just attention, but attention held in relationship.\n\nIf you are a Christian curious about mindfulness, the practice is already yours. You do not have to import anything. You only have to notice, and return.\n\nIf you are not a Christian but you are curious about this tradition, you are welcome. The practices work whether or not you share our theology. The breath is a free prayer.",
    reading_minutes: 4,
    is_published: true,
    published_at: '2026-06-04',
  },
  {
    title: 'The Small Door',
    slug: 'the-small-door',
    subtitle: 'On beginning a practice when you are very tired',
    author: 'HEAL',
    excerpt: 'The most important thing about a contemplative practice is not how long it is. It is whether you show up. Even on the days — especially on the days — you can barely show up at all.',
    body: "The most important thing about a contemplative practice is not how long it is. It is whether you show up.\n\nEven on the days — especially on the days — you can barely show up at all.\n\nIf you have ever tried to start a meditation practice, you know the pattern. The first week is fresh and earnest. The second week, you miss a day. The third week, you miss a week. By the end of the month, you have quietly decided that you are not a meditation person, and you go back to the scrolling, the noise, the not-very-quietness of your day.\n\nWe want to suggest a different approach: a smaller door.\n\nThe tradition calls it the \"rule.\" Not a strict, demanding rule, but a gentle, repeatable one. Two minutes a day, in the same place, at the same time. That is the rule. If you can do more, do more. If you can do less, do less. But do not skip the rule.\n\nThe rule is small for a reason. The point is not the meditation. The point is the return. The point is teaching the body, slowly, that there is a place it can come home to. That there is a chair, and a breath, and a small, kind space.\n\nThe room will hold you on the days you cannot hold yourself. That is the whole promise.",
    reading_minutes: 4,
    is_published: true,
    published_at: '2026-06-07',
  },
];

async function main() {
  console.log('🌿 HEAL — content generator (v1 launch batch)');

  await mkdir(join(ROOT, 'meditations'), { recursive: true });
  await mkdir(join(ROOT, 'quotes'), { recursive: true });
  await mkdir(join(ROOT, 'prayers'), { recursive: true });
  await mkdir(join(ROOT, 'essays'), { recursive: true });

  // Meditations: one JSON per record (so we can later generate illustration
  // and audio files alongside the JSON, and the seed script can upsert by slug).
  for (const m of meditations) {
    const slug = (m.title || '').toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
      .slice(0, 60);
    const payload = { ...m, slug, sort_order: m.day_of_year, is_published: true };
    const path = join(ROOT, 'meditations', `${String(m.day_of_year).padStart(3, '0')}-${slug}.json`);
    await writeFile(path, JSON.stringify(payload, null, 2));
    console.log(`  ✓ meditation ${m.day_of_year}: ${m.title}`);
  }

  // Quotes: one file, array form
  await writeFile(join(ROOT, 'quotes', 'quotes-launch-1.json'), JSON.stringify(quotes.map((q, i) => ({
    ...q,
    slug: `q-${String(q.day_of_year).padStart(3, '0')}-${(q.text || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 40).replace(/^-|-$/g, '')}`,
    is_published: true,
  })), null, 2));
  console.log(`  ✓ ${quotes.length} quotes`);

  // Prayers: one file per prayer (slug is stable)
  for (const p of prayers) {
    const path = join(ROOT, 'prayers', `${p.slug}.json`);
    await writeFile(path, JSON.stringify({ ...p, is_published: true, sort_order: prayers.indexOf(p) + 1 }, null, 2));
  }
  console.log(`  ✓ ${prayers.length} prayers`);

  // Essays
  for (const e of essays) {
    const path = join(ROOT, 'essays', `${e.slug}.json`);
    await writeFile(path, JSON.stringify(e, null, 2));
  }
  console.log(`  ✓ ${essays.length} essays`);

  console.log('\n✨ Done. Now run: pnpm content:seed');
}

main().catch(e => { console.error('💥', e); process.exit(1); });
