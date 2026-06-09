import PocketBase from 'pocketbase';
const pb = new PocketBase('https://pocketbase.scaleupcrm.com');
try { await pb.admins.authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); } catch { await pb.collection('_superusers').authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); }
const list = await pb.collection('HEAL_breathwork').getFullList();
for (const r of list) {
  await pb.collection('HEAL_breathwork').update(r.id, { is_published: true });
  console.log('  ✓ published:', r.name);
}
console.log('done');
