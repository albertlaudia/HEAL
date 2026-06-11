export const metadata = {
  title: 'Privacy',
  description: 'How HEAL handles your data. Quiet, private, transparent.',
};

const EFFECTIVE = '2026-06-11';
const CONTACT_EMAIL = 'hello@positiveness.club';

export default function PrivacyPage() {
  return (
    <article className="container-quiet py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Privacy</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">How we handle your data</h1>
        <p className="serif italic text-ink/60 text-lg">
          HEAL is a quiet, private space. This page explains what we store, what we don't, and how to reach us.
        </p>
        <p className="text-xs text-ink/40 mt-6">Effective: {EFFECTIVE} · HEAL by positiveness.club</p>
      </header>

      <div className="prose-quiet max-w-2xl mx-auto space-y-10 text-ink/80 leading-relaxed">

        <section>
          <h2 className="serif text-2xl text-ink mb-3">The short version</h2>
          <p>
            HEAL is a Christian mindfulness platform. To use most of the platform you do not need an account.
            We do not sell your data. We do not run ads. We do not track you across the web. If you create an
            account (optional), we store the minimum data needed to make the experience yours: favorites, journal
            entries, practice history, and earned badges.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">What we store locally on your device</h2>
          <p>
            Even without an account, HEAL keeps a small amount of data in your browser's localStorage so the
            experience remembers you between visits:
          </p>
          <ul className="list-disc pl-6 space-y-1 mt-3">
            <li>Recently viewed meditations, scriptures, and prayers (last 12 items)</li>
            <li>Your audio volume preference</li>
            <li>Whether the audio mini-player is open</li>
            <li>Service-worker cache (so the app works offline)</li>
          </ul>
          <p className="mt-3">You can clear all of this at any time by clearing your browser's site data for HEAL.</p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">If you create an account</h2>
          <p>Account data is stored with Firebase Authentication and Firestore. We store:</p>
          <ul className="list-disc pl-6 space-y-1 mt-3">
            <li><strong>Authentication:</strong> Firebase Auth user id (uid). Email only if you sign up with email.</li>
            <li><strong>Favorites:</strong> slugs of meditations / scriptures / prayers / praises you save</li>
            <li><strong>Journal:</strong> your private reflection entries (text only; you can delete any of them)</li>
            <li><strong>History:</strong> last 50 items you've viewed, debounced to avoid noise</li>
            <li><strong>Program progress:</strong> which multi-step programs you've started and which steps are complete</li>
            <li><strong>Badges:</strong> badges you've earned by completing a program</li>
            <li><strong>Session token:</strong> an HTTP-only JWT cookie, valid 14 days, used to authenticate the Firestore data layer</li>
          </ul>
          <p className="mt-3">We do not store your password (Firebase Auth handles this). We do not store payment data (the platform is free).</p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Static content (no account needed)</h2>
          <p>
            Meditations, prayers, scriptures, breathwork, praise songs, and essays are served from PocketBase (a
            content store hosted at <code className="text-ink/70">pocketbase.scaleupcrm.com</code>). Reading any
            of this content is anonymous — we do not log who reads what.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Audio and illustrations</h2>
          <p>
            Voice meditations and watercolor illustrations are served either from our own server (in
            <code className="text-ink/70"> /public/audio/</code> and <code className="text-ink/70">/public/images/</code>) or
            from Backblaze B2 (cloud storage). When you play an audio or load an image, your browser makes a
            standard HTTP request — we do not embed tracking pixels or analytics in those requests.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Cookies and similar</h2>
          <p>HEAL uses a small set of cookies, none of which are for advertising:</p>
          <ul className="list-disc pl-6 space-y-1 mt-3">
            <li><strong>heal_session</strong> — JWT session token, HTTP-only, 14 days, signed with the server's secret</li>
            <li><strong>__session</strong> — Firebase Auth cookie (only if you sign in)</li>
            <li><strong>heal_recently_viewed_v1</strong> — localStorage key (not a cookie) holding the last 12 items you viewed</li>
          </ul>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Third-party services</h2>
          <p>To run the platform we rely on a small number of carefully chosen services:</p>
          <ul className="list-disc pl-6 space-y-1 mt-3">
            <li><strong>Firebase Auth + Firestore</strong> (Google) — for your account and personal data</li>
            <li><strong>PocketBase</strong> (self-hosted at scaleupcrm.com) — for static content</li>
            <li><strong>Backblaze B2</strong> (cloud storage) — for media files</li>
            <li><strong>Dokploy</strong> (self-hosted) — for application deployment</li>
            <li><strong>GitHub</strong> — for source code hosting</li>
          </ul>
          <p className="mt-3">None of these services are used to track you across the web, build advertising profiles, or sell your data.</p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Children</h2>
          <p>
            HEAL is intended for adults. The platform is not directed to children under 13, and we do not knowingly
            collect personal information from children. If you are a parent and believe your child has created an
            account, write to us at <a className="underline" href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a> and
            we will delete the account.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Your rights</h2>
          <p>You can, at any time:</p>
          <ul className="list-disc pl-6 space-y-1 mt-3">
            <li>Delete your account (and all associated Firestore data) from the account menu</li>
            <li>Delete any specific journal entry, favorite, or badge</li>
            <li>Export your data (favorites, journal, badges) as JSON</li>
            <li>Clear local browser data by clearing site data for HEAL in your browser settings</li>
          </ul>
          <p className="mt-3">For anything not covered by a button in the UI, write to <a className="underline" href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.</p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Changes to this policy</h2>
          <p>
            If we change this policy in a way that affects you, we will note the change at the top with a new
            effective date. Material changes will also be communicated on the home page.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">Contact</h2>
          <p>
            HEAL is operated by <strong>positiveness.club</strong>. For any privacy question, write to
            <a className="underline ml-1" href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
          </p>
        </section>

      </div>
    </article>
  );
}
