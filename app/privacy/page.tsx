export const metadata = { title: 'Privacy' };
export default function PrivacyPage() {
  return (
    <article className="container-quiet py-16 prose-quiet">
      <h1 className="serif text-4xl md:text-5xl mb-8">Privacy</h1>
      <p>HEAL is a quiet, private space. We do not require an account to use it. We do not sell your data. We do not run ads.</p>
      <h2 className="serif text-2xl mt-8 mb-3">What we store locally</h2>
      <p>On your device, we keep a small list of meditations you have visited, and your theme preferences. You can clear it at any time by clearing your browser's site data for HEAL.</p>
      <h2 className="serif text-2xl mt-8 mb-3">What we do not collect</h2>
      <p>We do not collect names, emails, or any personal information. We do not track you across the web. We do not use third-party analytics that identify you.</p>
      <h2 className="serif text-2xl mt-8 mb-3">Cookies</h2>
      <p>HEAL uses a small number of essential cookies (for example, to remember your audio volume preference). We do not use advertising cookies.</p>
      <h2 className="serif text-2xl mt-8 mb-3">Contact</h2>
      <p>If you have a privacy question, write to us at <a href="mailto:hello@heal.example.com" className="underline">hello@heal.example.com</a>.</p>
    </article>
  );
}
