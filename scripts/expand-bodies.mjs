// expand-bodies.mjs — deepen meditation bodies from ~125 to ~400 words
// Reads each meditation, appends contemplative paragraphs based on theme
// Re-writes the JSON in place; preserves metadata, scripture, prayer.

import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const DIR = 'content/meditations';

// Theme-based extra paragraphs (140-180 words each)
const EXTRAS = {
  stillness: [
    `You do not have to be impressive in this moment. You do not have to be productive, or insightful, or kind of the right kind of person. The Lord of hosts, who is great in glory, has called this small, ordinary moment His own. He is in it. He is making it sing.\n\nThe world will ask you for many things. This is not one of them. The world is not watching this room. The Lord is. And He is pleased, simply, with your willingness to be here. He is pleased the way a father is pleased when a child, after a long day, comes and sits close to him and does not say anything.\n\nLet this be the one moment today that is not for anyone. Not for the work. Not for the people. Not even for the prayer. Just for the breath. Just for the being.`,
  ],
  gratitude: [
    `Gratitude, when it is honest, is not a feeling. It is a posture. It is the long, slow turning of the heart toward what is, instead of what is not. It does not require the thing to be big. It does not require the thing to be a miracle. It only requires the noticing.\n\nYou have noticed something. Something small, maybe. The cup of coffee. The door held open. The friend who texted first. The warmth of the sunlight. The fact that you are, at this moment, not on fire.\n\nThe Lord gave you that. He gave you a thousand small gifts before breakfast, and you did not even have to ask. He is like that. He is like that every morning, whether you noticed or not. Today, you noticed. Today, you said thank you. The Lord is pleased.`,
  ],
  let_go: [
    `The grip is the heaviest thing you carry. The white-knuckled holding-on of the things you were never meant to hold. The things that were never yours to keep. The relationship that has changed shape. The future you planned. The past you cannot rewrite. The opinions of people who will forget you by Tuesday.\n\nYou are allowed to set them down. The Lord is not asking you to carry them. He never was. He is the one who said, "Come to me, all you who are weary and heavy laden, and I will give you rest." The rest is not just the break. The rest is the release.\n\nSet the thing down. Watch the lightness come back. The Lord, who is faithful, will hold what you release. He is better at holding than you are.`,
  ],
  love: [
    `You have been loved in small, ordinary ways. The lunch packed. The blanket pulled up. The look across the room that meant, I see you. The friend who did not say anything, but stayed. The coworker who covered for you. The stranger who returned the wallet. The grandparent who remembered your name.\n\nThese are the love of God, distributed through the human. They are not random. They are not luck. They are the Lord, who is love, loving you in the only language the moment would allow.\n\nYou do not have to wait for a big love. The big love is the small love, repeated. The Lord is the one who stayed. The Lord is the one who came. The Lord is the one who keeps coming.`,
  ],
  focus: [
    `The mind is a wild animal. It has not been tamed. It wanders. It loops. It invents conversations that will never happen. It rehearses grievances from 2007. It makes shopping lists. It composes apologies to people who have died.\n\nThe mind, left alone, is exhausting. And you, today, are not alone with it. The Lord of the universe, who holds every thought in the palm of His hand, is in the room with the mind. He is not surprised by it. He made it. He can hold it.\n\nYou do not have to master the mind. You only have to bring it back. To the breath. To the word. To the chair. To the now. The Lord meets you in the bringing-back, every time.`,
  ],
  calm: [
    `The storm is not the whole sea. The storm is the part the wind is in. Underneath the storm, the sea is quiet. Underneath the storm, the sea has been quiet for a long time. Underneath the storm, the sea is the deep, still place where the Lord lives.\n\nYou are invited there. The water is deep. The water is warm. The water is safe. The wind is still happening above you, but the wind is not the truth. The deep is the truth. The deep is the Lord. The deep is where you are, right now, if you let yourself be there.\n\nBreathe into the deep. The deep breathes back.`,
  ],
  hope: [
    `Hope is not the same as optimism. Optimism believes the future will be good. Hope believes that, no matter what the future is, the Lord is already there. The Lord is in tomorrow. He is in the room you have not entered yet. He is in the conversation you have not had. He is in the diagnosis. He is in the loss. He is in the new thing.\n\nYou do not have to see the future to be hopeful. You only have to know Who is in it. The Lord, who walked with Israel in the wilderness for forty years, will walk with you into your tomorrow. He has time. He has grace. He has you.`,
  ],
  rest: [
    `Rest is not laziness. Rest is not the opposite of work. Rest is the foundation under the work. The Lord rested on the seventh day, and He did not rest because He was tired. He rested because the rest is part of the rhythm. The rest is what gives the work its meaning.\n\nYou are not a machine. You are a soul, housed in a body, on a long journey. The body needs to be still sometimes. The soul needs to be still more often. The journey needs a rest stop, or the road gets blurry, and you forget where you were going.\n\nStop. Be still. The Lord is not disappointed in your stillness. The Lord is the one who invented it.`,
  ],
  courage: [
    `The fear is not a sign that something is wrong. The fear is a sign that you are doing something brave. The people of the Bible, when they heard the call of God, were mostly afraid. Moses said, "I am slow of speech." Gideon said, "I am the least in my father's house." Jeremiah said, "I am a child." David was a shepherd. The fear is the calling's costume. You put it on when you step into the thing. You take it off later, on the other side.\n\nThe Lord does not ask you to be unafraid. He asks you to be brave. Brave is being afraid and stepping anyway. The Lord is the step. The Lord is the road. The Lord is the hand at your back.`,
  ],
  wisdom: [
    `Wisdom is not information. Wisdom is the slow, lived-in knowing. It is the difference between a book about swimming and a person who has swum. The book has the facts. The person has the body-knowledge, the water-knowledge, the muscle-and-bone memory.\n\nYou have lived enough to have wisdom. You have made enough decisions to know what the wrong one felt like. You have loved enough to know what it cost. You have lost enough to know what you would do differently next time. The wisdom is in the living. The wisdom is the long sediment of the years.\n\nThe Lord gives more. Ask Him. He gives generously, without scolding. He is the one who gives wisdom like He gives breath.`,
  ],
  forgiveness: [
    `Forgiveness is a muscle. The first time you try to flex it, it does not move. The second time, it twitches. The third time, it moves a little. The thousandth time, it is a strength. You have been working this muscle, on and off, for a long time. Some days it is strong. Some days it is sore. Today is a day to gently work it again. Not to prove anything. Not to perform anything. Just to set the weight down. Just to not carry it.\n\nThe Lord, who has forgiven you more than you will ever forgive yourself or anyone else, is with you in the work. He is not grading you. He is not watching the clock. He is just there, with the muscle, with the breath, with the slow, patient help.`,
  ],
  grief: [
    `Grief does not have a deadline. Grief is not a project to be finished. Grief is the long, slow re-orienting of the heart to a world that has changed shape. The shape will not be what it was. The shape will be something new, with an empty chair in it, or a name you cannot say, or a song you cannot listen to. The shape will be yours, and the shape will be enough.\n\nThe Lord does not rush grief. The Lord is the one who stood at the tomb of His friend and wept, even though He knew what was about to happen. He is the one who said, "Blessed are those who mourn." He is the one who is close to the brokenhearted.\n\nYou are not behind. You are not slow. You are walking the long road at the pace the long road requires. The Lord is walking with you.`,
  ],
  joy: [
    `The joy of the Lord is not a happy feeling. The joy of the Lord is something deeper, something that does not require the circumstances to be right. It is the bedrock. It is what is there, under the surface, even when the surface is sad.\n\nYou have felt this joy. You have felt it in a room that was otherwise heavy. You have felt it in a song that did not make sense at first. You have felt it on a day you did not want to wake up. It came anyway. The joy came anyway. That is the joy. That is the Lord.\n\nIt will come again. Even today. Especially today. It comes like the sun over the hill, on its own time, in its own way. You cannot earn it. You cannot make it. You can only be there when it arrives.`,
  ],
  strength: [
    `The strength you need today is not the strength of the athlete. It is the strength of the patient. The strength of the one who waits. The strength of the one who holds on when the rope burns the hand. The strength of the one who shows up, again, even when the showing up is heavy.\n\nThis is the kind of strength the Lord gives. He does not give the flashy kind. He gives the long kind. The quiet kind. The kind that does not make the news, but the kind that holds the world together. The kind that keeps a parent going at 3am. The kind that keeps a widow steady at the funeral. The kind that gets up the next morning and does the small thing.\n\nThe Lord is your strength. He is glad to be. He is glad to hold you, all day, in the invisible holding.`,
  ],
  grace: [
    `Grace is the thing you cannot earn, and the Lord has been pouring it on you anyway. Grace is the fact that you woke up this morning, in a body, in a day, with breath, and you were not asked to have earned any of it. Grace is the people who love you, who do not love you because you are lovable, but because love is what they are for.\n\nThe Lord is the source of all grace. He is the spring. He is the well. He is the one who said, "My grace is sufficient for you, for my power is made perfect in weakness." He is the one who, right now, is letting you be weak, and meeting you in the weakness, with the strength you did not have.\n\nYou are not too broken for grace. You are exactly the kind of person grace is for. The rest of the day, let it be the day you stop trying to deserve it.`,
  ],
};

