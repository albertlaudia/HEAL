// HEAL — Terms of Service page.
// Served at https://heal.positiveness.club/terms

import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Terms of Service — HEAL',
  description: 'Terms of using HEAL.',
};

export default function TermsPage() {
  return (
    <main className="legal-page">
      <h1>Terms of Service</h1>
      <p className="legal-updated">Last updated: 13 July 2026</p>

      <section>
        <h2>The short version</h2>
        <p>
          HEAL is a wellness app, not a substitute for medical, psychological,
          or pastoral care. If you are in crisis, please contact a licensed
          professional or call your local emergency number.
        </p>
      </section>

      <section>
        <h2>Acceptable use</h2>
        <p>
          You agree to use HEAL for personal, non-commercial reflection. You
          will not use the app to harass, defame, or harm others, and you will
          not attempt to disrupt the service.
        </p>
      </section>

      <section>
        <h2>Content ownership</h2>
        <p>
          All scripture quotations, prayers, and reflections in HEAL are
          provided for personal devotion. Public-domain translations (KJV,
          WEB) may be freely shared. Modern translations (NIV, ESV, NLT) are
          used under license and may not be republished outside the app.
        </p>
        <p>
          Your practice data — sessions, favorites, breath profile — is yours.
          We do not claim ownership of it.
        </p>
      </section>

      <section>
        <h2>No warranty</h2>
        <p>
          HEAL is provided "as is" without warranty of any kind. We try our
          best to make it gentle, accurate, and reliable, but we cannot
          guarantee that the service will be uninterrupted or error-free.
        </p>
      </section>

      <section>
        <h2>Limitation of liability</h2>
        <p>
          To the maximum extent permitted by law, the makers of HEAL are not
          liable for any indirect, incidental, or consequential damages
          arising from your use of the app.
        </p>
      </section>

      <section>
        <h2>Changes</h2>
        <p>
          We may update these terms from time to time. If we do, we will show
          an in-app notice and update the date at the top of this page.
        </p>
      </section>

      <section>
        <h2>Contact</h2>
        <p>
          Questions about these terms? Email{' '}
          <a href="mailto:legal@heal.positiveness.club">legal@heal.positiveness.club</a>.
        </p>
      </section>
    </main>
  );
}
