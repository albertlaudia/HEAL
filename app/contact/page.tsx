export const metadata = {
  title: 'Contact',
  description: 'Reach HEAL by positiveness.club',
};

const EMAIL = 'hello@positiveness.club';

export default function ContactPage() {
  return (
    <article className="container-quiet py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Contact</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">Reach us</h1>
        <p className="serif italic text-ink/60 text-lg">
          HEAL is a small, quiet project. We read every message, and we try to respond within a few days.
        </p>
      </header>

      <div className="max-w-2xl mx-auto space-y-8">
        <div className="card-quiet p-8">
          <h2 className="serif text-2xl text-ink mb-3">Email</h2>
          <p className="text-ink/70 mb-4">For everything: questions, bug reports, partnership ideas, prayer requests, love letters.</p>
          <a
            href={`mailto:${EMAIL}`}
            className="inline-flex items-center gap-2 text-lg text-sage-700 hover:text-sage-800 underline underline-offset-4"
          >
            {EMAIL}
          </a>
        </div>

        <div className="card-quiet p-8">
          <h2 className="serif text-2xl text-ink mb-3">What we can help with</h2>
          <ul className="space-y-2 text-ink/75 list-disc pl-6">
            <li>Account questions (sign in, password reset, deletion)</li>
            <li>Bug reports or accessibility issues</li>
            <li>Content suggestions (a meditation, a prayer, a song)</li>
            <li>Theological or pastoral feedback (we welcome it)</li>
            <li>Permissions to translate, perform, or republish content</li>
            <li>Press, partnership, or licensing inquiries</li>
          </ul>
        </div>

        <div className="card-quiet p-8">
          <h2 className="serif text-2xl text-ink mb-3">What we can't do</h2>
          <p className="text-ink/70 mb-3">HEAL is a contemplative platform, not a substitute for professional care:</p>
          <ul className="space-y-2 text-ink/75 list-disc pl-6">
            <li>We are not licensed therapists, counselors, or medical professionals</li>
            <li>We do not provide crisis intervention — please call 988 (US) or your local equivalent</li>
            <li>We do not provide legal advice, financial advice, or diagnostic opinions</li>
            <li>We do not endorse specific churches, denominations, or theological positions beyond what the platform's content itself states</li>
          </ul>
          <p className="mt-3 text-ink/70">
            If you are in spiritual or emotional crisis, please reach out to a pastor, priest, or trusted friend in your tradition. If you are in medical or psychiatric crisis, please call your local emergency number or 988.
          </p>
        </div>

        <div className="card-quiet p-8">
          <h2 className="serif text-2xl text-ink mb-3">Operator</h2>
          <p className="text-ink/75">
            <strong>HEAL</strong> is operated by <strong>positiveness.club</strong>, a small studio that
            builds quiet, kind, useful things for the web. We believe the digital world can be a calmer
            place than it often is, and we make tools to help.
          </p>
          <p className="mt-3 text-ink/70 text-sm">
            For more about us, see <a href="https://positiveness.club" className="underline" target="_blank" rel="noopener noreferrer">positiveness.club</a>.
          </p>
        </div>

        <div className="card-quiet p-8">
          <h2 className="serif text-2xl text-ink mb-3">Mailing address</h2>
          <p className="text-ink/70 text-sm">
            positiveness.club<br />
            [registered address on file — write to {EMAIL} for the current address]
          </p>
        </div>
      </div>
    </article>
  );
}
