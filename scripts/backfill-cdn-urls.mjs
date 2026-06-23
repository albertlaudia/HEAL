// HEAL — backfill PB illustration_url + audio_url to point to the CDN
// (https://resources.positiveness.club/heal/...)
//
// Walks every record in HEAL_meditations, HEAL_prayers, HEAL_praise,
// HEAL_essays, HEAL_breathwork, HEAL_programs and sets the URL fields
// based on slug. Idempotent — re-runs are safe.
//
// What this gives us:
// - Components can read straight from PB without cdnUrl() wrapping
// - Old local-fallback chain is dead (but kept in components as defense-in-depth)
// - All media is now demonstrably external to Dokploy
//
// Env: PB_URL, PB_IDENTITY, PB_PASSWORD

const PB_URL = process.env.PB_URL;
const PB_IDENTITY = process.env.PB_IDENTITY;
const PB_PASSWORD = process.env.PB_PASSWORD;

const CDN_BASE = 'https://resources.positiveness.club/heal';

// Map: collection -> field->url-template-fn(slug)
const PLAN = {
  HEAL_meditations: {
    illustration_url: (s) => `${CDN_BASE}/images/meditations/illustration-${s}.png`,
    audio_url:       (s) => `${CDN_BASE}/audio/meditations/audio-${s}.mp3`,
  },
  HEAL_prayers: {
    illustration_url: (s) => `${CDN_BASE}/images/prayers/prayer-${s}.png`,
  },
  HEAL_praise: {
    illustration_url: (s) => `${CDN_BASE}/images/praise/praise-${s}.png`,
    audio_url:       (s) => `${CDN_BASE}/audio/praise/song-${s}.mp3`,
  },
  HEAL_essays: {
    illustration_url: (s) => `${CDN_BASE}/images/essays/essay-${s}.png`,
  },
  // breathwork + programs: no illustration file convention, skip
};

if (!PB_URL || !PB_IDENTITY || !PB_PASSWORD) {
  console.error('❌ Set PB_URL, PB_IDENTITY, PB_PASSWORD');
  process.exit(1);
}

async function auth() {
  const r = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity: PB_IDENTITY, password: PB_PASSWORD }),
  });
  const d = await r.json();
  if (!d.token) throw new Error('auth failed: ' + JSON.stringify(d));
  return d.token;
}

async function* listAll(collection, token) {
  let page = 1;
  while (true) {
    const r = await fetch(
      `${PB_URL}/api/collections/${collection}/records?perPage=500&page=${page}&fields=id,slug,illustration_url,audio_url`,
      { headers: { Authorization: token } }
    );
    const d = await r.json();
    if (!d.items || d.items.length === 0) return;
    for (const it of d.items) yield it;
    if (d.items.length < 500) return;
    page++;
  }
}

async function main() {
  const token = await auth();
  console.log(`Authenticated. CDN base: ${CDN_BASE}\n`);

  let totalUpdated = 0;
  let totalSkipped = 0;
  let totalNotFound = 0;
  let totalFailed = 0;
  const notFound = [];

  for (const [col, fields] of Object.entries(PLAN)) {
    console.log(`=== ${col} ===`);
    let colUpdated = 0, colSkipped = 0, colNotFound = 0, colFailed = 0;

    for await (const item of listAll(col, token)) {
      const updates = {};
      for (const [field, urlFn] of Object.entries(fields)) {
        const newUrl = urlFn(item.slug);
        if (item[field] === newUrl) {
          colSkipped++;
          continue;
        }
        updates[field] = newUrl;
      }
      if (Object.keys(updates).length === 0) continue;

      // Verify the CDN URL works before writing to PB
      const urlToCheck = updates.illustration_url || updates.audio_url;
      let remoteOk = true;
      try {
        const head = await fetch(urlToCheck, { method: 'HEAD' });
        remoteOk = head.ok;
      } catch {
        remoteOk = false;
      }
      if (!remoteOk) {
        colNotFound++;
        notFound.push(`${col}/${item.slug}: ${urlToCheck}`);
        continue;
      }

      const r = await fetch(`${PB_URL}/api/collections/${col}/records/${item.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', Authorization: token },
        body: JSON.stringify(updates),
      });
      if (r.ok) {
        colUpdated++;
        console.log(`  ✓ ${item.slug} → ${Object.keys(updates).join(', ')}`);
      } else {
        colFailed++;
        console.log(`  ✗ ${item.slug}: ${(await r.text()).slice(0, 200)}`);
      }
    }

    console.log(`  updated=${colUpdated}  skipped=${colSkipped}  not_found_remote=${colNotFound}  failed=${colFailed}\n`);
    totalUpdated += colUpdated;
    totalSkipped += colSkipped;
    totalNotFound += colNotFound;
    totalFailed += colFailed;
  }

  console.log('=== TOTAL ===');
  console.log(`updated:    ${totalUpdated}`);
  console.log(`skipped:    ${totalSkipped}`);
  console.log(`not_found:  ${totalNotFound}`);
  console.log(`failed:     ${totalFailed}`);

  if (notFound.length > 0) {
    console.log('\n=== Files not found on CDN (need upload) ===');
    for (const nf of notFound) console.log(`  ${nf}`);
  }
}

main().catch((e) => {
  console.error('Fatal:', e);
  process.exit(1);
});
