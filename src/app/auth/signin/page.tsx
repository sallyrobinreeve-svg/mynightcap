"use client";

import { useState } from "react";
import Link from "next/link";
import { AuthMethod, AuthMethodToggle } from "@/components/AuthMethodToggle";
import { PhoneOtpForm } from "@/components/PhoneOtpForm";
import { getAuthCallbackUrl } from "@/lib/auth-redirect";
import { toFriendlyAuthMessage } from "@/lib/auth-errors";
import { createClient } from "@/lib/supabase/client";

const inputClass =
  "w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none";

export default function SignInPage() {
  const [method, setMethod] = useState<AuthMethod>("phone");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      setError(toFriendlyAuthMessage(error.message));
      setLoading(false);
      return;
    }

    setMessage("Signed in! Redirecting...");
    window.location.href = "/";
  };

  const handleMagicLink = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: getAuthCallbackUrl(),
      },
    });

    if (error) {
      setError(toFriendlyAuthMessage(error.message));
      setLoading(false);
      return;
    }

    setMessage("Check your email for the magic link!");
    setLoading(false);
  };

  const handlePasswordReset = async () => {
    if (!email) {
      setError("Enter your email address first.");
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${getAuthCallbackUrl()}?next=/auth/reset-password`,
    });

    if (error) {
      setError(toFriendlyAuthMessage(error.message));
      setLoading(false);
      return;
    }

    setMessage("Check your email for a password reset link.");
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-nightcap flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <Link href="/" className="inline-block font-display text-2xl text-nightcap-accent mb-8">
          NightCapt
        </Link>
        <div className="glass rounded-2xl p-8">
          <h1 className="font-display text-3xl text-white mb-2">Sign in</h1>
          <p className="text-sm text-nightcap-muted mb-6">
            Verify with a text to your phone. Existing email accounts can still sign in with email.
          </p>

          <AuthMethodToggle value={method} onChange={setMethod} />

          {method === "phone" ? (
            <PhoneOtpForm shouldCreateUser={false} submitLabel="Send verification code" />
          ) : (
            <form onSubmit={handleSignIn} className="space-y-4">
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
                <div className="mb-2 flex items-center justify-between gap-3">
                  <label htmlFor="password" className="block text-sm text-nightcap-muted">
                    Password
                  </label>
                  <button
                    type="button"
                    onClick={handlePasswordReset}
                    disabled={loading}
                    className="text-xs text-nightcap-accent hover:underline disabled:opacity-50"
                  >
                    Forgot password?
                  </button>
                </div>
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className={inputClass}
                  placeholder="••••••••"
                />
              </div>
              {error && <p className="text-red-400 text-sm">{error}</p>}
              {message && <p className="text-night-mint text-sm">{message}</p>}
              <div className="flex gap-3">
                <button
                  type="submit"
                  disabled={loading}
                  className="flex-1 rounded-xl bg-nightcap-accent px-4 py-3 font-medium text-white transition hover:opacity-90 disabled:opacity-50"
                >
                  {loading ? "Signing in..." : "Sign in"}
                </button>
                <button
                  type="button"
                  onClick={handleMagicLink}
                  disabled={loading}
                  className="rounded-xl glass px-4 py-3 font-medium text-white transition hover:border-nightcap-accent/50 disabled:opacity-50"
                >
                  Magic link
                </button>
              </div>
            </form>
          )}

          <p className="text-sm text-nightcap-muted mt-4">
            By signing in, you agree to the{" "}
            <Link href="/privacy" className="text-nightcap-accent hover:underline">
              Terms of Use, Privacy Policy and Support
            </Link>
            . There is zero tolerance for objectionable content or abusive users.
          </p>

          <p className="mt-6 text-center text-sm text-nightcap-muted">
            Don&apos;t have an account?{" "}
            <Link href="/auth/signup" className="text-nightcap-accent hover:underline">
              Sign up
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
