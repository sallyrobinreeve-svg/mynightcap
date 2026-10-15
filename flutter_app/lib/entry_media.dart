const maxEntryPhotos = 10;
const maxEntryVideos = 5;

class StoredMedia {
  const StoredMedia({required this.type, required this.url, this.sortOrder});

  final String type;
  final String url;
  final int? sortOrder;
}

List<StoredMedia> storedMediaFromRows(List<Map<String, dynamic>> rows) {
  return [
    for (final row in rows)
      if (row['url'] is String)
        StoredMedia(
          type: row['type'] as String? ?? '',
          url: row['url'] as String,
          sortOrder: (row['sort_order'] as num?)?.toInt(),
        ),
  ];
}

List<String> _unique(Iterable<String> urls, int max) {
  final seen = <String>{};
  final out = <String>[];
  for (final url in urls) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    out.add(trimmed);
    if (out.length >= max) break;
  }
  return out;
}

List<String> _gallery(List<StoredMedia> rows, String type, int max) {
  final matches = rows.where((row) => row.type == type && row.url.isNotEmpty).toList()
    ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  return _unique(matches.map((row) => row.url), max);
}

List<String> entryPhotoUrls(List<StoredMedia> rows) {
  final gallery = _gallery(rows, 'photo', maxEntryPhotos);
  if (gallery.isNotEmpty) return gallery;
  final legacy = <String>[];
  final outfit = rows.where((row) => row.type == 'outfit');
  final favourite = rows.where((row) => row.type == 'favourite');
  if (outfit.isNotEmpty) legacy.add(outfit.first.url);
  if (favourite.isNotEmpty && favourite.first.url != legacy.firstOrNull) {
    legacy.add(favourite.first.url);
  }
  return legacy;
}

List<String> entryVideoUrls(List<StoredMedia> rows, [String? legacyVideoUrl]) {
  final gallery = _gallery(rows, 'video', maxEntryVideos);
  if (gallery.isNotEmpty) return gallery;
  if (legacyVideoUrl != null && legacyVideoUrl.trim().isNotEmpty) {
    return [legacyVideoUrl];
  }
  return const [];
}

String? entryThumbnailUrl(List<StoredMedia> rows) {
  final photos = entryPhotoUrls(rows);
  return photos.isEmpty ? null : photos.first;
}

List<Map<String, dynamic>> mediaInsertRows(
  String entryId,
  List<String> photoUrls,
  List<String> videoUrls,
) {
  final photos = _unique(photoUrls, maxEntryPhotos);
  final videos = _unique(videoUrls, maxEntryVideos);
  return [
    for (var i = 0; i < photos.length; i++)
      {'entry_id': entryId, 'type': 'photo', 'url': photos[i], 'sort_order': i},
    for (var i = 0; i < videos.length; i++)
      {'entry_id': entryId, 'type': 'video', 'url': videos[i], 'sort_order': i},
    if (photos.isNotEmpty)
      {
        'entry_id': entryId,
        'type': 'favourite',
        'url': photos.first,
        'sort_order': 0,
      },
  ];
}
