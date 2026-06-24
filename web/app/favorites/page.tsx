'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth-store';
import { listFavorites, type Favorite } from '@/lib/firebase-rest';
import { cached } from '@/lib/firestore-cache';
import { Heart } from 'lucide-react';
import { AuthMenu } from '@/components/auth/AuthMenu';

export default function FavoritesPage() {
  const { user, ready } = useAuth();
  const [favs, setFavs] = useState<Favorite[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { setLoading(false); return; }
    cached(`favs:${user.uid}`, () => listFavorites(user.uid))
      .then(setFavs)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [user]);

  if (!ready) return null;

  if (!user) {
    return (
      <div className="container-quiet py-32 text-center">
        <Heart className="mx-auto text-ink/30 mb-6" size={32} />
        <h1 className="serif text-4xl mb-4">Favorites</h1>
        <p className="text-ink/60 mb-8">Sign in to save the practices that speak to you.</p>
        <AuthMenu />
      </div>
    );
  }

  return (
    <div className="container-wide py-16">
      <header className="mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Your collection</p>
        <h1 className="serif text-5xl mb-4">Favorites</h1>
        <p className="text-ink/60">The practices you wanted to come back to.</p>
      </header>

      {loading ? (
        <p className="text-ink/50">Loading…</p>
      ) : favs.length === 0 ? (
        <p className="text-ink/50 serif italic py-12">No favorites yet. Tap the heart on any meditation or passage to begin.</p>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {favs.map(f => (
            <Link
              key={f.id}
              href={f.kind === 'meditation' ? `/meditate/${f.slug}` : f.kind === 'essay' ? `/essays/${f.slug}` : '#'}
              className="card-quiet p-6 hover:scale-[1.01] transition-transform"
            >
              <p className="text-xs tracking-widest uppercase text-sage-700 mb-2">{f.kind}</p>
              <h3 className="serif text-2xl mb-2">{f.title}</h3>
              {f.subtitle && <p className="text-sm text-ink/60 serif italic">{f.subtitle}</p>}
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
