"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useDropzone } from "react-dropzone";
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
const PHOTO_EDGE = 1600;

type MediaSlot = {
  key: string;
  preview: string;
  remoteUrl: string | null;
  uploading: boolean;
};

function slotsFromUrls(urls: string[]): MediaSlot[] {
  return urls.map((url) => ({
    key: url,
    preview: url,
    remoteUrl: url,
    uploading: false,
  }));
}

function readyUrls(slots: MediaSlot[]): string[] {
  return slots.flatMap((slot) => (slot.remoteUrl ? [slot.remoteUrl] : []));
}

function revokePreview(preview: string) {
  if (preview.startsWith("blob:")) URL.revokeObjectURL(preview);
}

async function shrinkImage(file: File): Promise<File> {
  if (!file.type.startsWith("image/") || file.type === "image/gif") return file;
  try {
    const bitmap = await createImageBitmap(file);
    const scale = Math.min(1, PHOTO_EDGE / Math.max(bitmap.width, bitmap.height));
    const width = Math.max(1, Math.round(bitmap.width * scale));
    const height = Math.max(1, Math.round(bitmap.height * scale));
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const context = canvas.getContext("2d");
    if (!context) {
      bitmap.close();
      return file;
    }
    context.drawImage(bitmap, 0, 0, width, height);
    bitmap.close();
    const blob = await new Promise<Blob | null>((resolve) => {
      canvas.toBlob(resolve, "image/jpeg", 0.72);
    });
    if (!blob) return file;
    const name = file.name.replace(/\.\w+$/, "") || "photo";
    return new File([blob], `${name}.jpg`, { type: "image/jpeg" });
  } catch {
    return file;
  }
}

