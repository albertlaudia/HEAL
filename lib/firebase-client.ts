// Firebase client SDK — only safe to import in 'use client' components.
// On the server (SSR/SSG), we export a no-op stub so builds don't fail.
'use client';
import { initializeApp, getApps, getApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithPopup, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut as fbSignOut, onAuthStateChanged, type User } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey:            process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain:        process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId:         process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket:     process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId:             process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  measurementId:     process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID,
};

const HAS_CONFIG = !!firebaseConfig.apiKey && !!firebaseConfig.projectId;

let app: any = null;
let _auth: any = null;
let _db: any = null;

if (HAS_CONFIG && typeof window !== 'undefined') {
  try {
    app = getApps().length ? getApp() : initializeApp(firebaseConfig);
    _auth = getAuth(app);
    _db = getFirestore(app);
  } catch (e) {
    // Will surface in browser console
  }
}

export const auth = _auth;
export const db = _db;
export const googleProvider = _auth ? new GoogleAuthProvider() : null;

export async function signInWithGoogle() {
  if (!_auth || !googleProvider) throw new Error('Firebase not configured');
  return signInWithPopup(_auth, googleProvider);
}
export async function signInWithEmail(email: string, password: string) {
  if (!_auth) throw new Error('Firebase not configured');
  return signInWithEmailAndPassword(_auth, email, password);
}
export async function signUpWithEmail(email: string, password: string) {
  if (!_auth) throw new Error('Firebase not configured');
  return createUserWithEmailAndPassword(_auth, email, password);
}
export async function signOut() {
  if (!_auth) return;
  return fbSignOut(_auth);
}

export async function getIdTokenSafe(): Promise<string | null> {
  if (!_auth || !_auth.currentUser) return null;
  return _auth.currentUser.getIdToken();
}

export function watchAuth(cb: (u: User | null) => void) {
  if (!_auth) return () => {};
  return onAuthStateChanged(_auth, cb);
}
