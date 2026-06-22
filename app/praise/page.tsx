import { getPublished, type HEALPraise } from '@/lib/pb';
import { PraiseLibrary } from '@/components/praise/PraiseLibrary';

export const revalidate = 3600;

export const metadata = {
  title: 'Praise — Songs for the Soul',
  description: 'Worship songs, hymns, and chants. Lyrics, chords, AI-sung leads over quiet instrumentals — for prayer, for singing, for the times when the only thing left is to lift a voice.',
};

export default async function PraisePage() {
  const songs = (await getPublished(
    'HEAL_praise',
    'sort_order,id',
    'is_published = true'
  )) as HEALPraise[];

  // Extract unique emotions + tags for the filter UI
  const allEmotions = Array.from(
    new Set(songs.map(s => s.emotion).filter(Boolean))
  ) as string[];
  const allTags = Array.from(
    new Set(songs.flatMap(s => s.tags || []))
  ).sort() as string[];
  const allContexts = Array.from(
    new Set(songs.flatMap(s => s.best_for || []))
  ) as string[];

  return (
    <div className="container-wide py-12 md:py-16">
      <header className="max-w-3xl mb-10">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Songs</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Praise</h1>
        <p className="serif italic text-ink/65 text-lg leading-relaxed mb-4">
          A library of worship songs, hymns, and chants — old and new — for prayer, for singing, for the times when the only thing left is to lift a voice.
        </p>
        <p className="text-ink/60 leading-relaxed">
          Each song has a sung lead you can play, lyrics to read along, chords to learn, and tags so you can find what fits your moment.
        </p>
      </header>

      <PraiseLibrary
        songs={songs}
        allEmotions={allEmotions}
        allTags={allTags}
        allContexts={allContexts}
      />
    </div>
  );
}
