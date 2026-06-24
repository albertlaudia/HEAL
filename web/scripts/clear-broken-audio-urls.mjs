// HEAL — clear audio_url in PB for any meditation whose audio doesn't exist on the CDN.
// This prevents 404s on the live site. Meditations will show in text-only mode
// until the audio is generated and uploaded.

const PB_URL = process.env.PB_URL;
const PB_IDENTITY = process.env.PB_IDENTITY;
const PB_PASSWORD = process.env.PB_PASSWORD;
const CDN_BASE = 'https://resources.positiveness.club/heal';

if (!PB_URL || !PB_IDENTITY || !PB_PASSWORD) {
  console.error('❌ Set PB_URL, PB_IDENTITY, PB_PASSWORD');
  process.exit(1);
}

async function main() {
  const auth = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity: PB_IDENTITY, password: PB_PASSWORD }),
  });
  const a = await auth.json();
  const token = a.token;
  console.log('authenticated ✓');

  // Fetch all meditations with their audio_url
  const r = await fetch(`${PB_URL}/api/collections/HEAL_meditations/records?perPage=500&fields=id,slug,audio_url`, {
    headers: { Authorization: token },
  });
  const d = await r.json();
  const items = d.items || [];
  console.log(`meditations to check: ${items.length}`);

  let cleared = 0, kept = 0, errors = 0;
  const clearedList = [];
  for (const item of items) {
    if (!item.audio_url) {
      kept++;
      continue;
    }
    // HEAD check
    let ok = true;
    try {
      const head = await fetch(item.audio_url, { method: 'HEAD' });
      ok = head.ok;
    } catch {
      ok = false;
    }
    if (ok) {
      kept++;
      continue;
    }
    // 404 — clear the audio_url
    const r2 = await fetch(`${PB_URL}/api/collections/HEAL_meditations/records/${item.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: token },
      body: JSON.stringify({ audio_url: '' }),
    });
    if (r2.ok) {
      cleared++;
      clearedList.push(item.slug);
    } else {
      errors++;
      console.log(`  ✗ ${item.slug}: ${(await r2.text()).slice(0, 200)}`);
    }
  }

  console.log(`\nkept:    ${kept}`);
  console.log(`cleared: ${cleared}`);
  console.log(`errors:  ${errors}`);
  if (cleared > 0) {
    console.log(`\nCleared slugs (${cleared}):`);
    for (const s of clearedList) console.log(`  ${s}`);
  }
}

main().catch((e) => {
  console.error('Fatal:', e);
  process.exit(1);
});