// Closing contemplation (50-80 words) — varies by theme
const CLOSINGS = {
  stillness: `You do not have to do anything else with this moment. You have done the work of being here. That is the whole work. Carry the stillness with you, lightly, into whatever comes next.`,
  gratitude: `One thing, named. That is the practice. The rest of the day, see how many small good things you can name. The list will surprise you.`,
  let_go: `The hands are open. The thing is set down. You are lighter. Walk forward, even a little, with the lighter step.`,
  love: `The love you have been given, you have also been given to give. Look for one person, today, to give it to.`,
  focus: `One thing, at a time. The next small thing. The Lord meets you in the small, focused moments.`,
  calm: `The deep place is still there. Return to it, as many times as you need. The Lord is in the returning.`,
  hope: `Tomorrow is in the Lord's hands. So is today. So are you. Walk into both.`,
  rest: `The rest is not over. The rest is the day. Let the day have the rest.`,
  courage: `The fear does not have to leave before the step. The step and the fear can walk together.`,
  wisdom: `The wisdom is in the next small choice. Make the small choice. The Lord will meet you there.`,
  forgiveness: `The weight is lighter. The heart is a little less sore. Tomorrow, try again. The trying is the practice.`,
  grief: `There is no hurry. The road is long, and the Lord is with you on it. Walk at the pace the road requires.`,
  joy: `The joy came. It will come again. Be there when it does.`,
  strength: `You are held. You are stronger than you know. The Lord's strength is in the holding.`,
  grace: `The grace is enough. It has always been enough. The rest of the day, let it be enough.`,
};

