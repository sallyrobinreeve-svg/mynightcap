const DEFAULT_SITE_URL = "https://mynightcap.vercel.app";

/** URL Supabase should redirect to after email confirmation or magic links. */
export function getAuthCallbackUrl(): string {
  const base =
    process.env.NEXT_PUBLIC_SITE_URL ||
    (typeof window !== "undefined" ? window.location.origin : DEFAULT_SITE_URL);
  return `${base.replace(/\/$/, "")}/auth/callback`;
}
