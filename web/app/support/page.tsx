// HEAL — Support page.
// Served at https://heal.positiveness.club/support

import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Support — HEAL',
  description: 'Get help with HEAL — the quiet Christian mindfulness practice.',
};

export default function SupportPage() {
  return (
    <main className="legal-page">
      <h1>Support</h1>
      <p className="legal-updated">Need help? Start here.</p>

      <section>
        <h2>Common questions</h2>

        <h3>I can't hear any audio</h3>
        <p>
          Check that your device is not muted and that the volume is turned up.
          If you're on a public Wi-Fi network, some schools and offices block
          audio streams — try a different network or download the track for
          offline playback from the song's detail page.
        </p>

        <h3>How do I turn off daily reminders?</h3>
        <p>
          Open HEAL → Settings → Daily Reminders, and turn off Morning and/or
          Evening. You can also disable notifications at the device level in
          your iOS or Android settings.
        </p>

        <h3>How do I delete my account?</h3>
        <p>
          Email <a href="mailto:privacy@heal.positiveness.club">privacy@heal.positiveness.club</a>{' '}
          from the address you signed in with, and we'll delete your account
          within 7 days.
        </p>

        <h3>How do I delete the app's local data?</h3>
        <p>
          On iOS: Settings → General → iPhone Storage → HEAL → Delete App.
          On Android: Settings → Apps → HEAL → Storage → Clear Data.
          This removes everything stored on your device, including your
          practice history, stickers, and breath profile.
        </p>
      </section>

      <section>
        <h2>Bug reports and feature requests</h2>
        <p>
          Email <a href="mailto:support@heal.positiveness.club">support@heal.positiveness.club</a>{' '}
          with as much detail as you can — your device model, iOS or Android
          version, and what you were doing when the issue happened.
          Screenshots help a lot.
        </p>
      </section>

      <section>
        <h2>Press &amp; partnerships</h2>
        <p>
          Email <a href="mailto:hello@heal.positiveness.club">hello@heal.positiveness.club</a>.
        </p>
      </section>
    </main>
  );
}