function SortableMediaRow({
  slot,
  index,
  total,
  kind,
  onMove,
  onRemove,
}: {
  slot: MediaSlot;
  index: number;
  total: number;
  kind: "photo" | "video";
  onMove: (index: number, direction: -1 | 1) => void;
  onRemove: (index: number) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: slot.key,
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
      <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-lg bg-black">
        {kind === "photo" ? (
          // Local previews are blob URLs, which next/image cannot render.
          // eslint-disable-next-line @next/next/no-img-element
          <img src={slot.preview} alt="" className="h-full w-full object-cover" />
        ) : (
          <video
            src={slot.preview}
            className="h-full w-full object-cover"
            muted
            playsInline
            preload="metadata"
          />
        )}
        {slot.uploading && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/55">
            <div className="h-5 w-5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
          </div>
        )}
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-sm text-white">
          {kind === "photo" ? "Photo" : "Video"} {index + 1}
        </p>
        <p className="text-xs text-nightcap-muted">
          {slot.uploading ? "Uploading in the background" : "Drag or use the arrows"}
        </p>
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
  onUploadingChange,
  userId,
}: {
  photoUrls: string[];
  videoUrls: string[];
  onChange: (photos: string[], videos: string[]) => void;
  onUploadingChange?: (uploading: boolean) => void;
  userId: string;
}) {
  const [photoSlots, setPhotoSlots] = useState<MediaSlot[]>(() => slotsFromUrls(photoUrls));
  const [videoSlots, setVideoSlots] = useState<MediaSlot[]>(() => slotsFromUrls(videoUrls));
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [isNative, setIsNative] = useState(false);
  const photoSlotsRef = useRef(photoSlots);
  const videoSlotsRef = useRef(videoSlots);
  const emittedPhotos = useRef(photoUrls.join("|"));
  const emittedVideos = useRef(videoUrls.join("|"));
  useEffect(() => {
    photoSlotsRef.current = photoSlots;
  }, [photoSlots]);

  useEffect(() => {
    videoSlotsRef.current = videoSlots;
  }, [videoSlots]);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  const publish = useCallback(
    (photos: MediaSlot[], videos: MediaSlot[]) => {
      const photoList = readyUrls(photos);
      const videoList = readyUrls(videos);
      emittedPhotos.current = photoList.join("|");
      emittedVideos.current = videoList.join("|");
      onChange(photoList, videoList);
      onUploadingChange?.(photos.some((slot) => slot.uploading) || videos.some((slot) => slot.uploading));
    },
    [onChange, onUploadingChange]
  );

  useEffect(() => {
    const incoming = photoUrls.join("|");
    if (incoming === emittedPhotos.current) return;
    emittedPhotos.current = incoming;
    setPhotoSlots(slotsFromUrls(photoUrls));
  }, [photoUrls]);

  useEffect(() => {
    const incoming = videoUrls.join("|");
    if (incoming === emittedVideos.current) return;
    emittedVideos.current = incoming;
    setVideoSlots(slotsFromUrls(videoUrls));
  }, [videoUrls]);

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

  const uploadSlot = useCallback(
    async (key: string, file: File, type: "photo" | "video") => {
      try {
        const prepared = type === "photo" ? await shrinkImage(file) : file;
        const url = await uploadFile(prepared, type);
        if (!url) throw new Error("Upload failed");
        const apply = (slots: MediaSlot[]) =>
          slots.map((slot) =>
            slot.key === key ? { ...slot, remoteUrl: url, uploading: false } : slot
          );
        if (type === "photo") {
          const next = apply(photoSlotsRef.current);
          photoSlotsRef.current = next;
          setPhotoSlots(next);
          publish(next, videoSlotsRef.current);
        } else {
          const next = apply(videoSlotsRef.current);
          videoSlotsRef.current = next;
          setVideoSlots(next);
          publish(photoSlotsRef.current, next);
        }
      } catch {
        const drop = (slots: MediaSlot[]) => {
          const removed = slots.find((slot) => slot.key === key);
          if (removed) revokePreview(removed.preview);
          return slots.filter((slot) => slot.key !== key);
        };
        if (type === "photo") {
          const next = drop(photoSlotsRef.current);
          photoSlotsRef.current = next;
          setPhotoSlots(next);
          publish(next, videoSlotsRef.current);
        } else {
          const next = drop(videoSlotsRef.current);
          videoSlotsRef.current = next;
          setVideoSlots(next);
          publish(photoSlotsRef.current, next);
        }
        setUploadError(
          type === "photo"
            ? "A photo did not upload. It was removed so you can try it again."
            : "A video did not upload. It was removed so you can try it again."
        );
      }
    },
    [publish, uploadFile]
  );

  const addFiles = useCallback(
    async (files: File[], type: "photo" | "video") => {
      const max = type === "photo" ? MAX_ENTRY_PHOTOS : MAX_ENTRY_VIDEOS;
      const current = type === "photo" ? photoSlotsRef.current : videoSlotsRef.current;
      const room = max - current.length;
      if (room <= 0) {
        setUploadError(
          type === "photo" ? "You can add up to 10 photos." : "You can add up to 5 videos."
        );
        return;
      }
      const batch = files.slice(0, room);
      const added: MediaSlot[] = batch.map((file) => ({
        key: `${type}-${crypto.randomUUID()}`,
        preview: URL.createObjectURL(file),
        remoteUrl: null,
        uploading: true,
      }));
      setUploadError(null);
      if (type === "photo") {
        const next = [...photoSlotsRef.current, ...added];
        photoSlotsRef.current = next;
        setPhotoSlots(next);
        publish(next, videoSlotsRef.current);
      } else {
        const next = [...videoSlotsRef.current, ...added];
        videoSlotsRef.current = next;
        setVideoSlots(next);
        publish(photoSlotsRef.current, next);
      }
      await Promise.all(added.map((slot, index) => uploadSlot(slot.key, batch[index], type)));
    },
    [publish, uploadSlot]
  );

  const pickNativePhotos = useCallback(async () => {
    const room = MAX_ENTRY_PHOTOS - photoSlotsRef.current.length;
    if (room <= 0) return;
    try {
      const { Camera } = await import("@capacitor/camera");
      const gallery = await Camera.pickImages({ quality: 70, width: 1600, height: 1600, limit: room });
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
  }, [addFiles]);

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

  const photoRoom = Math.max(0, MAX_ENTRY_PHOTOS - photoSlots.length);
  const videoRoom = Math.max(0, MAX_ENTRY_VIDEOS - videoSlots.length);
  const { getRootProps: getPhotoRoot, getInputProps: getPhotoInput } = useDropzone({
    onDrop: onDropPhotos,
    accept: PHOTO_ACCEPT,
    maxFiles: Math.max(1, photoRoom),
    disabled: photoRoom === 0,
  });
  const { getRootProps: getVideoRoot, getInputProps: getVideoInput } = useDropzone({
    onDrop: onDropVideos,
    accept: VIDEO_ACCEPT,
    maxFiles: Math.max(1, videoRoom),
    disabled: videoRoom === 0,
  });

  const moveSlots = (kind: "photo" | "video", index: number, direction: -1 | 1) => {
    const list = kind === "photo" ? photoSlots : videoSlots;
    const nextIndex = index + direction;
    if (nextIndex < 0 || nextIndex >= list.length) return;
    const next = arrayMove(list, index, nextIndex);
    if (kind === "photo") {
      setPhotoSlots(next);
      publish(next, videoSlots);
    } else {
      setVideoSlots(next);
      publish(photoSlots, next);
    }
  };

  const removeSlot = (kind: "photo" | "video", index: number) => {
    const list = kind === "photo" ? photoSlots : videoSlots;
    const removed = list[index];
    if (removed) revokePreview(removed.preview);
    const next = list.filter((_, itemIndex) => itemIndex !== index);
    if (kind === "photo") {
      setPhotoSlots(next);
      publish(next, videoSlots);
    } else {
      setVideoSlots(next);
      publish(photoSlots, next);
    }
  };

  const onDragEnd = (kind: "photo" | "video") => (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    const list = kind === "photo" ? photoSlots : videoSlots;
    const oldIndex = list.findIndex((slot) => slot.key === String(active.id));
    const newIndex = list.findIndex((slot) => slot.key === String(over.id));
    if (oldIndex < 0 || newIndex < 0) return;
    const next = arrayMove(list, oldIndex, newIndex);
    if (kind === "photo") {
      setPhotoSlots(next);
      publish(next, videoSlots);
    } else {
      setVideoSlots(next);
      publish(photoSlots, next);
    }
  };

  const uploadingPhotos = photoSlots.some((slot) => slot.uploading);
  const uploadingVideos = videoSlots.some((slot) => slot.uploading);

  return (
    <div className="space-y-8">
      <div>
        <div className="mb-3 flex items-baseline justify-between gap-3">
          <h2 className="font-display text-2xl text-white">Photos</h2>
          <p className="text-sm text-nightcap-muted">
            {photoSlots.length} / {MAX_ENTRY_PHOTOS}
          </p>
        </div>
        {photoSlots.length > 0 && (
          <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={onDragEnd("photo")}>
            <SortableContext items={photoSlots.map((slot) => slot.key)} strategy={verticalListSortingStrategy}>
              <div className="mb-3 space-y-2">
                {photoSlots.map((slot, index) => (
                  <SortableMediaRow
                    key={slot.key}
                    slot={slot}
                    index={index}
                    total={photoSlots.length}
                    kind="photo"
                    onMove={(itemIndex, direction) => moveSlots("photo", itemIndex, direction)}
                    onRemove={(itemIndex) => removeSlot("photo", itemIndex)}
                  />
                ))}
              </div>
            </SortableContext>
          </DndContext>
        )}
        {photoRoom > 0 && (
          <div
            {...(isNative ? { onClick: () => void pickNativePhotos() } : getPhotoRoot())}
            className="cursor-pointer rounded-xl border-2 border-dashed border-nightcap-muted p-6 text-center transition hover:border-nightcap-accent/50"
          >
            {!isNative && <input {...getPhotoInput()} />}
            <p className="text-nightcap-muted">
              {uploadingPhotos
                ? "Uploading in the background. You can still reorder."
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
            {videoSlots.length} / {MAX_ENTRY_VIDEOS}
          </p>
        </div>
        {videoSlots.length > 0 && (
          <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={onDragEnd("video")}>
            <SortableContext items={videoSlots.map((slot) => slot.key)} strategy={verticalListSortingStrategy}>
              <div className="mb-3 space-y-2">
                {videoSlots.map((slot, index) => (
                  <SortableMediaRow
                    key={slot.key}
                    slot={slot}
                    index={index}
                    total={videoSlots.length}
                    kind="video"
                    onMove={(itemIndex, direction) => moveSlots("video", itemIndex, direction)}
                    onRemove={(itemIndex) => removeSlot("video", itemIndex)}
                  />
                ))}
              </div>
            </SortableContext>
          </DndContext>
        )}
        {videoRoom > 0 && (
          <div
            {...getVideoRoot()}
            className="cursor-pointer rounded-xl border-2 border-dashed border-nightcap-muted p-6 text-center transition hover:border-nightcap-accent/50"
          >
            <input {...getVideoInput()} />
            <p className="text-nightcap-muted">
              {uploadingVideos
                ? "Uploading in the background. You can still reorder."
                : "Drop or click to add videos (mp4, webm, mov)"}
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
