import Link from 'next/link';
import { Pause, Wind, BookOpen, Sparkles, ArrowRight } from 'lucide-react';

export const metadata = { title: 'Why HEAL' };

const PRINCIPLES = [
  {
    letter: 'H', word: 'Halt', icon: Pause,
    color: 'text-amber-700', bg: 'bg-amber-50/60', border: 'border-amber-200/60',
    body: 'Pause your busy day, step away from distractions, and intentionally stop striving. The first movement of HEAL is to stop.',
  },
  {
    letter: 'E', word: 'Exhale', icon: Wind,
    color: 'text-cyan-700', bg: 'bg-cyan-50/60', border: 'border-cyan-200/60',
    body: 'Breathe out anxiety and release your daily burdens to God. The breath is a small sacrament — what you exhale, you give away.',
  },
  {
    letter: 'A', word: 'Align', icon: BookOpen,
    color: 'text-sage-700', bg: 'bg-sage-50/60', border: 'border-sage-200/60',
    body: 'Bring your racing thoughts and spirit back into alignment with God\'s Word and the present moment. What we attend to, we become.',
  },
  {
    letter: 'L', word: 'Listen', icon: Sparkles,
    color: 'text-indigo-700', bg: 'bg-indigo-50/60', border: 'border-indigo-200/60',
    body: 'Be still in the silence and listen for the gentle guidance of the Holy Spirit. The still, small voice speaks in the quiet.',
  },
];

export default function AboutPage() {
  return (
    <article className="container-quiet py-16">
      <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">The story</p>
      <h1 className="serif text-5xl md:text-6xl mb-8">Why HEAL</h1>

      <section className="prose-quiet text-lg">
        <p>
          Most of us are tired. Not the kind of tired that one good night's sleep fixes — the other kind. The kind that lives in the shoulders, in the chest, in the part of you that checks email even when you're not at work.
        </p>
        <p>
          The world's wisdom traditions have, for thousands of years, offered an answer: <em>be still. Pay attention. Breathe. Return.</em> The Christian tradition, in particular, is rich with this — the Desert Mothers and Fathers, the Jesus Prayer, the Lectio Divina, the simple instruction of the Psalmist: "Be still, and know that I am God."
        </p>
        <p>
          HEAL is a small attempt to gather that wisdom into a daily practice. A short meditation. A passage. A breath. A prayer. A word to carry with you into the day.
        </p>
        <p>
          We are not therapists. We are not theologians. We are people who needed this ourselves, and we made it for anyone who might need it too. Whatever you believe, you are welcome here. Whatever you're carrying, you don't have to put it down at the door.
        </p>
      </section>

      {/* H.E.A.L. Framework */}
      <section className="mt-20">
        <div className="text-center mb-10">
          <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-2">The framework</p>
          <h2 className="serif text-3xl md:text-4xl">A small rhythm called H.E.A.L.</h2>
          <p className="serif italic text-ink/55 mt-3 max-w-xl mx-auto">
            Four letters, four steps. A practice you can return to in two minutes or twenty.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 gap-4 max-w-3xl mx-auto">
          {PRINCIPLES.map(p => {
            const Icon = p.icon;
            return (
              <div key={p.letter} className={`card-quiet p-6 ${p.bg} ${p.border} border`}>
                <div className="flex items-baseline gap-3 mb-3">
                  <span className={`serif text-4xl ${p.color} leading-none font-light`}>{p.letter}</span>
                  <span className="text-xs tracking-widest uppercase text-ink/60">{p.word}</span>
                  <Icon size={16} className={`${p.color} ml-auto`} />
                </div>
                <p className="text-sm text-ink/75 leading-relaxed">{p.body}</p>
              </div>
            );
          })}
        </div>

        <p className="text-center mt-10 text-sm text-ink/60 max-w-2xl mx-auto">
          Each step takes seconds. The whole practice takes as little as 90 seconds if you are short on time, or as long as twenty minutes if you have it. The point is not the duration — it is the returning.
        </p>

        <div className="text-center mt-10">
          <Link href="/" className="btn-primary">
            Begin today's practice
            <ArrowRight size={16} />
          </Link>
        </div>
      </section>

      {/* Closing benediction */}
      <section className="mt-24 text-center">
        <p className="hand text-3xl text-sage-700">
          Be still. Breathe. Begin again.
        </p>
      </section>
    </article>
  );
}
