import { notFound } from 'next/navigation';
import { getBySlug, getPublished } from '@/lib/pb';
import Image from 'next/image';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

export const revalidate = 3600;

export async function generateStaticParams() {
  const all = await getPublished('HEAL_essays', '-published_at', 'is_published = true');
  return all.map((e: any) => ({ slug: e.slug }));
}

export default async function EssayPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const essay: any = await getBySlug('HEAL_essays', slug);
  if (!essay) notFound();

  return (
    <article className="container-quiet py-16">
      <Link href="/essays" className="inline-flex items-center gap-2 text-sm text-ink/60 hover:text-ink mb-8">
        <ArrowLeft size={14} /> Essays
      </Link>

      <header className="mb-12">
        <p className="text-xs tracking-widest uppercase text-ink/50 mb-4">
          {new Date(essay.published_at).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
          {essay.reading_minutes ? ` · ${essay.reading_minutes} min read` : ''}
        </p>
        <h1 className="serif text-4xl md:text-5xl mb-3">{essay.title}</h1>
        {essay.subtitle && <p className="serif italic text-xl text-ink/60">{essay.subtitle}</p>}
        {essay.author && <p className="mt-4 text-sm text-ink/50">By {essay.author}</p>}
      </header>

      {essay.illustration_url && (
        <div className="relative aspect-[2/1] rounded-2xl overflow-hidden mb-12">
          <Image src={essay.illustration_url} alt={essay.title} fill className="object-cover" />
        </div>
      )}

      <div className="prose-quiet text-lg max-w-none">
        {essay.body.split('\n\n').map((p: string, i: number) => <p key={i}>{p}</p>)}
      </div>
    </article>
  );
}
