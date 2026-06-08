export const metadata = { title: 'Why HEAL' };

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
        <p className="hand text-3xl text-sage-700 mt-12">
          Be still. Breathe. Begin again.
        </p>
      </section>
    </article>
  );
}
