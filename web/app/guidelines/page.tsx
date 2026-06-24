export const metadata = {
  title: 'Community Guidelines',
  description: 'How we keep HEAL a quiet, kind space',
};

const COMPANY = 'positiveness.club';

export default function GuidelinesPage() {
  return (
    <article className="container-quiet py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Community Guidelines</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">A quiet space</h1>
        <p className="serif italic text-ink/60 text-lg">
          HEAL is contemplative, not social. Here's what that means in practice.
        </p>
      </header>

      <div className="prose-quiet max-w-2xl mx-auto space-y-10 text-ink/80 leading-relaxed">

        <section>
          <h2 className="serif text-2xl text-ink mb-3">This is not a social network</h2>
          <p>
            There are no likes, no comments, no follower counts, no public profiles, no feeds. You can favorite a
            meditation. You can write a private journal entry. You can earn a badge. You can share a meditation
            link with a friend. That's the full social surface of the platform.
          </p>
          <p className="mt-3">
            We built it this way on purpose. Contemplation does not flourish in a feed.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Your journal is yours alone</h2>
          <p>
            Journal entries you write in HEAL are private. They are stored encrypted at rest (Firestore
            default) and are only visible to you, signed in on your account. We do not read them. We do not
            scan them. We do not train any model on them. We do not share them with third parties.
          </p>
          <p className="mt-3">
            You can delete any entry at any time. When you close your account, your journal is deleted within 30 days.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Scripture and tradition</h2>
          <p>
            HEAL draws from the broad Christian tradition — Catholic, Protestant, Orthodox, and charismatic
            expressions. Where we use a specific translation, we name it. Where a meditation is rooted in
            one tradition's reading, we say so. We do not believe there is one right way to pray.
          </p>
          <p className="mt-3">
            If you come from a tradition we have not represented well, write to us. We are listening, and we
            would like to learn.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">What we will remove</h2>
          <p>
            The platform has very little user-generated content. If you write something in your journal that
            contains a public-safety threat (e.g., "I am going to harm X"), the system may notify our team
            so we can take action consistent with the law. Outside of that narrow case, your journal is yours.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">No ads, no tracking, no manipulation</h2>
          <p>
            There are no advertisements on HEAL. There is no "engagement" optimization. There are no
            notifications trying to bring you back. The platform does not use dark patterns to keep you
            scrolling. If you want to come back, we will be here. If you do not, that is also fine.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">How we moderate</h2>
          <p>
            We are a tiny team. When something needs our attention, we read it, we think about it, and we
            respond in writing. We do not use automated moderation for journal content. We do not have a
            report button on user posts, because there are no user posts. If something seems off, write to us.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Multi-track programs and badges</h2>
          <p>
            Some content on HEAL is structured as a <em>program</em> — a sequence of reflections and practices
            around a single theme. When you complete a program, you earn a badge. Badges are not public. They
            are visible to you on the Badges page. They are not used to rank you or compare you to others.
            They are a quiet reminder of the work you have done.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">A note on AI</h2>
          <p>
            Voice meditations and watercolor illustrations on HEAL are produced with the help of generative
            AI tools. The words themselves are written by humans and reviewed by humans. The AI assists
            with the audio rendering and the visual art, both of which are then curated by a human editor
            before publication.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Changes to these guidelines</h2>
          <p>
            These guidelines may be updated as the platform grows. The current version will always be at this
            URL. Substantive changes will be announced on the home page.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Operator</h2>
          <p>
            HEAL is operated by <strong>{COMPANY}</strong>. For questions, write to
            <a className="underline ml-1" href="mailto:hello@positiveness.club">hello@positiveness.club</a>.
          </p>
        </section>

      </div>
    </article>
  );
}
