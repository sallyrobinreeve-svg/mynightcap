import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  entryPhotoUrls,
  entryThumbnailUrl,
  entryVideoUrls,
  mediaInsertRows,
  parseUrlList,
  resolveSubmittedMedia,
} from "./entry-media.ts";

const photo = (n: number) => `https://cdn.example.com/p${n}.jpg`;
const video = (n: number) => `https://cdn.example.com/v${n}.mp4`;

describe("entryPhotoUrls", () => {
  it("uses ordered gallery photos and ignores the favourite mirror", () => {
    assert.deepEqual(
      entryPhotoUrls([
        { type: "photo", url: photo(2), sort_order: 1 },
        { type: "favourite", url: photo(1), sort_order: 0 },
        { type: "photo", url: photo(1), sort_order: 0 },
      ]),
      [photo(1), photo(2)]
    );
  });

  it("falls back to outfit then favourite", () => {
    assert.deepEqual(
      entryPhotoUrls([
        { type: "favourite", url: photo(2) },
        { type: "outfit", url: photo(1) },
      ]),
      [photo(1), photo(2)]
    );
  });
});

describe("entryVideoUrls", () => {
  it("prefers ordered video rows over the legacy column", () => {
    assert.deepEqual(
      entryVideoUrls(
        [
          { type: "video", url: video(2), sort_order: 1 },
          { type: "video", url: video(1), sort_order: 0 },
        ],
        video(9)
      ),
      [video(1), video(2)]
    );
  });

  it("uses the legacy column when no video rows exist", () => {
    assert.deepEqual(entryVideoUrls([], video(1)), [video(1)]);
  });
});

describe("entryThumbnailUrl", () => {
  it("uses the first ordered photo", () => {
    assert.equal(
      entryThumbnailUrl([
        { type: "photo", url: photo(2), sort_order: 1 },
        { type: "photo", url: photo(1), sort_order: 0 },
      ]),
      photo(1)
    );
  });
});

describe("parseUrlList", () => {
  it("rejects more than the maximum", () => {
    const urls = Array.from({ length: 11 }, (_, i) => photo(i));
    assert.deepEqual(parseUrlList(urls, 10, "photos"), {
      error: "You can add up to 10 photos.",
    });
  });

  it("drops duplicate urls and keeps order", () => {
    assert.deepEqual(parseUrlList([photo(1), photo(1), photo(2)], 10, "photos"), {
      urls: [photo(1), photo(2)],
    });
  });
});

describe("resolveSubmittedMedia", () => {
  it("keeps legacy outfit and favourite when gallery arrays are absent", () => {
    assert.deepEqual(
      resolveSubmittedMedia(
        { outfitPhotoUrl: photo(1), favouritePhotoUrl: photo(2), videoUrl: video(1) },
        { photosProvided: false, videosProvided: false }
      ),
      { photoUrls: [photo(1), photo(2)], videoUrls: [video(1)] }
    );
  });

  it("uses gallery arrays when they are provided", () => {
    assert.deepEqual(
      resolveSubmittedMedia(
        { photoUrls: [photo(2), photo(1)], videoUrls: [video(1), video(2)] },
        { photosProvided: true, videosProvided: true }
      ),
      { photoUrls: [photo(2), photo(1)], videoUrls: [video(1), video(2)] }
    );
  });
});

describe("mediaInsertRows", () => {
  it("writes ordered photos, videos, and a favourite mirror of the first photo", () => {
    assert.deepEqual(mediaInsertRows("entry-1", [photo(1), photo(2)], [video(1)]), [
      { entry_id: "entry-1", type: "photo", url: photo(1), sort_order: 0 },
      { entry_id: "entry-1", type: "photo", url: photo(2), sort_order: 1 },
      { entry_id: "entry-1", type: "video", url: video(1), sort_order: 0 },
      { entry_id: "entry-1", type: "favourite", url: photo(1), sort_order: 0 },
    ]);
  });
});
