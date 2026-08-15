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

/** Normalize a national or pasted number into E.164, or null if invalid. */
export function toE164(dialCode: string, nationalNumber: string): string | null {
  const trimmed = nationalNumber.trim();
  if (!trimmed) return null;

  if (trimmed.startsWith("+")) {
    const e164 = `+${digitsOnly(trimmed)}`;
    return E164_RE.test(e164) ? e164 : null;
  }

  const dialDigits = digitsOnly(dialCode);
  if (!dialDigits) return null;

  let national = digitsOnly(trimmed);
  if (national.startsWith("0")) {
    national = national.slice(1);
  }
  if (national.startsWith(dialDigits) && national.length > dialDigits.length + 6) {
    national = national.slice(dialDigits.length);
  }

  const e164 = `+${dialDigits}${national}`;
  return E164_RE.test(e164) ? e164 : null;
}

export function isValidE164(phone: string): boolean {
  return E164_RE.test(phone.trim());
}

export function isValidOtp(token: string): boolean {
  return /^\d{6}$/.test(token.trim());
}

/** Mask a phone number for UI copy, e.g. +447••••••789. */
export function maskPhone(e164: string): string {
  const digits = digitsOnly(e164);
  if (digits.length < 8) return e164;
  const start = digits.slice(0, 3);
  const end = digits.slice(-3);
  return `+${start}${"•".repeat(digits.length - 6)}${end}`;
}
