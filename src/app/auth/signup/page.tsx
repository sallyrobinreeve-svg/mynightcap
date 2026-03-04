"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";

export default function SignUpPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { full_name: displayName },
      },
    });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    setMessage("Check your email to confirm your account!");
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-nightcap flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <Link href="/" className="inline-block font-display text-2xl text-nightcap-accent mb-8">
          NightCapt
        </Link>
        <div className="glass rounded-2xl p-8">
          <h1 className="font-display text-3xl text-white mb-6">Create account</h1>

          <form onSubmit={handleSignUp} className="space-y-4">
            <div>
              <label htmlFor="displayName" className="block text-sm text-nightcap-muted mb-2">
                Display name
              </label>
              <input
                id="displayName"
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className="w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none"
                placeholder="Your name"
              />
            </div>
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
                className="w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none"
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
                className="w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none"
                placeholder="••••••••"
              />
            </div>
            {error && <p className="text-red-400 text-sm">{error}</p>}
            {message && <p className="text-night-mint text-sm">{message}</p>}
            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-xl bg-nightcap-accent px-4 py-3 font-medium text-white transition hover:opacity-90 disabled:opacity-50"
            >
              {loading ? "Creating account..." : "Sign up"}
            </button>
          </form>

          <p className="mt-6 text-center text-sm text-nightcap-muted">
            Already have an account?{" "}
            <Link href="/auth/signin" className="text-nightcap-accent hover:underline">
              Sign in
            </Link>
          </p>
          <p className="mt-4 text-center">
            <Link href="/privacy" className="text-xs text-nightcap-muted hover:text-nightcap-accent transition">
              Privacy Policy
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
