/** Seconds a provider asked us to wait, when the message includes them. */
export function retryAfterSeconds(message: string): number | null {
  const match = message.match(/(\d+)\s*seconds?/i);
  if (!match) return null;
  const seconds = Number(match[1]);
  if (!Number.isFinite(seconds) || seconds <= 0 || seconds > 3600) return null;
  return seconds;
}

/** Network blips worth one automatic retry. Auth rejections are not. */
export function isTransientAuthError(message: string): boolean {
  const m = message.toLowerCase();
  return (
    m.includes("failed to fetch") ||
    m.includes("network") ||
    m.includes("timeout") ||
    m.includes("timed out") ||
    m.includes("load failed") ||
    m.includes("econnreset")
  );
}

/** Connection failures that return immediately. Timeouts are excluded so a slow text is not sent twice. */
export function isImmediateNetworkError(message: string): boolean {
  const m = message.toLowerCase();
  if (m.includes("timeout") || m.includes("timed out")) return false;
  return (
    m.includes("failed to fetch") ||
    m.includes("load failed") ||
    m.includes("econnreset") ||
    m.includes("socket") ||
    m.includes("network")
  );
}

/** Map Supabase Auth errors into short, user-facing copy. */
export function toFriendlyAuthMessage(message: string): string {
  const m = message.toLowerCase();
  const wait = retryAfterSeconds(message);

  if (
    m.includes("signups not allowed") ||
    m.includes("user not found") ||
    m.includes("unable to find user")
  ) {
    return "No account found for this number. Create an account first.";
  }
  if (
    m.includes("error sending") ||
    m.includes("sms_send_failed") ||
    m.includes("error sending confirmation") ||
    (m.includes("sms") && m.includes("error"))
  ) {
    return "We couldn't send a verification text. Wait a moment, then tap resend. If it keeps failing, use email.";
  }
  if (m.includes("otp_expired") || (m.includes("token") && (m.includes("expired") || m.includes("invalid")))) {
    return "That code is invalid or expired. Request a new one and enter the latest text.";
  }
  if (
    m.includes("rate") ||
    m.includes("too many") ||
    m.includes("security purposes") ||
    m.includes("over_sms_send_rate_limit") ||
    m.includes("over_request_rate_limit")
  ) {
    return wait
      ? `Too many attempts. Wait ${wait} seconds, then try again.`
      : "Too many attempts. Wait a minute and try again.";
  }
  if (m.includes("phone") && m.includes("invalid")) {
    return "Enter a valid UK mobile, like 07123 456789.";
  }
  if (
    m.includes("unsupported phone provider") ||
    m.includes("phone provider") ||
    m.includes("phone_provider_disabled") ||
    m.includes("sms provider")
  ) {
    return "Phone sign-in is not set up yet. Use email, or try again later.";
  }
  if (isTransientAuthError(message)) {
    return "We couldn't reach the verification service. Check your connection and try again.";
  }

  return message;
}
