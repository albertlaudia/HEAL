// HEAL — Privacy Policy page.
// Served at https://heal.positiveness.club/privacy

import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Privacy Policy — HEAL',
  description: 'How HEAL handles your data. Short version: we collect almost nothing.',
};

export default function PrivacyPage() {
  return (
    <main className="legal-page">
      <h1>Privacy Policy</h1>
      <p className="legal-updated">Last updated: 13 July 2026</p>

      <section>
        <h2>The short version</h2>
        <p>
          HEAL is a quiet Christian mindfulness practice. We do not track you
          across apps or websites. We do not show ads. We do not sell your
          data. Your practice data — streaks, favorites, and your breath
          profile — stays on your device unless you sign in and opt in to
          syncing.
        </p>
      </section>

      <section>
        <h2>What we collect, and why</h2>

        <h3>When you use HEAL without signing in</h3>
        <ul>
          <li>
            <strong>A random local identifier</strong> (a string of letters and
            numbers) is generated and stored on your device. This is what lets
            us keep your streak and stickers consistent between app sessions.
            It never leaves your device.
          </li>
          <li>
            <strong>Your practice activity</strong> (which sessions you
            started, which stickers you've earned, which praise songs you've
            favorited) is stored in the app's local storage. It never leaves
            your device.
          </li>
        </ul>

        <h3>When you sign in (Google, Apple, or email + password)</h3>
        <ul>
          <li>
            <strong>Your email address</strong> is requested from the sign-in
            provider so we can sign you in. It is stored by Firebase
            Authentication. We do not use it to send you marketing email.
          </li>
          <li>
            <strong>Your display name and avatar</strong> (if the sign-in
            provider gives them to us) are used to greet you on the home
            screen. They are stored on your device.
          </li>
          <li>
            <strong>Your random local identifier</strong> is copied to a
            per-user key on your device so we can stitch any in-flight data
            to the new account if you choose to migrate later.
          </li>
        </ul>

        <h3>When you use the Breath Studio (microphone)</h3>
        <ul>
          <li>
            If you opt in to voice calibration, the app briefly listens to
            your breath to learn your natural inhale and exhale duration.
            We never record, store, or upload the audio. Only the
            measured timing (in seconds) is kept, and only on your device.
          </li>
          <li>
            You can revoke microphone access at any time in your device
            settings.
          </li>
        </ul>

        <h3>When you enable daily reminder notifications</h3>
        <ul>
          <li>
            We schedule a local notification at the time you choose
            (typically morning or evening). The notification fires from
            your device — we do not run a push notification service.
          </li>
        </ul>
      </section>

      <section>
        <h2>What we do not collect</h2>
        <ul>
          <li>Your name, contacts, or address book.</li>
          <li>Your location (GPS or network-based).</li>
          <li>Your photos or camera.</li>
          <li>Your advertising ID, IDFA, or any cross-app identifier.</li>
          <li>Your device fingerprint.</li>
          <li>
            Any information that leaves your device is listed above; nothing
            else is sent to our servers.
          </li>
        </ul>
      </section>

      <section>
        <h2>Where your data is stored</h2>
        <p>
          Everything you create in HEAL — practice sessions, stickers,
          favorites, your breath profile — lives in your device's local
          storage (shared preferences, an encrypted SQLite database, and
          on-device file cache for offline audio).
        </p>
        <p>
          If you sign in, your authentication tokens are stored by Firebase
          Authentication (Google Cloud). Your practice data is not uploaded
          to our servers in this version of the app; it remains on your
          device.
        </p>
      </section>

      <section>
        <h2>Children's privacy</h2>
        <p>
          HEAL is appropriate for ages 4 and up. We do not knowingly collect
          personal information from children under 13. The app does not
          include chat, social features, or user-generated content visible
          to others.
        </p>
      </section>

      <section>
        <h2>Changes to this policy</h2>
        <p>
          If we make material changes, we will show an in-app notice and
          update the date at the top of this page.
        </p>
      </section>

      <section>
        <h2>Contact</h2>
        <p>
          Questions or concerns? Email <a href="mailto:privacy@heal.positiveness.club">privacy@heal.positiveness.club</a>.
        </p>
      </section>
    </main>
  );
}
