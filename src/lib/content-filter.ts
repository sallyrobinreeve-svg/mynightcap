/**
 * Basic content filter for UGC (App Store Guideline 1.2).
 * Rejects objectionable content. Expand blocklist as needed.
 */
const BLOCKED_WORDS: string[] = [
  // Add specific terms as needed. Keep minimal to avoid false positives.
];

export function containsObjectionableContent(text: string): boolean {
  if (!text || typeof text !== "string") return false;
  const normalized = text.trim().toLowerCase();
  return BLOCKED_WORDS.some((w) => normalized.includes(w));
}
