"use client";

import { useCallback, useEffect, useState } from "react";
import { useDropzone } from "react-dropzone";
import Image from "next/image";
import { ChevronDown, ChevronUp, GripVertical, X } from "lucide-react";
import {
  DndContext,
  KeyboardSensor,
  PointerSensor,
  closestCenter,
  useSensor,
  useSensors,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  arrayMove,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { MAX_ENTRY_PHOTOS, MAX_ENTRY_VIDEOS } from "@/lib/entry-media";

const PHOTO_ACCEPT = { "image/*": [".jpeg", ".jpg", ".png", ".webp", ".gif"] };
const VIDEO_ACCEPT = { "video/*": [".mp4", ".webm", ".mov", ".avi"] };

function moveItem(urls: string[], index: number, direction: -1 | 1): string[] {
  const next = index + direction;
  if (next < 0 || next >= urls.length) return urls;
  return arrayMove(urls, index, next);
}

function SortableMediaRow({
  id,
  index,
  total,
  kind,
  onMove,
  onRemove,
}: {
  id: string;
  index: number;
  total: number;
  kind: "photo" | "video";
  onMove: (index: number, direction: -1 | 1) => void;
  onRemove: (index: number) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id,
  });
  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`flex items-center gap-3 rounded-xl border border-white/10 bg-nightcap/60 p-2 ${
        isDragging ? "opacity-70" : ""
      }`}
    >
      <button
        type="button"
        className="touch-none cursor-grab p-1 text-nightcap-muted hover:text-white active:cursor-grabbing"
        aria-label={`Drag ${kind} ${index + 1}`}
        {...attributes}
        {...listeners}
      >
        <GripVertical size={18} />
      </button>
      {kind === "photo" ? (
        <Image
          src={id}
          alt=""
          width={72}
          height={72}
          className="h-16 w-16 rounded-lg object-cover"
        />
      ) : (
        <video src={id} className="h-16 w-16 rounded-lg bg-black object-cover" muted playsInline />
      )}
      <div className="min-w-0 flex-1">
        <p className="text-sm text-white">
          {kind === "photo" ? "Photo" : "Video"} {index + 1}
        </p>
        <p className="text-xs text-nightcap-muted">Drag or use the arrows</p>
      </div>
      <div className="flex items-center gap-1">
        <button
          type="button"
          aria-label={`Move ${kind} ${index + 1} up`}
          disabled={index === 0}
          onClick={() => onMove(index, -1)}
          className="rounded-lg p-1.5 text-nightcap-muted hover:text-white disabled:opacity-30"
        >
          <ChevronUp size={18} />
        </button>
        <button
          type="button"
          aria-label={`Move ${kind} ${index + 1} down`}
          disabled={index === total - 1}
          onClick={() => onMove(index, 1)}
          className="rounded-lg p-1.5 text-nightcap-muted hover:text-white disabled:opacity-30"
        >
          <ChevronDown size={18} />
        </button>
        <button
          type="button"
          aria-label={`Remove ${kind} ${index + 1}`}
          onClick={() => onRemove(index)}
          className="rounded-full bg-nightcap-accent p-1 text-white"
        >
          <X size={14} />
        </button>
      </div>
    </div>
  );
}

