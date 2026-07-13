// HEAL — Health check endpoint. Pings Postgres.
import { NextResponse } from 'next/server';
import { pgHealthCheck } from '../../../lib/db';

export const dynamic = 'force-dynamic';

export async function GET() {
  const pg = await pgHealthCheck();
  return NextResponse.json({
    status: pg.ok ? 'ok' : 'degraded',
    postgres: pg,
    timestamp: new Date().toISOString(),
  });
}
