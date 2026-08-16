"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { AuthMethod, AuthMethodToggle, UkAuthNotice } from "@/components/AuthMethodToggle";
import { NeonLogo } from "@/components/NeonLogo";
import { PhoneOtpForm } from "@/components/PhoneOtpForm";
import { getAuthCallbackUrl } from "@/lib/auth-redirect";
import { toFriendlyAuthMessage } from "@/lib/auth-errors";
import { prefersUkPhoneAuth } from "@/lib/uk-auth";
import { createClient } from "@/lib/supabase/client";

const inputClass =
  "w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none";

export default function SignUpPage() {
  const [method, setMethod] = useState<AuthMethod>("phone");
  const [forcedToEmail, setForcedToEmail] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [acceptedTerms, setAcceptedTerms] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!prefersUkPhoneAuth()) {
      setMethod("email");
    }
  }, []);

  const termsAcceptedAt = () => new Date().toISOString();

  const persistTerms = async (userId: string, acceptedAt: string) => {
    const supabase = createClient();
    await supabase.from("profiles").update({ terms_accepted_at: acceptedAt }).eq("id", userId);
  };

  const handleEmailSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!acceptedTerms) {
      setError("You must agree to the Terms of Use and Privacy Policy");
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const acceptedAt = termsAcceptedAt();
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { full_name: displayName, terms_accepted_at: acceptedAt },
        emailRedirectTo: getAuthCallbackUrl(),
      },
    });

    if (error) {
      setError(toFriendlyAuthMessage(error.message));
      setLoading(false);
      return;
    }

    if (data.user) {
      await persistTerms(data.user.id, acceptedAt);
    }

    setMessage("Check your email to confirm your account!");
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-nightcap flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="mb-8">
          <NeonLogo className="text-4xl" />
        </div>
        <div className="glass rounded-2xl p-8 neon-glow">
          <h1 className="text-3xl font-semibold text-white mb-2">Create account</h1>
          <UkAuthNotice method={method} intent="signup" />

          <AuthMethodToggle value={method} onChange={setMethod} />

          {forcedToEmail && method === "email" && (
            <p className="mb-4 rounded-xl border border-nightcap-accent/40 bg-nightcap-accent/10 px-4 py-3 text-sm text-white">
              Phone login is for UK numbers only. Continue with email.
            </p>
          )}

          <div className="space-y-4">
            <div>
              <label htmlFor="displayName" className="block text-sm text-nightcap-muted mb-2">
                Display name
              </label>
              <input
                id="displayName"
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className={inputClass}
                placeholder="Your name"
              />
            </div>

            <label className="flex items-start gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={acceptedTerms}
                onChange={(e) => setAcceptedTerms(e.target.checked)}
                className="mt-1 rounded border-white/20"
              />
              <span className="text-sm text-nightcap-muted">
                I agree to the{" "}
                <Link href="/privacy" className="text-nightcap-accent hover:underline">
                  Terms of Use, Privacy Policy and Support
                </Link>
                . I understand there is zero tolerance for objectionable content.
              </span>
            </label>

            {method === "phone" ? (
              <PhoneOtpForm
                shouldCreateUser
                submitLabel="Send verification code"
                metadata={() => ({
                  full_name: displayName,
                  terms_accepted_at: termsAcceptedAt(),
                })}
                validateBeforeSend={() =>
                  acceptedTerms ? null : "You must agree to the Terms of Use and Privacy Policy"
                }
                onVerified={async (userId) => {
                  await persistTerms(userId, termsAcceptedAt());
                }}
                onRequireEmail={() => {
                  setForcedToEmail(true);
                  setMethod("email");
                }}
              />
            ) : (
              <form onSubmit={handleEmailSignUp} className="space-y-4">
                <div>
                  <label htmlFor="email" className="block text-sm text-nightcap-muted mb-2">
                    Email
                  </label>
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className={inputClass}
                    placeholder="you@example.com"
                  />
                </div>
                <div>
                  <label htmlFor="password" className="block text-sm text-nightcap-muted mb-2">
                    Password
                  </label>
                  <input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    minLength={6}
                    className={inputClass}
                    placeholder="••••••••"
                  />
                </div>
                {error && <p className="text-red-400 text-sm">{error}</p>}
                {message && <p className="text-night-mint text-sm">{message}</p>}
                <button
                  type="submit"
                  disabled={loading || !acceptedTerms}
                  className="w-full rounded-xl bg-nightcap-accent px-4 py-3 font-medium text-white transition hover:opacity-90 disabled:opacity-50"
                >
                  {loading ? "Creating account..." : "Sign up"}
                </button>
              </form>
            )}
          </div>

          <p className="mt-6 text-center text-sm text-nightcap-muted">
            Already have an account?{" "}
            <Link href="/auth/signin" className="text-nightcap-accent hover:underline">
              Sign in
            </Link>
          </p>
          <p className="mt-4 text-center">
            <Link href="/privacy" className="text-xs text-nightcap-muted hover:text-nightcap-accent transition">
              Terms, Privacy & Support
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
