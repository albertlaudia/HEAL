import PocketBase from 'pocketbase';
const pb = new PocketBase('https://pocketbase.scaleupcrm.com');
try { await pb.admins.authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); } catch { await pb.collection('_superusers').authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); }
const list = await pb.collection('HEAL_meditations').getFullList({ filter: 'slug ~ "test"' });
for (const r of list) {
  await pb.collection('HEAL_meditations').delete(r.id);
  console.log('deleted test record', r.slug);
}
