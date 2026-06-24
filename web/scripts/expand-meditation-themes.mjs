import PocketBase from 'pocketbase';
const pb = new PocketBase('https://pocketbase.scaleupcrm.com');
try { await pb.admins.authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); } catch { await pb.collection('_superusers').authWithPassword(process.env.PB_IDENTITY, process.env.PB_PASSWORD); }
const col = await pb.collections.getOne('HEAL_meditations');
const themeField = col.fields.find(f => f.name === 'theme');
const existing = themeField.values || [];
const need = ['calm','courage','focus','forgiveness','grace','gratitude','grief','hope','joy','let-go','love','rest','stillness','strength','wisdom'];
const merged = [...new Set([...existing, ...need])].sort();
themeField.values = merged;
await pb.collections.update(col.id, { fields: col.fields });
console.log('  meditation theme values:', merged);
console.log('done');
