import { createClient } from "@/lib/supabase/server";
import { NextRequest, NextResponse } from "next/server";
import { resolveSubmittedMedia } from "@/lib/entry-media";
import { saveEntryMedia } from "@/lib/save-entry-media";

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id: entryId } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { data: entry } = await supabase
    .from("entries")
    .select("user_id")
    .eq("id", entryId)
    .single();

  if (!entry || entry.user_id !== user.id) {
    return NextResponse.json({ error: "Not found or forbidden" }, { status: 403 });
  }

  const body = await request.json();
  const {
    dateOfNight,
    rating,
    prompts,
    kissedPrivate,
    timelineSteps,
    taggedUserIds,
    visibility,
  } = body;

  const media = resolveSubmittedMedia(body, {
    photosProvided: Object.prototype.hasOwnProperty.call(body, "photoUrls"),
    videosProvided: Object.prototype.hasOwnProperty.call(body, "videoUrls"),
  });
  if ("error" in media) {
    return NextResponse.json({ error: media.error }, { status: 400 });
  }

  if (!dateOfNight) {
    return NextResponse.json(
      { error: "Date of night is required" },
      { status: 400 }
    );
  }

  const promptsData = prompts ? { ...prompts } : undefined;
  if (promptsData && kissedPrivate && (promptsData.kissedAnyone || promptsData.kissedWho)) {
    promptsData.kissedPrivate = true;
  }

  const { error: updateError } = await supabase
    .from("entries")
    .update({
      date_of_night: dateOfNight,
      ...(rating !== undefined && { rating: rating ?? null }),
      ...(promptsData !== undefined && { prompts: promptsData }),
      ...(media.videoUrls && { video_url: media.videoUrls[0] ?? null }),
      ...(visibility !== undefined && { visibility: visibility || "friends" }),
      updated_at: new Date().toISOString(),
    })
    .eq("id", entryId)
    .eq("user_id", user.id);

  if (updateError) {
    return NextResponse.json(
      { error: updateError.message || "Failed to update entry" },
      { status: 500 }
    );
  }

  if (timelineSteps !== undefined) {
    await supabase.from("timeline_steps").delete().eq("entry_id", entryId);
    if (timelineSteps?.length > 0) {
      const steps = timelineSteps.map(
        (
          s: {
            type: string;
            emoji?: string | null;
            location_name: string | null;
            time_at: string | null;
            notes: string | null;
            sort_order: number;
          },
          i: number
        ) => ({
          entry_id: entryId,
          type: s.type,
          emoji: s.emoji || null,
          location_name: s.location_name || null,
          time_at: s.time_at || null,
          notes: s.notes || null,
          sort_order: i,
        })
      );
      await supabase.from("timeline_steps").insert(steps);
    }
  }

  const mediaError = await saveEntryMedia(supabase, entryId, user.id, media);
  if (mediaError) {
    return NextResponse.json({ error: mediaError }, { status: 500 });
  }

  if (taggedUserIds !== undefined) {
    await supabase.from("entry_tags").delete().eq("entry_id", entryId);
    if (taggedUserIds?.length > 0) {
      await supabase.from("entry_tags").insert(
        taggedUserIds.map((uid: string) => ({
          entry_id: entryId,
          user_id: uid,
        }))
      );
    }
  }

  return NextResponse.json({ id: entryId });
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id: entryId } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { error } = await supabase
    .from("entries")
    .delete()
    .eq("id", entryId)
    .eq("user_id", user.id);

  if (error) {
    return NextResponse.json(
      { error: error.message || "Failed to delete" },
      { status: 500 }
    );
  }

  return NextResponse.json({ ok: true });
}
