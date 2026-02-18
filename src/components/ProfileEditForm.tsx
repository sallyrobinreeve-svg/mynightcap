"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { useDropzone } from "react-dropzone";
import { BottomNav } from "@/components/BottomNav";
import Link from "next/link";

interface ProfileEditFormProps {
  userId: string;
  displayName: string | null;
  avatarUrl: string | null;
  bio: string | null;
}

export function ProfileEditForm({
  userId,
  displayName,
  avatarUrl,
  bio,
}: ProfileEditFormProps) {
  const router = useRouter();
  const [display_name, setDisplayName] = useState(displayName ?? "");
  const [avatar_url, setAvatarUrl] = useState(avatarUrl);
  const [bioText, setBio] = useState(bio ?? "");
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onDrop = useCallback(
    async (acceptedFiles: File[]) => {
      const file = acceptedFiles[0];
      if (!file) return;
      setUploading(true);
      try {
        const formData = new FormData();
        formData.set("file", file);
        formData.set("type", "avatar");
        formData.set("userId", userId);
        const res = await fetch("/api/upload", { method: "POST", body: formData });
        if (!res.ok) throw new Error("Upload failed");
        const { url } = await res.json();
        setAvatarUrl(url);
      } catch {
        setError("Failed to upload photo");
      } finally {
        setUploading(false);
      }
    },
    [userId]
  );

  const { getRootProps, getInputProps } = useDropzone({
    onDrop,
    accept: { "image/*": [".jpeg", ".jpg", ".png", ".webp", ".gif"] },
    maxFiles: 1,
    disabled: uploading,
  });

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const res = await fetch("/api/profile", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          display_name: display_name.trim() || null,
          avatar_url: avatar_url || null,
          bio: bioText.trim() || null,
        }),
      });
      if (!res.ok) throw new Error("Failed to save");
      router.push("/profile");
      router.refresh();
    } catch {
      setError("Failed to save profile");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-nightcap pb-24">
      <nav className="glass sticky top-0 z-10 border-b border-white/5">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <Link href="/profile" className="font-display text-2xl text-nightcap-accent hover:opacity-90">
            ← Back
          </Link>
        </div>
      </nav>

      <main className="mx-auto max-w-2xl px-4 py-12">
        <h1 className="font-display text-4xl text-white mb-8">Edit profile</h1>

        <div className="glass rounded-2xl p-8 space-y-6">
          <div>
            <p className="text-nightcap-muted text-sm mb-2">Profile picture</p>
            <div
              {...getRootProps()}
              className="w-28 h-28 rounded-full overflow-hidden bg-nightcap-muted border-2 border-dashed border-nightcap-muted flex items-center justify-center cursor-pointer hover:border-nightcap-accent/50 transition"
            >
              <input {...getInputProps()} />
              {avatar_url ? (
                <Image src={avatar_url} alt="" width={112} height={112} className="object-cover w-full h-full" />
              ) : uploading ? (
                <span className="text-nightcap-muted text-sm">Uploading...</span>
              ) : (
                <span className="text-nightcap-muted text-4xl">
                  {(display_name || "?")[0].toUpperCase()}
                </span>
              )}
            </div>
            <p className="text-nightcap-muted text-xs mt-2">Tap to change</p>
          </div>

          <div>
            <label className="block text-nightcap-muted text-sm mb-2">Display name</label>
            <input
              type="text"
              value={display_name}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="Your name"
              className="w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-nightcap-muted text-sm mb-2">Bio</label>
            <textarea
              value={bioText}
              onChange={(e) => setBio(e.target.value)}
              placeholder="A few words about you..."
              rows={3}
              className="w-full rounded-xl bg-nightcap/80 border border-white/10 px-4 py-3 text-white placeholder:text-nightcap-muted focus:border-nightcap-accent focus:outline-none resize-none"
            />
          </div>

          {error && (
            <p className="text-red-400 text-sm">{error}</p>
          )}

          <button
            type="button"
            onClick={handleSave}
            disabled={saving}
            className="w-full rounded-xl bg-nightcap-accent px-4 py-3 font-medium text-white hover:opacity-90 disabled:opacity-50"
          >
            {saving ? "Saving..." : "Save profile"}
          </button>
        </div>
      </main>
      <BottomNav />
    </div>
  );
}
