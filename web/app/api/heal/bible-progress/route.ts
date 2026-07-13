import { NextRequest, NextResponse } from 'next/server';
import { listRows } from '../../../../lib/db';

/// Bible progress is auth-gated. Reads require the user's auth token
/// (Firebase ID token via Authorization: Bearer <idToken>). For v1, the
/// mobile app writes directly to PB (where the rules are tight); this
/// route will be wired when Firebase auth lands.
export async function GET(_req: NextRequest) {
  return NextResponse.json({
    note: 'Bible progress writes still go to PB until Firebase auth lands.',
    records: [],
  });
}
