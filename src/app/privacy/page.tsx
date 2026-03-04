import Link from "next/link";

export const metadata = {
  title: "Privacy Policy | NightCapt",
  description: "NightCapt privacy policy – how we collect, use, and protect your data.",
};

export default function PrivacyPage() {
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
            Privacy Policy
          </h1>
          <p className="text-nightcap-muted text-sm mb-8">
            Last updated: {new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}
          </p>

          <div className="prose prose-invert prose-sm max-w-none space-y-6 text-nightcap-muted">
            <section>
              <h2 className="text-white font-display text-xl mb-2">
                Introduction
              </h2>
              <p>
                NightCapt (&quot;we&quot;, &quot;our&quot;, or &quot;us&quot;) is a social journal app for recording and sharing your nights out. This Privacy Policy explains how we collect, use, store, and protect your information when you use our app and services.
              </p>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">
                Information We Collect
              </h2>
              <p>When you use NightCapt, we may collect:</p>
              <ul className="list-disc pl-6 mt-2 space-y-1">
                <li><strong className="text-white">Account information:</strong> Email address and password when you create an account</li>
                <li><strong className="text-white">Profile information:</strong> Display name, bio, and profile picture if you choose to add them</li>
                <li><strong className="text-white">Journal entries:</strong> Dates, ratings, photos, videos, text prompts, and timeline details you post</li>
                <li><strong className="text-white">Social data:</strong> Friends, comments, and reactions you share</li>
                <li><strong className="text-white">Technical data:</strong> Device information and usage data necessary to run the app</li>
              </ul>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">
                How We Use Your Information
              </h2>
              <p>
                We use your information to provide, maintain, and improve NightCapt, including:
              </p>
              <ul className="list-disc pl-6 mt-2 space-y-1">
                <li>Creating and managing your account</li>
                <li>Storing and displaying your journal entries and profile</li>
                <li>Enabling social features (friends, comments, reactions, leaderboards)</li>
                <li>Hosting and serving photos and media you upload</li>
                <li>Communicating with you about your account</li>
              </ul>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">
                Data Storage & Third Parties
              </h2>
              <p>
                Your data is stored and processed using Supabase, which provides our database and authentication services. Photos and media are stored in Supabase Storage. We use Vercel for hosting the app. These services have their own privacy policies and security measures.
              </p>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">
                Your Rights
              </h2>
              <p>
                You can access, update, or delete your account and data through the app. To request account deletion or data export, contact us using the details below.
              </p>
            </section>

            <section>
              <h2 className="text-white font-display text-xl mb-2">
                Contact
              </h2>
              <p>
                For privacy-related questions or requests, contact us at the email address associated with your NightCapt account or through the app support channels.
              </p>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}
