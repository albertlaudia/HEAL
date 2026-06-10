import { getPublished } from '@/lib/pb';
import { SongCard } from '@/components/praise/SongCard';

export const revalidate = 3600;

export const metadata = {
  title: 'Praise — Songs for the Soul',
  description: 'Worship songs, hymns, and chants. Lyrics, chords, and reflections for prayer and singing.',
};

export default async function PraisePage() {
  const songs = await getPublished('HEAL_praise', 'sort_order', 'is_published = true');

  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Songs</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Praise</h1>
        <p className="text-ink/60 leading-relaxed mb-4">
          A library of worship songs, hymns, and chants — old and new — for prayer, for singing, for the times when the only thing left is to lift a voice.
        </p>
        <p className="text-ink/60 leading-relaxed">
          Click any song to read the lyrics. Expand to see chords and a short reflection.
        </p>
      </header>

      {songs.length === 0 ? (
        <p className="text-ink/50 serif italic">Songs are being prepared.</p>
      ) : (
        <div className="space-y-8 max-w-3xl">
          {songs.map((s: any) => (
            <SongCard key={s.id} song={s} />
          ))}
        </div>
      )}
    </div>
  );
}
