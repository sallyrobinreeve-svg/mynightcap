export const DEFAULT_DIAL_CODE = "+44";

export const DIAL_CODES = [
  { dial: "+44", label: "UK +44" },
  { dial: "+1", label: "US/CA +1" },
  { dial: "+353", label: "IE +353" },
  { dial: "+61", label: "AU +61" },
  { dial: "+64", label: "NZ +64" },
  { dial: "+33", label: "FR +33" },
  { dial: "+49", label: "DE +49" },
  { dial: "+34", label: "ES +34" },
  { dial: "+39", label: "IT +39" },
  { dial: "+31", label: "NL +31" },
  { dial: "+46", label: "SE +46" },
  { dial: "+47", label: "NO +47" },
  { dial: "+45", label: "DK +45" },
  { dial: "+48", label: "PL +48" },
  { dial: "+351", label: "PT +351" },
  { dial: "+91", label: "IN +91" },
  { dial: "+27", label: "ZA +27" },
  { dial: "+65", label: "SG +65" },
  { dial: "+852", label: "HK +852" },
  { dial: "+81", label: "JP +81" },
] as const;

const E164_RE = /^\+[1-9]\d{7,14}$/;

export function digitsOnly(value: string): string {
  return value.replace(/\D/g, "");
}

/**
 * Strip international prefixes and a trunk 0 so "0044 (0) 7123..." and
 * "+44 7123..." share one national significant number.
 */
export function nationalSignificantNumber(value: string, dialCode: string): string {
  let digits = digitsOnly(value);
  if (digits.startsWith("00")) digits = digits.slice(2);

  const dialDigits = digitsOnly(dialCode);
  if (dialDigits && digits.startsWith(dialDigits) && digits.length > dialDigits.length + 6) {
    digits = digits.slice(dialDigits.length);
  }
  if (digits.startsWith("0")) digits = digits.slice(1);
  return digits;
}

/** Normalize a national or pasted number into E.164, or null if invalid. */
export function toE164(dialCode: string, nationalNumber: string): string | null {
  const trimmed = nationalNumber.trim();
  if (!trimmed) return null;

  const dialDigits = digitsOnly(dialCode);
  if (!dialDigits && !trimmed.startsWith("+")) return null;

  if (trimmed.startsWith("+") && dialDigits && !digitsOnly(trimmed).startsWith(dialDigits)) {
    const e164 = `+${digitsOnly(trimmed)}`;
    return E164_RE.test(e164) ? e164 : null;
  }

  const national = nationalSignificantNumber(trimmed, dialDigits ? `+${dialDigits}` : dialCode);
  if (!dialDigits || !national) return null;

  const e164 = `+${dialDigits}${national}`;
  return E164_RE.test(e164) ? e164 : null;
}

export function isValidE164(phone: string): boolean {
  return E164_RE.test(phone.trim());
}

export function isValidOtp(token: string): boolean {
  return /^\d{6}$/.test(token.trim());
}

const UK_MOBILE = /^\+447\d{9}$/;

export function isUkMobile(e164: string): boolean {
  return UK_MOBILE.test(e164.trim());
}

export type UkPhoneResult =
  | { status: "ok"; phone: string }
  | { status: "invalid" }
  | { status: "not_uk" };

/** Parse a number for UK phone login. Non-UK numbers should switch to email. */
export function parseUkLoginPhone(nationalNumber: string): UkPhoneResult {
  const trimmed = nationalNumber.trim();
  if (!trimmed) return { status: "invalid" };

  const digits = digitsOnly(trimmed);
  const international = trimmed.startsWith("+") || digits.startsWith("00");
  if (international && !digits.startsWith("44") && !digits.startsWith("0044")) {
    return { status: "not_uk" };
  }

  if (!international && digits.startsWith("1") && digits.length === 11) {
    return { status: "not_uk" };
  }

  const national = nationalSignificantNumber(trimmed, DEFAULT_DIAL_CODE);
  if (!international && national.length === 10 && !national.startsWith("7")) {
    if (/^[12]/.test(national)) return { status: "invalid" };
    return { status: "not_uk" };
  }

  if (national.length === 10 && /^[12]/.test(national)) return { status: "invalid" };

  const phone = `+44${national}`;
  if (!isUkMobile(phone)) return { status: "invalid" };
  return { status: "ok", phone };
}

/** Mask a phone number for UI copy, e.g. +447••••••789. */
export function maskPhone(e164: string): string {
  const digits = digitsOnly(e164);
  if (digits.length < 8) return e164;
  const start = digits.slice(0, 3);
  const end = digits.slice(-3);
  return `+${start}${"•".repeat(digits.length - 6)}${end}`;
}
