// Server-side session helpers — verify Firebase idToken → set/read a JWT cookie
// Pattern proven in Sindo Shipping (2026-06-08): client posts idToken, server
// verifies via Firebase REST API (no admin SDK needed for v1), mints a 14-day
// JWT cookie with jose.
import { cookies } from 'next/headers';
import { SignJWT, jwtVerify } from 'jose';
import 'server-only';

const COOKIE = 'heal_session';
const ALG = 'HS256';
const secret = new TextEncoder().encode(process.env.HEAL_JWT_SECRET || 'dev-only-secret-rotate-me-please');

export type Session = { uid: string; email?: string | null; name?: string | null; picture?: string | null };

export async function mintSessionCookie(payload: Session): Promise<string> {
  return await new SignJWT({ ...payload })
    .setProtectedHeader({ alg: ALG })
    .setIssuedAt()
    .setExpirationTime('14d')
    .sign(secret);
}

export async function readSession(): Promise<Session | null> {
  const c = await cookies();
  const tok = c.get(COOKIE)?.value;
  if (!tok) return null;
  try {
    const { payload } = await jwtVerify(tok, secret);
    return payload as unknown as Session;
  } catch { return null; }
}

export async function requireSession(): Promise<Session> {
  const s = await readSession();
  if (!s) throw new Error('UNAUTHENTICATED');
  return s;
}

export const SESSION_COOKIE = COOKIE;

export async function setSessionCookie(token: string) {
  const c = await cookies();
  c.set(COOKIE, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    maxAge: 60 * 60 * 24 * 14,
  });
}

export async function clearSessionCookie() {
  const c = await cookies();
  c.delete(COOKIE);
}
