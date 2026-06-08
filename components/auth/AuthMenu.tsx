'use client';

import { useState } from 'react';
import { useAuth } from '@/lib/auth-store';
import { signInWithGoogle, signInWithEmail, signUpWithEmail, signOut } from '@/lib/firebase-client';
import { LogIn, LogOut, User as UserIcon, BookMarked, Heart, History as HistoryIcon } from 'lucide-react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

export function AuthMenu() {
  const { user, setUser } = useAuth();
  const [open, setOpen] = useState(false);
  const [mode, setMode] = useState<'menu' | 'signin' | 'signup'>('menu');
  const [email, setEmail] = useState('');
  const [pwd, setPwd] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const router = useRouter();

  const close = () => { setOpen(false); setMode('menu'); setErr(null); setEmail(''); setPwd(''); };

  const onGoogle = async () => {
    setBusy(true); setErr(null);
    try { await signInWithGoogle(); close(); } catch (e: any) { setErr(e.message); }
    setBusy(false);
  };

  const onEmail = async (signUp: boolean) => {
    setBusy(true); setErr(null);
    try {
      if (signUp) await signUpWithEmail(email, pwd);
      else await signInWithEmail(email, pwd);
      close();
    } catch (e: any) { setErr(e.message); }
    setBusy(false);
  };

  const onSignOut = async () => {
    await signOut();
    setUser(null);
    close();
  };

  if (user) {
    return (
      <div className="relative">
        <button onClick={() => setOpen(o => !o)} className="flex items-center gap-2 text-sm text-ink/70 hover:text-ink">
          {user.picture ? (
            <img src={user.picture} alt="" className="w-7 h-7 rounded-full" />
          ) : (
            <span className="w-7 h-7 rounded-full bg-sage-200 text-sage-800 flex items-center justify-center text-xs">
              {(user.name || user.email || '?')[0]?.toUpperCase()}
            </span>
          )}
        </button>
        {open && (
          <div className="absolute right-0 top-full mt-2 w-60 card-quiet p-2 z-50">
            <div className="px-3 py-2 border-b border-ink/5 mb-1">
              <p className="text-sm font-medium truncate">{user.name || user.email}</p>
              <p className="text-xs text-ink/50 truncate">{user.email}</p>
            </div>
            <MenuLink href="/journal" icon={<BookMarked size={14} />}>Journal</MenuLink>
            <MenuLink href="/favorites" icon={<Heart size={14} />}>Favorites</MenuLink>
            <MenuLink href="/history" icon={<HistoryIcon size={14} />}>History</MenuLink>
            <button onClick={onSignOut} className="w-full text-left px-3 py-2 rounded-lg text-sm hover:bg-ink/5 flex items-center gap-2 text-ink/70">
              <LogOut size={14} /> Sign out
            </button>
          </div>
        )}
      </div>
    );
  }

  return (
    <>
      <button onClick={() => setOpen(true)} className="btn-pill">
        <LogIn size={14} /> Sign in
      </button>
      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-ink/30 backdrop-blur-sm" onClick={close}>
          <div className="card-quiet max-w-md w-full p-8" onClick={e => e.stopPropagation()}>
            {mode === 'menu' && (
              <>
                <h2 className="serif text-2xl mb-2">Welcome to HEAL</h2>
                <p className="text-ink/60 text-sm mb-6">Sign in to keep a journal, save favorites, and track your daily practice.</p>
                <button onClick={onGoogle} disabled={busy} className="w-full btn-primary mb-3">
                  Continue with Google
                </button>
                <div className="flex gap-2 mt-2">
                  <button onClick={() => setMode('signin')} className="flex-1 btn-ghost">Email</button>
                  <button onClick={() => setMode('signup')} className="flex-1 btn-ghost">Create account</button>
                </div>
                <p className="mt-6 text-xs text-ink/50">No account? You can still use HEAL — your progress just won't sync.</p>
              </>
            )}
            {(mode === 'signin' || mode === 'signup') && (
              <>
                <h2 className="serif text-2xl mb-6">{mode === 'signin' ? 'Sign in' : 'Create your account'}</h2>
                <form onSubmit={e => { e.preventDefault(); onEmail(mode === 'signup'); }} className="space-y-3">
                  <input
                    type="email" required placeholder="email" value={email} onChange={e => setEmail(e.target.value)}
                    className="w-full px-4 py-3 rounded-full bg-paper border border-ink/10 focus:border-sage-400 focus:outline-none text-sm"
                  />
                  <input
                    type="password" required minLength={6} placeholder="password (min 6 chars)" value={pwd} onChange={e => setPwd(e.target.value)}
                    className="w-full px-4 py-3 rounded-full bg-paper border border-ink/10 focus:border-sage-400 focus:outline-none text-sm"
                  />
                  {err && <p className="text-sm text-red-600">{err}</p>}
                  <button type="submit" disabled={busy} className="w-full btn-primary">
                    {busy ? '…' : (mode === 'signin' ? 'Sign in' : 'Create account')}
                  </button>
                </form>
                <button onClick={() => setMode('menu')} className="mt-4 text-sm text-ink/50 hover:text-ink">← Back</button>
              </>
            )}
          </div>
        </div>
      )}
    </>
  );
}

function MenuLink({ href, icon, children }: { href: string; icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <Link href={href} className="block px-3 py-2 rounded-lg text-sm hover:bg-ink/5 flex items-center gap-2 text-ink/70">
      {icon} {children}
    </Link>
  );
}
