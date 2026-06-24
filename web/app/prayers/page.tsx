import { getPublished } from '@/lib/pb';
import { PrayerList } from '@/components/prayers/PrayerList';

export const revalidate = 3600;

export default async function PrayersPage() {
  const prayers = await getPublished('HEAL_prayers', 'sort_order', 'is_published = true');
  return (
    <div className="container-wide py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Words</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Prayers</h1>
        <p className="text-ink/60 leading-relaxed">
          Short prayers for the in-between moments. Borrow them; they were never really ours.
        </p>
      </header>
      <PrayerList prayers={prayers} />
    </div>
  );
}
