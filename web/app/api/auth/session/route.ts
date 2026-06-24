// POST /api/auth/session — verify idToken, mint session cookie
// DELETE /api/auth/session — clear cookie
import { NextRequest, NextResponse } from 'next/server';
import { mintSessionCookie, setSessionCookie, clearSessionCookie } from '@/lib/session';

async function verifyIdToken(idToken: string) {
  // Firebase Identity Toolkit REST API: lookup account by idToken
  const key = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
  const r = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${key}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ idToken }),
  });
  if (!r.ok) throw new Error(`verify failed: ${r.status}`);
  const j = await r.json();
  return j.users?.[0];
}

export async function POST(req: NextRequest) {
  try {
    const { idToken } = await req.json();
    if (!idToken) return NextResponse.json({ error: 'missing idToken' }, { status: 400 });
    const user = await verifyIdToken(idToken);
    if (!user) return NextResponse.json({ error: 'invalid token' }, { status: 401 });
    const session = {
      uid: user.localId,
      email: user.email,
      name: user.displayName,
      picture: user.photoUrl,
    };
    const token = await mintSessionCookie(session);
    await setSessionCookie(token);
    return NextResponse.json({ ok: true, user: session });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}

export async function DELETE() {
  await clearSessionCookie();
  return NextResponse.json({ ok: true });
}
