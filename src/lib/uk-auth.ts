export const UK_DIAL_CODE = "+44";

export const UK_PHONE_AUTH_COPY =
  "Phone authentication is for UK users only. If you're outside the UK, use email.";

const UK_TIME_ZONES = new Set([
  "Europe/London",
  "Europe/Belfast",
  "Europe/Guernsey",
  "Europe/Isle_of_Man",
  "Europe/Jersey",
]);

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
