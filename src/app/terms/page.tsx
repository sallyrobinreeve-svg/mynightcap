import Link from "next/link";

export const metadata = {
  title: "Terms of Use | NightCapt",
  description: "NightCapt Terms of Use and End User License Agreement.",
};

export default function TermsPage() {
  return (
    <div className="min-h-screen playful-bg py-12 px-4">
      <div className="max-w-2xl mx-auto">
        <Link
          href="/"
          className="inline-block text-nightcap-muted hover:text-nightcap-accent mb-8 transition"
        >
          ← Back
        </Link>
        <div className="glass rounded-2xl p-8">
          <h1 className="font-display text-3xl gradient-text mb-2">
            Terms of Use
          </h1>
          <p className="text-nightcap-muted text-sm mb-8">
            Last updated: {new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}
          </p>

          <div className="prose prose-invert prose-sm max-w-none space-y-6 text-nightcap-muted">
            <section>
              <h2 className="text-white font-display text-xl mb-2">Agreement</h2>
              <p>
                By using NightCapt, you agree to these Terms of Use and our Privacy Policy. If you do not agree, do not use the app.
              </p>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">User-Generated Content – Zero Tolerance</h2>
              <p>
                <strong className="text-white">NightCapt has zero tolerance for objectionable content or abusive users.</strong> You must not post, share, or upload:
              </p>
              <ul className="list-disc pl-6 mt-2 space-y-1">
                <li>Content that is illegal, harmful, threatening, abusive, harassing, defamatory, obscene, or otherwise objectionable</li>
                <li>Content that infringes others&apos; rights or privacy</li>
                <li>Spam, impersonation, or misleading content</li>
              </ul>
              <p className="mt-2">
                We reserve the right to remove any content and suspend or terminate accounts that violate these terms. We act on reports within 24 hours.
              </p>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">Reporting & Blocking</h2>
              <p>
                You can report objectionable content and block abusive users in the app. When you block someone, their content is removed from your feed immediately. Reports are reviewed and we take action within 24 hours.
              </p>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">Your Responsibility</h2>
              <p>
                You are responsible for your content and conduct. You grant us a license to host, display, and share your content as needed to operate the service.
              </p>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">Contact</h2>
              <p>
                For questions about these terms, contact us at{" "}
                <a href="mailto:support@mynightcap.vercel.app" className="text-nightcap-accent hover:underline">
                  support@mynightcap.vercel.app
                </a>
              </p>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}
