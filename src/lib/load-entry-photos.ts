import type { SupabaseClient } from "@supabase/supabase-js";
import type { StoredMedia } from "@/lib/entry-media";

export type PhotoRow = StoredMedia & { entry_id: string };

function missingSortOrder(message: string): boolean {
  const lower = message.toLowerCase();
  return lower.includes("sort_order") || lower.includes("schema cache");
}

/** Load entry photos, including order once migration 013 has been applied. */
export async function loadPhotosForEntries(
  supabase: SupabaseClient,
  entryIds: string[]
): Promise<PhotoRow[]> {
  if (entryIds.length === 0) return [];

  const primary = await supabase
    .from("photos")
    .select("entry_id, type, url, sort_order")
    .in("entry_id", entryIds);

  if (!primary.error) {
    return (primary.data ?? []) as PhotoRow[];
  }
  if (!missingSortOrder(primary.error.message)) {
    throw new Error(primary.error.message);
  }

  const fallback = await supabase
    .from("photos")
    .select("entry_id, type, url")
    .in("entry_id", entryIds);
  return (fallback.data ?? []) as PhotoRow[];
}