const SEASONAL_EXTRAS = {
  lent: `\n\nIn these forty days, the small acts of denying are not the point. The point is the empty space they make. The point is the small hunger that opens the heart to a larger feeding. You are not being punished. You are being uncluttered. The Lord is the one who is making the space. He has time. He will fill it.`,
  easter: `\n\nThe empty tomb is the whole of the Christian claim. He is not there. He is risen. The world is not as stuck as it looks. The grave is not the last word. The Lord is in the rising, and the rising is for you, and you do not have to deserve it. You only have to receive it.`,
  christmas: `\n\nThe gospel begins in a feed trough, in a barn, in the wrong town, at the wrong time of year. The Lord did not start in a palace. He started in the bottom of the pile, with the people no one was looking at, and He has not left. He is with the bottom of the pile still. He is with you.`,
};

async function main() {
  const files = (await readdir(DIR)).filter(f => f.endsWith('.json') && !f.includes('-audio-') && !f.includes('-illustration-'));
  let expanded = 0;
  for (const f of files) {
    const p = join(DIR, f);
    const d = JSON.parse(await readFile(p, 'utf8'));
    const theme = d.theme || 'stillness';
    const season = d.season || 'ordinary';

    const currentBody = d.body || '';
    const currentWords = currentBody.split(/\s+/).filter(Boolean).length;

    // Skip if already dense (300+ words)
    if (currentWords >= 300) continue;

    // Add theme extras
    const themeExtras = EXTRAS[theme] || EXTRAS.stillness;
    const extra = themeExtras[Math.floor(Math.random() * themeExtras.length)];

    // Add seasonal extra if applicable
    const seasonal = (season !== 'ordinary' && SEASONAL_EXTRAS[season]) ? SEASONAL_EXTRAS[season] : '';

    // Add closing
    const closing = CLOSINGS[theme] || CLOSINGS.stillness;

    // Rebuild body: original + blank + extra + seasonal + blank + closing + a second contemplative
    const contemplative = `\n\nThere is a way of being in the world that does not require you to be ahead, or impressive, or on top of it. The world will not validate this way. The world will tell you to hurry. The Lord is telling you to be still. The Lord is telling you to be here. The Lord is the one who sees you, right now, in this chair, with this breath, with this much strength, with this much doubt. He sees you. He is with you. The seeing is the practice. The being-with is the gift.`;
    d.body = [currentBody.trim(), extra.trim(), seasonal.trim(), contemplative.trim(), closing.trim()].filter(Boolean).join('\n\n') + '\n';

    // Bump duration to 360-480s based on word count
    const newWords = d.body.split(/\s+/).filter(Boolean).length;
    d.duration_seconds = Math.min(480, Math.max(300, Math.round(newWords / 150 * 60)));

    await writeFile(p, JSON.stringify(d, null, 2) + '\n');
    expanded++;
  }
  console.log(`✓ Expanded ${expanded}/${files.length} meditations`);
}

main().catch(e => { console.error(e); process.exit(1); });
