export const MAX_ENTRY_PHOTOS = 10;
export const MAX_ENTRY_VIDEOS = 5;

export type StoredMedia = {
  type: string;
  url: string;
  sort_order?: number | null;
};

export type MediaInsertRow = {
  entry_id: string;
  type: "photo" | "video" | "favourite";
  url: string;
  sort_order: number;
};

function isHttpUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}

/** Keep the first occurrence of each non-empty URL, capped at max. */
export function uniqueUrls(urls: readonly string[], max: number): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const url of urls) {
    const trimmed = url.trim();
    if (!trimmed || seen.has(trimmed)) continue;
    seen.add(trimmed);
    out.push(trimmed);
    if (out.length >= max) break;
  }
  return out;
}

export function parseUrlList(
  value: unknown,
  max: number,
  label: string
): { urls: string[] } | { error: string } {
  if (!Array.isArray(value)) {
    return { error: `${label} must be a list.` };
  }
  const raw: string[] = [];
  for (const item of value) {
    if (typeof item !== "string" || !item.trim()) continue;
    const trimmed = item.trim();
    if (!isHttpUrl(trimmed)) {
      return { error: `Each ${label.slice(0, -1)} must be an uploaded file.` };
    }
    raw.push(trimmed);
  }
  if (raw.length > max) {
    return { error: `You can add up to ${max} ${label}.` };
  }
  return { urls: uniqueUrls(raw, max) };
}

function galleryUrls(rows: readonly StoredMedia[], type: "photo" | "video"): string[] {
  return [...rows]
    .filter((row) => row.type === type && row.url)
    .sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0))
    .map((row) => row.url);
}

/** Ordered gallery photos, or the older outfit + favourite pair when no gallery exists. */
export function entryPhotoUrls(rows: readonly StoredMedia[]): string[] {
  const gallery = uniqueUrls(galleryUrls(rows, "photo"), MAX_ENTRY_PHOTOS);
  if (gallery.length > 0) return gallery;

  const legacy: string[] = [];
  const outfit = rows.find((row) => row.type === "outfit")?.url;
  const favourite = rows.find((row) => row.type === "favourite")?.url;
  if (outfit) legacy.push(outfit);
  if (favourite && favourite !== outfit) legacy.push(favourite);
  return legacy;
}

/** Ordered gallery videos, or the single legacy video_url. */
export function entryVideoUrls(
  rows: readonly StoredMedia[],
  legacyVideoUrl?: string | null
): string[] {
  const gallery = uniqueUrls(galleryUrls(rows, "video"), MAX_ENTRY_VIDEOS);
  if (gallery.length > 0) return gallery;
  return legacyVideoUrl ? [legacyVideoUrl] : [];
}

export function entryThumbnailUrl(rows: readonly StoredMedia[]): string | null {
  return entryPhotoUrls(rows)[0] ?? null;
}

export function friendlyMediaWriteError(message: string): string {
  const lower = message.toLowerCase();
  if (
    lower.includes("photos_type_check") ||
    lower.includes("sort_order") ||
    lower.includes("schema cache")
  ) {
    return "Photo and video galleries need a database update before they can be saved.";
  }
  return message;
}

export function mediaInsertRows(
  entryId: string,
  photoUrls: readonly string[],
  videoUrls: readonly string[]
): MediaInsertRow[] {
  const photos = uniqueUrls(photoUrls, MAX_ENTRY_PHOTOS);
  const videos = uniqueUrls(videoUrls, MAX_ENTRY_VIDEOS);
  const rows: MediaInsertRow[] = [
    ...photos.map((url, sort_order) => ({
      entry_id: entryId,
      type: "photo" as const,
      url,
      sort_order,
    })),
    ...videos.map((url, sort_order) => ({
      entry_id: entryId,
      type: "video" as const,
      url,
      sort_order,
    })),
  ];
  if (photos[0]) {
    rows.push({
      entry_id: entryId,
      type: "favourite",
      url: photos[0],
      sort_order: 0,
    });
  }
  return rows;
}

type MediaBody = {
  photoUrls?: unknown;
  videoUrls?: unknown;
  outfitPhotoUrl?: unknown;
  favouritePhotoUrl?: unknown;
  videoUrl?: unknown;
};

function legacyPhotoUrls(body: MediaBody): string[] {
  const urls: string[] = [];
  if (typeof body.outfitPhotoUrl === "string") urls.push(body.outfitPhotoUrl);
  if (typeof body.favouritePhotoUrl === "string") urls.push(body.favouritePhotoUrl);
  return uniqueUrls(urls, MAX_ENTRY_PHOTOS);
}

/** Resolve a create/update payload. Absent lists mean "leave the old fields alone" only when hasOwn is false. */
export function resolveSubmittedMedia(
  body: MediaBody,
  options: { photosProvided: boolean; videosProvided: boolean }
): { photoUrls?: string[]; videoUrls?: string[] } | { error: string } {
  const result: { photoUrls?: string[]; videoUrls?: string[] } = {};

  if (options.photosProvided) {
    const parsed = parseUrlList(body.photoUrls, MAX_ENTRY_PHOTOS, "photos");
    if ("error" in parsed) return parsed;
    result.photoUrls = parsed.urls;
  } else if ("outfitPhotoUrl" in body || "favouritePhotoUrl" in body) {
    result.photoUrls = legacyPhotoUrls(body);
  }

  if (options.videosProvided) {
    const parsed = parseUrlList(body.videoUrls, MAX_ENTRY_VIDEOS, "videos");
    if ("error" in parsed) return parsed;
    result.videoUrls = parsed.urls;
  } else if ("videoUrl" in body) {
    result.videoUrls =
      typeof body.videoUrl === "string" && body.videoUrl.trim()
        ? uniqueUrls([body.videoUrl], MAX_ENTRY_VIDEOS)
        : [];
  }

  return result;
}
