#!/usr/bin/env node
// HEAL — Export PocketBase → Postgres.
// One-shot, idempotent. Reads every record from PB's HEAL_* collections
// and writes them to Postgres. Logs progress to stdout.
//
// Usage: node scripts/export-pb-to-postgres.js

const { Client } = require('pg');

const PB_URL = process.env.PB_URL || 'https://pocketbase.scaleupcrm.com';
const PB_IDENTITY = process.env.PB_IDENTITY || 'minimax@scaleupcrm.com';
const PB_PASSWORD = process.env.PB_PASSWORD;
if (!PB_PASSWORD) {
  console.error('PB_PASSWORD env var required');
  process.exit(1);
}

const PG_URL = process.env.PG_URL || 'postgresql://heal:heal_production_2026@heal-pg:5432/heal';

const COLLECTIONS = [
  'heal_meditations',
  'heal_praise',
  'heal_prayers',
  'heal_scriptures',
  'heal_quotes',
  'heal_breathwork',
  'heal_essays',
  'heal_bible_readings',
  'heal_bible_progress',
  'heal_world',
  'heal_pages',
];

// Map PB field type → Postgres type + transform
const TRANSFORMS = {
  json: (v) => JSON.stringify(v ?? []),
  bool: (v) => Boolean(v),
  number: (v) => v == null ? null : Number(v),
  date: (v) => v,  // already ISO string; Postgres parses
};

async function main() {
  // 1. Auth to PB
  const authRes = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identity: PB_IDENTITY, password: PB_PASSWORD }),
  });
  if (!authRes.ok) {
    console.error(`PB auth failed: ${authRes.status}`);
    process.exit(1);
  }
  const { token } = await authRes.json();
  console.log(`✓ Authenticated to PB`);

  // 2. Connect to Postgres
  const pg = new Client({ connectionString: PG_URL });
  await pg.connect();
  console.log(`✓ Connected to Postgres`);

  // 3. For each collection: TRUNCATE then COPY
  let totalRecords = 0;
  for (const col of COLLECTIONS) {
    console.log(`\n── ${col} ──`);

    // Fetch all records from PB (paginate)
    let allRecords = [];
    let page = 1;
    while (true) {
      const res = await fetch(
        `${PB_URL}/api/collections/${col}/records?perPage=500&page=${page}`,
        { headers: { Authorization: token } }
      );
      if (!res.ok) {
        console.error(`  fetch failed: ${res.status}`);
        break;
      }
      const data = await res.json();
      allRecords = allRecords.concat(data.items || []);
      if (!data.items || data.items.length < 500) break;
      page++;
    }
    console.log(`  Fetched ${allRecords.length} records`);

    if (allRecords.length === 0) {
      console.log(`  (empty, skipping)`);
      continue;
    }

    // Get the table schema to know which columns to write
    const schemaRes = await pg.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = $1
    `, [col]);
    const validColumns = new Set(schemaRes.rows.map((r) => r.column_name));

    // TRUNCATE
    await pg.query(`TRUNCATE TABLE ${col} CASCADE`);

    // Build INSERT
    const sample = allRecords[0];
    const cols = Object.keys(sample).filter((k) => validColumns.has(k) && k !== 'collectionId' && k !== 'collectionName' && k !== 'expand');

    // Transform values
    const values = allRecords.map((rec) => {
      const row = {};
      for (const c of cols) {
        let v = rec[c];
        // Type-transform based on PG column type
        const pgType = schemaRes.rows.find((r) => r.column_name === c)?.data_type;
        if (pgType === 'jsonb' && typeof v !== 'string') {
          v = JSON.stringify(v ?? null);
        } else if (pgType === 'boolean') {
          v = Boolean(v);
        } else if (pgType === 'integer' || pgType === 'double precision' || pgType === 'numeric') {
          v = v == null ? null : Number(v);
        } else if (pgType === 'date') {
          // ensure ISO date format YYYY-MM-DD, or null
          v = v ? String(v).split('T')[0] : null;
        }
        row[c] = v;
      }
      return row;
    });

    // Bulk insert
    for (let i = 0; i < values.length; i += 100) {
      const batch = values.slice(i, i + 100);
      const placeholders = batch.map((_, idx) => {
        const base = idx * cols.length;
        return '(' + cols.map((_, c) => `$${base + c + 1}`).join(',') + ')';
      }).join(',');
      const params = batch.flatMap((row) => cols.map((c) => row[c]));
      const sql = `INSERT INTO ${col} (${cols.map((c) => `"${c}"`).join(',')}) VALUES ${placeholders} ON CONFLICT DO NOTHING`;
      await pg.query(sql, params);
    }

    totalRecords += allRecords.length;
    console.log(`  ✓ Inserted ${allRecords.length} records`);
  }

  // 4. Verification
  console.log(`\n── Verification ──`);
  for (const col of COLLECTIONS) {
    const r = await pg.query(`SELECT count(*) AS n FROM ${col}`);
    console.log(`  ${col.padEnd(25)} ${r.rows[0].n} records`);
  }

  await pg.end();
  console.log(`\n✓ Done. ${totalRecords} total records migrated.`);
}

main().catch((e) => {
  console.error('Fatal:', e);
  process.exit(1);
});
