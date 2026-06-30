/**
 * Client-only auth helpers.
 * Tracks the current user via Firebase Auth's onAuthStateChanged.
 * Safe to import in client components. No-op on the server.
 */
'use client';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { getAuthSafe } from './firebase-client';

let _user: User | null = null;
let _ready = false;
const _listeners: Array<(u: User | null) => void> = [];
let _started = false;

function start() {
  if (_started || typeof window === 'undefined') return;
  _started = true;
  const auth = getAuthSafe();
  if (!auth) return;
  onAuthStateChanged(auth, (u) => {
    _user = u;
    _ready = true;
    for (const cb of _listeners) cb(u);
  });
}

export function getCurrentUser(): User | null {
  start();
  return _user;
}

export function onAuthChange(cb: (u: User | null) => void): () => void {
  start();
  _listeners.push(cb);
  if (_ready) cb(_user);
  return () => {
    const i = _listeners.indexOf(cb);
    if (i >= 0) _listeners.splice(i, 1);
  };
}
