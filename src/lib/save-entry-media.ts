import type { SupabaseClient } from "@supabase/supabase-js";
import { friendlyMediaWriteError, mediaInsertRows } from "@/lib/entry-media";

export async function saveEntryMedia(
  supabase: SupabaseClient,
  entryId: string,
  userId: string,
  media: { photoUrls?: string[]; videoUrls?: string[] }
): Promise<string | null> {
  if (media.photoUrls) {
    const { error: deleteError } = await supabase
      .from("photos")
      .delete()
      .eq("entry_id", entryId)
      .in("type", ["outfit", "favourite", "photo"]);
    if (deleteError) return friendlyMediaWriteError(deleteError.message);

    const rows = mediaInsertRows(entryId, media.photoUrls, []).filter((row) => row.type !== "video");
    if (rows.length > 0) {
      const { error } = await supabase.from("photos").insert(rows);
      if (error) return friendlyMediaWriteError(error.message);
    }
  }

  if (media.videoUrls) {
    const { error: deleteError } = await supabase
      .from("photos")
      .delete()
      .eq("entry_id", entryId)
      .eq("type", "video");
    if (deleteError) return friendlyMediaWriteError(deleteError.message);

    const rows = mediaInsertRows(entryId, [], media.videoUrls).filter((row) => row.type === "video");
    if (rows.length > 0) {
      const { error } = await supabase.from("photos").insert(rows);
      if (error) return friendlyMediaWriteError(error.message);
    }

    const { error: videoError } = await supabase
      .from("entries")
      .update({ video_url: media.videoUrls[0] ?? null })
      .eq("id", entryId)
      .eq("user_id", userId);
    if (videoError) return friendlyMediaWriteError(videoError.message);
  }

  return null;
}
