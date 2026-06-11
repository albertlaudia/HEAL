export const metadata = {
  title: 'Terms of Service',
  description: 'Terms of service for HEAL by positiveness.club',
};

const EFFECTIVE = '2026-06-11';
const CONTACT_EMAIL = 'hello@positiveness.club';
const COMPANY = 'positiveness.club';
const PRODUCT = 'HEAL';

export default function TermsPage() {
  return (
    <article className="container-quiet py-16">
      <header className="max-w-2xl mb-12">
        <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">Terms of Service</p>
        <h1 className="serif text-5xl md:text-6xl mb-4">The agreement</h1>
        <p className="serif italic text-ink/60 text-lg">
          These terms cover your use of {PRODUCT} by {COMPANY}. They are written plainly because that is how we communicate.
        </p>
        <p className="text-xs text-ink/40 mt-6">Effective: {EFFECTIVE}</p>
      </header>

      <div className="prose-quiet max-w-2xl mx-auto space-y-10 text-ink/80 leading-relaxed">

        <section>
          <h2 className="serif text-2xl text-ink mb-3">1. Who we are</h2>
          <p>
            {PRODUCT} ("the platform", "we", "us") is a Christian mindfulness and meditation service operated by
            <strong> {COMPANY}</strong> ("the company"). The platform offers guided meditations, breathwork, scripture
            readings, prayers, praise music, essays, multi-step programs, journal entries, favorites, and badges
            (collectively "the Service").
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">2. Acceptance of terms</h2>
          <p>
            By using {PRODUCT} you agree to these terms and to our <a href="/privacy" className="underline">Privacy
            Policy</a>. If you do not agree, please do not use the Service.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">3. The Service is free</h2>
          <p>
            {PRODUCT} is currently offered free of charge. We may introduce paid features in the future; we will
            notify existing users in advance and any paid features will be clearly marked. Past free content
            will remain free.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">4. Eligibility</h2>
          <p>
            You must be at least 13 years old to create an account. If you are under 18, please have a parent or
            guardian review these terms with you. The Service is intended for personal, non-commercial use.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">5. Accounts</h2>
          <p>
            Account creation is optional. If you create an account, you agree to:
          </p>
          <ul className="list-disc pl-6 space-y-1 mt-3">
            <li>Provide accurate information (a valid email if you sign up with email)</li>
            <li>Keep your password secure (we will never ask for it)</li>
            <li>Be responsible for activity on your account</li>
            <li>Tell us promptly if you suspect unauthorized access</li>
          </ul>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">6. Your content</h2>
          <p>
            Journal entries, favorites, and any other content you create are <strong>yours</strong>. You retain all rights to your content.
            You grant us a limited license to store, display, and process that content only as needed to provide
            the Service to you. We will not sell, license, or share your journal entries or other personal content
            with third parties.
          </p>
          <p className="mt-3">
            If you delete content or close your account, we will delete that content from our active databases within
            30 days. Backup copies may persist for an additional 90 days before being overwritten.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">7. Acceptable use</h2>
          <p>You agree not to:</p>
          <ul className="list-disc pl-6 space-y-1 mt-3">
            <li>Use the Service to harass, threaten, or harm anyone</li>
            <li>Post content that is unlawful, defamatory, hateful, sexually explicit, or that infringes a third party's rights</li>
            <li>Attempt to access the Service by means other than the interface we provide</li>
            <li>Reverse engineer, decompile, or otherwise attempt to extract source code from the platform</li>
            <li>Use the Service to build a competing product</li>
            <li>Interfere with or disrupt the Service or its security features</li>
            <li>Upload viruses, malware, or anything designed to harm the platform or other users</li>
            <li>Scrape, mine, or harvest user data without permission</li>
            <li>Impersonate {COMPANY} staff, partners, or other users</li>
          </ul>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">8. Spiritual and pastoral content</h2>
          <p>
            {PRODUCT} offers content rooted in Christian scripture and contemplative practice. This content is
            <strong> pastoral and reflective, not medical, psychological, or legal advice</strong>. It is not a
            substitute for professional mental health care, medical care, or legal counsel. If you are in crisis
            or facing a serious life issue, please contact a licensed professional, your local emergency services,
            or a trusted spiritual advisor in your tradition. In the United States, the 988 Suicide & Crisis
            Lifeline is available 24/7 by dialing 988.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">9. Scripture translations</h2>
          <p>
            Unless otherwise noted, scripture quotations on the platform are from the New Revised Standard
            Version (NRSV), © 1989 National Council of Churches. All rights reserved. Used by permission.
            Quotations from other translations (NIV, KJV, ESV) are used under fair use for educational and
            devotional purposes.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">10. Music and audio</h2>
          <p>
            Voice meditations are generated by an AI text-to-speech engine. Praise songs whose lyrics are
            public domain or written for the platform are offered freely. Where a song is based on a copyrighted
            hymn tune, the words are presented as a derivative devotional work; the underlying tune remains the
            property of its composer or estate. We provide chords for personal practice; please contact us for
            permissions to record or perform these settings publicly.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">11. Illustrations</h2>
          <p>
            Watercolor illustrations on the platform are AI-generated originals created for {PRODUCT}. They are
            not photographs of identifiable people, places, or works. You may use them for personal devotion. You
            may not redistribute them commercially without permission.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">12. Intellectual property</h2>
          <p>
            The platform's source code, design, illustrations, original meditations, original prayers, original
            essays, and the {PRODUCT} name and logo are owned by {COMPANY} and protected by copyright. The
            underlying source code is proprietary. The content (meditations, prayers, scriptures) is offered for
            personal use; please do not republish it commercially without permission.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">13. Service availability</h2>
          <p>
            We work hard to keep {PRODUCT} available, but we do not guarantee uninterrupted access. The Service
            is provided "as is" and "as available". We may modify, suspend, or discontinue any part of the
            Service at any time, with reasonable notice where practical.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">14. Disclaimer of warranties</h2>
          <p>
            The Service is provided "as is" without warranties of any kind, express or implied, including but not
            limited to warranties of merchantability, fitness for a particular purpose, and non-infringement.
            We do not warrant that the Service will be uninterrupted, error-free, or free of harmful components,
            or that defects will be corrected.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">15. Limitation of liability</h2>
          <p>
            To the fullest extent permitted by law, {COMPANY} shall not be liable for any indirect, incidental,
            special, consequential, or punitive damages arising from or related to your use of the Service. Our
            total liability for any claim shall not exceed USD $100 or the amount you have paid us in the
            preceding 12 months, whichever is greater.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">16. Indemnification</h2>
          <p>
            You agree to indemnify and hold {COMPANY} and its officers, directors, employees, and agents
            harmless from any claim, demand, loss, or expense (including reasonable legal fees) arising from
            your use of the Service, your violation of these terms, or your violation of any third party's
            rights.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">17. Termination</h2>
          <p>
            We may suspend or terminate your access to the Service at any time if we reasonably believe you
            have violated these terms. Where appropriate, we will give you notice and an opportunity to cure.
            You may close your account at any time from the account menu.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">18. Changes to these terms</h2>
          <p>
            We may update these terms from time to time. If a change is material, we will give you notice on
            the platform or by email. Continued use of the Service after a change means you accept the updated
            terms. The most current version will always be at this URL.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">19. Governing law</h2>
          <p>
            These terms are governed by the laws of the jurisdiction in which {COMPANY} is incorporated, without
            regard to conflict of law principles. Any dispute arising from these terms shall be resolved in the
            courts of that jurisdiction, except where local law provides otherwise for consumer protection.
          </p>
        </section>

        <section>
          <h2 className="serif text-2xl text-ink mb-3">20. Contact</h2>
          <p>
            Questions, complaints, or requests about these terms can be sent to
            <a className="underline ml-1" href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
          </p>
        </section>

      </div>
    </article>
  );
}
