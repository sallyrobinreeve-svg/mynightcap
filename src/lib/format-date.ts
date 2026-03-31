import { format, isValid } from "date-fns";

/** Avoids server crash when DB has null/invalid dates (date-fns format throws). */
export function formatDateSafe(
  value: string | Date | null | undefined,
  fmt: string,
  fallback = "—"
): string {
  if (value == null || value === "") return fallback;
  const d = value instanceof Date ? value : new Date(value);
  if (!isValid(d)) return fallback;
  return format(d, fmt);
}
