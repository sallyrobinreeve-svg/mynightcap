const METADATA_KEYS = new Set([
  "hasMission",
  "missionCompleted",
  "kissedPrivate",
  "whoKissedWhoPrivate",
]);

export function privacyKeyFor(promptId: string): string {
  return `${promptId}Private`;
}

export function isPromptMetadataKey(key: string): boolean {
  return METADATA_KEYS.has(key) || key.endsWith("Private");
}

export function isPromptPrivate(
  prompts: Record<string, unknown> | undefined,
  promptId: string
): boolean {
  if (!prompts) return false;
  if (promptId === "kissedAnyone" || promptId === "kissedWho" || promptId === "whoKissedWho") {
    return prompts.kissedPrivate === true || prompts.whoKissedWhoPrivate === true;
  }
  return prompts[privacyKeyFor(promptId)] === true;
}
