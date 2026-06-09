import PocketBase from 'pocketbase';
const pb = new PocketBase('https://pocketbase.scaleupcrm.com');
try { await pb.admins.authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); } catch { await pb.collection('_superusers').authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); }
const cols = ['HEAL_meditations', 'HEAL_quotes', 'HEAL_scriptures', 'HEAL_prayers', 'HEAL_breathwork', 'HEAL_essays'];
for (const c of cols) {
  const list = await pb.collection(c).getFullList();
  let n = 0;
  for (const r of list) {
    if (!r.is_published) {
      await pb.collection(c).update(r.id, { is_published: true });
      n++;
    }
  }
  console.log(`  ${c}: published ${n}/${list.length}`);
}
console.log('done');
