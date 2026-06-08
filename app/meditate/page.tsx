import Link from 'next/link';
import Image from 'next/image';
import { getPublished } from '@/lib/pb';
import { formatDuration } from '@/lib/utils';
import { ThemeBadge } from '@/components/content/ThemeBadge';
import { Search, Headphones } from 'lucide-react';
import { MeditationFilters } from '@/components/meditate/MeditationFilters';

export const revalidate = 3600;

export default async function MeditatePage() {
  const all = await getPublished('HEAL_meditations', 'sort_order', 'is_published = true');

  const themes = ['calm', 'gratitude', 'let-go', 'love', 'focus', 'stillness', 'courage', 'rest'];
  const seasons = ['ordinary', 'advent', 'christmas', 'lent', 'easter', 'pentecost'];

  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Library</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Meditations</h1>
        <p className="text-ink/60 leading-relaxed">
          A growing collection of guided practices, organised by theme and season. Each one is its own small room — sit in it for as long as you like.
        </p>
      </header>

      <MeditationFilters meditations={all} themes={themes} seasons={seasons} />

      {all.length === 0 && (
        <div className="mt-12 text-center py-20 border border-dashed border-ink/10 rounded-2xl">
          <Headphones className="mx-auto text-ink/30 mb-4" size={32} />
          <p className="serif text-2xl text-ink/40">The library is being filled.</p>
          <p className="mt-2 text-sm text-ink/50">New meditations are added each week.</p>
        </div>
      )}
    </div>
  );
}
