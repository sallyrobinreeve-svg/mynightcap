import { digitsOnly, toE164 } from "./phone";

export const UK_DIAL_CODE = "+44";

export const UK_PHONE_AUTH_COPY =
  "Phone authentication is for UK numbers only. If you're outside the UK, use email.";

const UK_MOBILE = /^\+447\d{9}$/;
const UK_TIME_ZONES = new Set([
  "Europe/London",
  "Europe/Belfast",
  "Europe/Guernsey",
  "Europe/Isle_of_Man",
  "Europe/Jersey",
]);

export function isUkMobile(e164: string): boolean {
  return UK_MOBILE.test(e164.trim());
}

export function prefersUkPhoneAuth(options?: {
  languages?: readonly string[];
  timeZone?: string;
}): boolean {
  const languages =
    options?.languages ??
    (typeof navigator !== "undefined"
      ? navigator.languages?.length
        ? navigator.languages
        : navigator.language
          ? [navigator.language]
          : []
      : []);
  const timeZone =
    options?.timeZone ??
    (typeof Intl !== "undefined" ? Intl.DateTimeFormat().resolvedOptions().timeZone : "");

  const languageHit = languages.some((language) => {
    const normalized = language.toLowerCase().replace(/_/g, "-");
    return (
      normalized === "en-gb" ||
      normalized.endsWith("-gb") ||
      normalized === "cy-gb" ||
      normalized === "gd-gb"
    );
  });
  if (languageHit) return true;
  return UK_TIME_ZONES.has(timeZone);
}

export type UkPhoneResult =
  | { status: "ok"; phone: string }
  | { status: "invalid" }
  | { status: "not_uk" };

/** Parse a number for UK phone login. Non-UK numbers should switch to email. */
export function parseUkLoginPhone(nationalNumber: string): UkPhoneResult {
  const trimmed = nationalNumber.trim();
  if (!trimmed) return { status: "invalid" };

  const phone = toE164(UK_DIAL_CODE, trimmed);
  if (!phone) return { status: "invalid" };
  if (!phone.startsWith(UK_DIAL_CODE)) return { status: "not_uk" };
  if (!isUkMobile(phone)) return { status: "invalid" };
  return { status: "ok", phone };
}

export function pastedNumberLooksNonUk(nationalNumber: string): boolean {
  const trimmed = nationalNumber.trim();
  if (!trimmed.startsWith("+")) return false;
  const e164 = `+${digitsOnly(trimmed)}`;
  return e164.startsWith("+") && !e164.startsWith("+44") && e164.length >= 8;
}