export function EntryMediaFields({
  photoUrls,
  videoUrls,
  onChange,
  userId,
}: {
  photoUrls: string[];
  videoUrls: string[];
  onChange: (photos: string[], videos: string[]) => void;
  userId: string;
}) {
  const [uploading, setUploading] = useState<"photo" | "video" | null>(null);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [isNative, setIsNative] = useState(false);
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  useEffect(() => {
    import("@capacitor/core").then(({ Capacitor }) => {
      setIsNative(Capacitor.isNativePlatform());
    });
  }, []);

  const uploadFile = useCallback(
    async (file: File, type: "photo" | "video"): Promise<string | null> => {
      const formData = new FormData();
      formData.set("file", file);
      formData.set("type", type);
      formData.set("userId", userId);
      const res = await fetch("/api/upload", { method: "POST", body: formData });
      if (!res.ok) throw new Error("Upload failed");
      const { url } = (await res.json()) as { url?: string };
      return url ?? null;
    },
    [userId]
  );

  const addFiles = useCallback(
    async (files: File[], type: "photo" | "video") => {
      const max = type === "photo" ? MAX_ENTRY_PHOTOS : MAX_ENTRY_VIDEOS;
      const current = type === "photo" ? photoUrls : videoUrls;
      const room = max - current.length;
      if (room <= 0) {
        setUploadError(
          type === "photo" ? "You can add up to 10 photos." : "You can add up to 5 videos."
        );
        return;
      }
      const batch = files.slice(0, room);
      setUploading(type);
      setUploadError(null);
      const added: string[] = [];
      try {
        for (const file of batch) {
          const url = await uploadFile(file, type);
          if (url) added.push(url);
        }
        if (added.length === 0) {
          setUploadError("Failed to upload. Please try again.");
          return;
        }
        if (type === "photo") onChange([...photoUrls, ...added], videoUrls);
        else onChange(photoUrls, [...videoUrls, ...added]);
      } catch {
        setUploadError("Failed to upload. Please try again.");
        if (added.length > 0) {
          if (type === "photo") onChange([...photoUrls, ...added], videoUrls);
          else onChange(photoUrls, [...videoUrls, ...added]);
        }
      } finally {
        setUploading(null);
      }
    },
    [onChange, photoUrls, uploadFile, videoUrls]
  );

  const pickNativePhotos = useCallback(async () => {
    const room = MAX_ENTRY_PHOTOS - photoUrls.length;
    if (room <= 0 || uploading) return;
    try {
      const { Camera } = await import("@capacitor/camera");
      const gallery = await Camera.pickImages({ quality: 90, limit: room });
      const files: File[] = [];
      for (const photo of gallery.photos) {
        const src = photo.webPath;
        if (!src) continue;
        const response = await fetch(src);
        const blob = await response.blob();
        const format = photo.format || "jpeg";
        files.push(
          new File([blob], `photo.${format === "jpeg" ? "jpg" : format}`, {
            type: blob.type || `image/${format}`,
          })
        );
      }
      if (files.length === 0) {
        setUploadError("Couldn't read those photos. Try again.");
        return;
      }
      await addFiles(files, "photo");
    } catch {
      setUploadError("Failed to upload. Please try again.");
    }
  }, [addFiles, photoUrls.length, uploading]);

  const onDropPhotos = useCallback(
    (accepted: File[]) => {
      void addFiles(accepted, "photo");
    },
    [addFiles]
  );
  const onDropVideos = useCallback(
    (accepted: File[]) => {
      void addFiles(accepted, "video");
    },
    [addFiles]
  );

  const { getRootProps: getPhotoRoot, getInputProps: getPhotoInput } = useDropzone({
    onDrop: onDropPhotos,
    accept: PHOTO_ACCEPT,
    maxFiles: Math.max(1, MAX_ENTRY_PHOTOS - photoUrls.length),
    disabled: uploading !== null || photoUrls.length >= MAX_ENTRY_PHOTOS,
  });
  const { getRootProps: getVideoRoot, getInputProps: getVideoInput } = useDropzone({
    onDrop: onDropVideos,
    accept: VIDEO_ACCEPT,
    maxFiles: Math.max(1, MAX_ENTRY_VIDEOS - videoUrls.length),
    disabled: uploading !== null || videoUrls.length >= MAX_ENTRY_VIDEOS,
  });

  const onDragEnd = (kind: "photo" | "video") => (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    const list = kind === "photo" ? photoUrls : videoUrls;
    const oldIndex = list.indexOf(String(active.id));
    const newIndex = list.indexOf(String(over.id));
    if (oldIndex < 0 || newIndex < 0) return;
    const next = arrayMove(list, oldIndex, newIndex);
    if (kind === "photo") onChange(next, videoUrls);
    else onChange(photoUrls, next);
  };

  return (
    <div className="space-y-8">
      <div>
        <div className="mb-3 flex items-baseline justify-between gap-3">
          <h2 className="font-display text-2xl text-white">Photos</h2>
          <p className="text-sm text-nightcap-muted">
            {photoUrls.length} / {MAX_ENTRY_PHOTOS}
          </p>
        </div>
        {photoUrls.length > 0 && (
          <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={onDragEnd("photo")}>
            <SortableContext items={photoUrls} strategy={verticalListSortingStrategy}>
              <div className="mb-3 space-y-2">
                {photoUrls.map((url, index) => (
                  <SortableMediaRow
                    key={url}
                    id={url}
                    index={index}
                    total={photoUrls.length}
                    kind="photo"
                    onMove={(itemIndex, direction) =>
                      onChange(moveItem(photoUrls, itemIndex, direction), videoUrls)
                    }
                    onRemove={(itemIndex) =>
                      onChange(
                        photoUrls.filter((_, i) => i !== itemIndex),
                        videoUrls
                      )
                    }
                  />
                ))}
              </div>
            </SortableContext>
          </DndContext>
        )}
        {photoUrls.length < MAX_ENTRY_PHOTOS && (
          <div
            {...(isNative ? { onClick: () => void pickNativePhotos() } : getPhotoRoot())}
            className="cursor-pointer rounded-xl border-2 border-dashed border-nightcap-muted p-6 text-center transition hover:border-nightcap-accent/50"
          >
            {!isNative && <input {...getPhotoInput()} />}
            <p className="text-nightcap-muted">
              {uploading === "photo"
                ? "Uploading..."
                : isNative
                  ? "Tap to add photos from your library"
                  : "Drop or click to add photos"}
            </p>
          </div>
        )}
      </div>

      <div>
        <div className="mb-3 flex items-baseline justify-between gap-3">
          <h2 className="font-display text-2xl text-white">Videos</h2>
          <p className="text-sm text-nightcap-muted">
            {videoUrls.length} / {MAX_ENTRY_VIDEOS}
          </p>
        </div>
        {videoUrls.length > 0 && (
          <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={onDragEnd("video")}>
            <SortableContext items={videoUrls} strategy={verticalListSortingStrategy}>
              <div className="mb-3 space-y-2">
                {videoUrls.map((url, index) => (
                  <SortableMediaRow
                    key={url}
                    id={url}
                    index={index}
                    total={videoUrls.length}
                    kind="video"
                    onMove={(itemIndex, direction) =>
                      onChange(photoUrls, moveItem(videoUrls, itemIndex, direction))
                    }
                    onRemove={(itemIndex) =>
                      onChange(
                        photoUrls,
                        videoUrls.filter((_, i) => i !== itemIndex)
                      )
                    }
                  />
                ))}
              </div>
            </SortableContext>
          </DndContext>
        )}
        {videoUrls.length < MAX_ENTRY_VIDEOS && (
          <div
            {...getVideoRoot()}
            className="cursor-pointer rounded-xl border-2 border-dashed border-nightcap-muted p-6 text-center transition hover:border-nightcap-accent/50"
          >
            <input {...getVideoInput()} />
            <p className="text-nightcap-muted">
              {uploading === "video" ? "Uploading..." : "Drop or click to add videos (mp4, webm, mov)"}
            </p>
          </div>
        )}
      </div>

      {uploadError && <p className="text-sm text-red-400">{uploadError}</p>}
      <p className="text-sm text-nightcap-muted">
        Optional. Add up to 10 photos and 5 videos, then drag them into the order you want.
      </p>
    </div>
  );
}
