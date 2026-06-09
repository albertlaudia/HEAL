import PocketBase from 'pocketbase';
const pb = new PocketBase('https://pocketbase.scaleupcrm.com');
try { await pb.admins.authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); } catch { await pb.collection('_superusers').authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); }
const cols = ['HEAL_scriptures', 'HEAL_quotes', 'HEAL_prayers'];
for (const c of cols) {
  const list = await pb.collection(c).getFullList();
  for (let i = 0; i < list.length; i++) {
    const day = (i % 30) + 1; // wrap at 30 for now (full 365 would require more content)
    if (list[i].day_of_year !== day) {
      await pb.collection(c).update(list[i].id, { day_of_year: day });
    }
  }
  console.log(`  ${c}: assigned day_of_year 1-30 to ${list.length} records`);
}
console.log('done');
