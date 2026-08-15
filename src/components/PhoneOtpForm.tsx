"use client";

import { useEffect, useState } from "react";
import { toFriendlyAuthMessage } from "@/lib/auth-errors";
import { isValidOtp, maskPhone } from "@/lib/phone";
import { UK_DIAL_CODE, parseUkLoginPhone } from "@/lib/uk-auth";
import { createClient } from "@/lib/supabase/client";

const inputClass =
  "w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none";

type PhoneOtpFormProps = {
  shouldCreateUser: boolean;
  metadata?: Record<string, string> | (() => Record<string, string>);
  validateBeforeSend?: () => string | null;
  onVerified?: (userId: string) => Promise<void> | void;
  submitLabel?: string;
  onRequireEmail?: () => void;
};

export function PhoneOtpForm({
  shouldCreateUser,
  metadata,
  validateBeforeSend,
  onVerified,
  submitLabel = "Send code",
  onRequireEmail,
}: PhoneOtpFormProps) {
  const [nationalNumber, setNationalNumber] = useState("");
  const [otp, setOtp] = useState("");
  const [sentTo, setSentTo] = useState<string | null>(null);
  const [cooldown, setCooldown] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (cooldown <= 0) return;
    const id = window.setInterval(() => {
      setCooldown((current) => (current <= 1 ? 0 : current - 1));
    }, 1000);
    return () => window.clearInterval(id);
  }, [cooldown]);

  const sendCode = async () => {
    const blocked = validateBeforeSend?.();
    if (blocked) {
      setError(blocked);
      setMessage(null);
      return;
    }

    const parsed = parseUkLoginPhone(nationalNumber);
    if (parsed.status === "not_uk") {
      setError("Phone login is for UK numbers only. Use email instead.");
      setMessage(null);
      onRequireEmail?.();
      return;
    }
    if (parsed.status !== "ok") {
      setError("Enter a valid UK mobile number, or use email.");
      setMessage(null);
      return;
    }
    const phone = parsed.phone;

    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const data = typeof metadata === "function" ? metadata() : metadata;
    const { error: sendError } = await supabase.auth.signInWithOtp({
      phone,
      options: {
        channel: "sms",
        shouldCreateUser,
        data,
      },
    });

    if (sendError) {
      setError(toFriendlyAuthMessage(sendError.message));
      setLoading(false);
      return;
    }

    setSentTo(phone);
    setCooldown(60);
    setOtp("");
    setMessage(`We sent a 6-digit code to ${maskPhone(phone)}.`);
    setLoading(false);
  };

  const verifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!sentTo) {
      await sendCode();
      return;
    }

    if (!isValidOtp(otp)) {
      setError("Enter the 6-digit code from your text message.");
      setMessage(null);
      return;
    }

    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const { data, error: verifyError } = await supabase.auth.verifyOtp({
      phone: sentTo,
      token: otp.trim(),
      type: "sms",
    });

    if (verifyError) {
      setError(toFriendlyAuthMessage(verifyError.message));
      setLoading(false);
      return;
    }

    if (data.user && onVerified) {
      await onVerified(data.user.id);
    }

    setMessage("Verified! Redirecting...");
    window.location.href = "/";
  };

  return (
    <form onSubmit={verifyCode} className="space-y-4">
      <div>
        <label htmlFor="phone" className="mb-2 block text-sm text-nightcap-muted">
          UK mobile number
        </label>
        <div className="flex gap-2">
          <span className="flex shrink-0 items-center rounded-xl border border-white/10 bg-nightcap/80 px-4 py-3 text-sm text-white">
            {UK_DIAL_CODE}
          </span>
          <input
            id="phone"
            type="tel"
            inputMode="tel"
            autoComplete="tel"
            value={nationalNumber}
            onChange={(e) => setNationalNumber(e.target.value)}
            disabled={loading || Boolean(sentTo)}
            required
            className={inputClass}
            placeholder="7123 456789"
          />
        </div>
      </div>

      {sentTo && (
        <div>
          <label htmlFor="otp" className="mb-2 block text-sm text-nightcap-muted">
            Verification code
          </label>
          <input
            id="otp"
            type="text"
            inputMode="numeric"
            autoComplete="one-time-code"
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))}
            maxLength={6}
            className={`${inputClass} tracking-[0.4em]`}
            placeholder="123456"
          />
        </div>
      )}

      {error && <p className="text-sm text-red-400">{error}</p>}
      {message && <p className="text-sm text-night-mint">{message}</p>}

      <button
        type="submit"
        disabled={loading}
        className="w-full rounded-xl bg-nightcap-accent px-4 py-3 font-medium text-white transition hover:opacity-90 disabled:opacity-50"
      >
        {loading
          ? sentTo
            ? "Verifying..."
            : "Sending code..."
          : sentTo
            ? "Verify code"
            : submitLabel}
      </button>

      {sentTo && (
        <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
          <button
            type="button"
            disabled={loading || cooldown > 0}
            onClick={sendCode}
            className="text-nightcap-accent hover:underline disabled:opacity-50"
          >
            {cooldown > 0 ? `Resend code in ${cooldown}s` : "Resend code"}
          </button>
          <button
            type="button"
            disabled={loading}
            onClick={() => {
              setSentTo(null);
              setOtp("");
              setMessage(null);
              setError(null);
              setCooldown(0);
            }}
            className="text-nightcap-muted hover:text-white"
          >
            Change number
          </button>
        </div>
      )}
    </form>
  );
}
