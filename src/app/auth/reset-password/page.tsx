"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { NeonLogo } from "@/components/NeonLogo";

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setMessage(null);

    if (password.length < 6) {
      setError("Password must be at least 6 characters.");
      return;
    }

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    setLoading(true);
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({ password });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    setMessage("Password updated. Redirecting...");
    router.push("/profile");
    router.refresh();
  };

  return (
    <div className="min-h-screen bg-nightcap flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="mb-8">
          <NeonLogo className="text-4xl" />
        </div>
        <div className="glass rounded-2xl p-8 neon-glow">
          <h1 className="text-3xl font-semibold text-white mb-6">Reset password</h1>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label htmlFor="password" className="block text-sm text-nightcap-muted mb-2">
                New password
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                minLength={6}
                className="w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none"
                placeholder="New password"
              />
            </div>
            <div>
              <label htmlFor="confirmPassword" className="block text-sm text-nightcap-muted mb-2">
                Confirm password
              </label>
              <input
                id="confirmPassword"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                minLength={6}
                className="w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none"
                placeholder="Confirm password"
              />
            </div>

            {error && <p className="text-red-400 text-sm">{error}</p>}
            {message && <p className="text-night-mint text-sm">{message}</p>}

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-xl bg-nightcap-accent px-4 py-3 font-medium text-white transition hover:opacity-90 disabled:opacity-50"
            >
              {loading ? "Updating..." : "Update password"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
