// Server-side Firebase Admin — only for Firestore (not for Auth verification,
// which uses the REST API). Initialised lazily; safe to import in API routes
// and server components.
import 'server-only';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

function ensure() {
  if (getApps().length) return getApps()[0];
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  if (!projectId || !clientEmail || !privateKey) {
    throw new Error('Firebase Admin not configured (set FIREBASE_PROJECT_ID / FIREBASE_CLIENT_EMAIL / FIREBASE_PRIVATE_KEY)');
  }
  return initializeApp({ credential: cert({ projectId, clientEmail, privateKey }) });
}

export function adminDb() {
  return getFirestore(ensure());
}
