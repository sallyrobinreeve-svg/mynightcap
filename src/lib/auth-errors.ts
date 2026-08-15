/** Map Supabase Auth errors into short, user-facing copy. */
export function toFriendlyAuthMessage(message: string): string {
  const m = message.toLowerCase();

  if (
    m.includes("signups not allowed") ||
    m.includes("user not found") ||
    m.includes("unable to find user")
  ) {
    return "No account found for this number. Create an account first.";
  }
  if (m.includes("error sending") || (m.includes("sms") && m.includes("error"))) {
    return "We couldn't send a verification text. Try again in a moment.";
  }
  if (m.includes("token") && (m.includes("expired") || m.includes("invalid"))) {
    return "That code is invalid or expired. Request a new one.";
  }
  if (m.includes("rate") || m.includes("too many") || m.includes("over_sms_send_rate_limit")) {
    return "Too many attempts. Wait a minute and try again.";
  }
  if (m.includes("phone") && m.includes("invalid")) {
    return "Enter a valid mobile number including country code.";
  }
  if (m.includes("unsupported phone provider") || m.includes("phone provider")) {
    return "Phone sign-in is not set up yet. Use email, or try again later.";
  }

  return message;
}
