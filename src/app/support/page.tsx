import Link from "next/link";

export const metadata = {
  title: "Support | NightCapt",
  description: "Get help with NightCapt – contact support, FAQs, and more.",
};

export default function SupportPage() {
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
            Support
          </h1>
          <p className="text-nightcap-muted text-sm mb-8">
            Need help? We&apos;re here for you.
          </p>

          <div className="space-y-8 text-nightcap-muted">
            <section>
              <h2 className="text-white font-display text-xl mb-2">Contact us</h2>
              <p>
                For questions, feedback, or support requests, email us at{" "}
                <a
                  href="mailto:nightcapt1@outlook.com"
                  className="text-nightcap-accent hover:underline"
                >
                  nightcapt1@outlook.com
                </a>
              </p>
              <p className="mt-2 text-sm">
                We aim to respond within 24–48 hours.
              </p>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">Common questions</h2>
              <ul className="space-y-3 text-sm">
                <li>
                  <strong className="text-white">How do I reset my password?</strong>
                  <br />
                  Use &quot;Forgot password&quot; on the sign-in screen.
                </li>
                <li>
                  <strong className="text-white">How do I delete my account?</strong>
                  <br />
                  Go to Profile → Settings → Delete account.
                </li>
                <li>
                  <strong className="text-white">How do I report inappropriate content?</strong>
                  <br />
                  Tap the three dots on any entry or comment → Report.
                </li>
                <li>
                  <strong className="text-white">How do I block someone?</strong>
                  <br />
                  Open their profile → Block user.
                </li>
              </ul>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">Resources</h2>
              <ul className="space-y-2">
                <li>
                  <Link href="/privacy" className="text-nightcap-accent hover:underline">
                    Privacy Policy
                  </Link>
                </li>
                <li>
                  <Link href="/terms" className="text-nightcap-accent hover:underline">
                    Terms of Use
                  </Link>
                </li>
              </ul>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}
