// Lightweight client auth state — context-only, no external dep
'use client';
import { createContext, useContext, useState, type ReactNode } from 'react';

export type AuthUser = { uid: string; email?: string | null; name?: string | null; picture?: string | null } | null;

type AuthCtx = {
  user: AuthUser;
  setUser: (u: AuthUser) => void;
  ready: boolean;
  setReady: (r: boolean) => void;
};

const Ctx = createContext<AuthCtx>({
  user: null,
  setUser: () => undefined,
  ready: false,
  setReady: () => undefined,
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser>(null);
  const [ready, setReady] = useState(false);
  const ctxValue: AuthCtx = { user, setUser, ready, setReady };
  return (
    <Ctx.Provider value={ctxValue}>
      {children}
    </Ctx.Provider>
  );
}

export function useAuth() {
  return useContext(Ctx);
}
