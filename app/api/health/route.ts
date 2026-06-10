import { NextResponse } from 'next/server';
import { pb } from '@/lib/pb';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

export async function GET() {
  const start = Date.now();
  const checks: Record<string, { ok: boolean; latency_ms?: number; error?: string }> = {
    self: { ok: true },
  };

  // Check PocketBase
  try {
    const pbStart = Date.now();
    await pb.health.check();
    checks.pocketbase = { ok: true, latency_ms: Date.now() - pbStart };
  } catch (e: any) {
    checks.pocketbase = { ok: false, error: e?.message || 'unreachable' };
  }

  const allOk = Object.values(checks).every(c => c.ok);
  return NextResponse.json(
    {
      status: allOk ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime_ms: process.uptime() * 1000,
      total_latency_ms: Date.now() - start,
      checks,
    },
    { status: allOk ? 200 : 503, headers: { 'Cache-Control': 'no-store' } }
  );
}
