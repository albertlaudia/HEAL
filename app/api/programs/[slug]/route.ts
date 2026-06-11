import { NextResponse } from 'next/server';
import { getProgramBySlug } from '@/lib/pb';

export const dynamic = 'force-dynamic';

export async function GET(_req: Request, { params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const program = await getProgramBySlug(slug);
  if (!program) return NextResponse.json({ error: 'not found' }, { status: 404 });
  return NextResponse.json({
    slug: program.slug,
    title: program.title,
    tagline: program.tagline,
    step_count: program.step_count,
    theme_color: program.theme_color,
    badge_name: program.badge_name,
  });
}
