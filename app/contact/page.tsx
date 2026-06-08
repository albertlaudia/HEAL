export const metadata = { title: 'Contact' };
export default function ContactPage() {
  return (
    <article className="container-quiet py-16">
      <h1 className="serif text-4xl md:text-5xl mb-8">Contact</h1>
      <p className="text-ink/70 mb-8 serif italic">A few good ways to reach us.</p>
      <div className="space-y-4">
        <Row label="General" email="hello@heal.example.com" />
        <Row label="Pastoral use" email="pastoral@heal.example.com" />
        <Row label="Press" email="press@heal.example.com" />
        <Row label="Privacy" email="privacy@heal.example.com" />
        <Row label="Support" email="support@heal.example.com" />
      </div>
    </article>
  );
}
function Row({ label, email }: { label: string; email: string }) {
  return (
    <div className="card-quiet p-5 flex items-center justify-between">
      <p className="serif text-lg">{label}</p>
      <a href={`mailto:${email}`} className="text-ink/70 hover:text-ink text-sm underline">{email}</a>
    </div>
  );
}
