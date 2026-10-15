"use client";

import { useEffect, useRef, useState } from "react";
import {
  isTransientAuthError,
  retryAfterSeconds,
  toFriendlyAuthMessage,
} from "@/lib/auth-errors";
import { digitsOnly, isValidOtp, maskPhone, parseUkLoginPhone } from "@/lib/phone";
import { UK_DIAL_CODE } from "@/lib/uk-auth";
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

function samePhone(a?: string | null, b?: string | null): boolean {
  if (!a || !b) return false;
  return digitsOnly(a) === digitsOnly(b);
}

function sleep(ms: number) {
  return new Promise((resolve) => window.setTimeout(resolve, ms));
}

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
  const verifyLock = useRef(false);
  const attemptedOtp = useRef<string | null>(null);
  const sentToRef = useRef<string | null>(null);

  useEffect(() => {
    sentToRef.current = sentTo;
  }, [sentTo]);

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
      setError("Enter a valid UK mobile number, like 07123 456789, or use email.");
      setMessage(null);
      return;
    }
    const phone = parsed.phone;

    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const data = typeof metadata === "function" ? metadata() : metadata;
    let lastMessage = "We couldn't send a verification text. Try again in a moment.";

    for (let attempt = 0; attempt < 2; attempt += 1) {
      try {
        const { error: sendError } = await supabase.auth.signInWithOtp({
          phone,
          options: {
            channel: "sms",
            shouldCreateUser,
            data,
          },
        });
        if (!sendError) {
          attemptedOtp.current = null;
          setSentTo(phone);
          setCooldown(60);
          setOtp("");
          setMessage(`We sent a 6-digit code to ${maskPhone(phone)}. It can take up to a minute.`);
          setLoading(false);
          return;
        }
        lastMessage = sendError.message;
        if (attempt === 0 && isTransientAuthError(sendError.message)) continue;
        break;
      } catch (sendError) {
        lastMessage = sendError instanceof Error ? sendError.message : "Network error";
        if (attempt === 0 && isTransientAuthError(lastMessage)) continue;
        break;
      }
    }

    const wait = retryAfterSeconds(lastMessage);
    if (wait) setCooldown(wait);
    setError(toFriendlyAuthMessage(lastMessage));
    setLoading(false);
  };

  const verifyCode = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if (verifyLock.current) return;

    const phone = sentToRef.current;
    if (!phone) {
      await sendCode();
      return;
    }

    const token = otp.trim();
    if (!isValidOtp(token)) {
      setError("Enter the 6-digit code from your text message.");
      setMessage(null);
      return;
    }

    verifyLock.current = true;
    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    try {
      const { data, error: verifyError } = await supabase.auth.verifyOtp({
        phone,
        token,
        type: "sms",
      });

      let user = data.user ?? null;
      if (verifyError || !user) {
        const { data: sessionData } = await supabase.auth.getSession();
        const sessionUser = sessionData.session?.user ?? null;
        if (sessionUser && samePhone(sessionUser.phone, phone)) {
          user = sessionUser;
        } else if (verifyError) {
          setError(toFriendlyAuthMessage(verifyError.message));
          return;
        }
      }

      for (let attempt = 0; attempt < 3 && !user; attempt += 1) {
        await sleep(250);
        const { data: sessionData } = await supabase.auth.getSession();
        user = sessionData.session?.user ?? null;
      }

      if (!user || !samePhone(user.phone, phone)) {
        setError("The code was accepted but sign-in didn't finish. Request a new code and try again.");
        return;
      }

      try {
        if (onVerified) await onVerified(user.id);
      } catch {
        // The code already signed the user in. A profile side effect can be retried later.
      }

      setMessage("Verified! Redirecting...");
      window.location.href = "/";
    } catch (verifyError) {
      const message = verifyError instanceof Error ? verifyError.message : "Network error";
      setError(toFriendlyAuthMessage(message));
    } finally {
      verifyLock.current = false;
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!sentTo || !isValidOtp(otp) || verifyLock.current) return;
    const key = `${sentTo}:${otp}`;
    if (attemptedOtp.current === key) return;
    attemptedOtp.current = key;
    void verifyCode();
    // verifyCode reads the latest otp and sentTo refs; listing it would retrigger every render.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [otp, sentTo]);

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
          <p className="mt-2 text-xs text-nightcap-muted">
            Enter the newest 6-digit text. The code fills in automatically on most phones.
          </p>
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

      {onRequireEmail && (
        <button
          type="button"
          disabled={loading}
          onClick={onRequireEmail}
          className="w-full text-sm text-nightcap-accent hover:underline disabled:opacity-50"
        >
          Outside the UK? Use email instead
        </button>
      )}

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
              attemptedOtp.current = null;
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
