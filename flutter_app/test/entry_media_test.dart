import 'package:flutter_test/flutter_test.dart';
import 'package:nightcapt_flutter/entry_media.dart';

void main() {
  test('orders gallery photos ahead of the favourite mirror', () {
    final urls = entryPhotoUrls(const [
      StoredMedia(type: 'photo', url: 'https://cdn.example/b.jpg', sortOrder: 1),
      StoredMedia(type: 'favourite', url: 'https://cdn.example/a.jpg'),
      StoredMedia(type: 'photo', url: 'https://cdn.example/a.jpg', sortOrder: 0),
    ]);
    expect(urls, ['https://cdn.example/a.jpg', 'https://cdn.example/b.jpg']);
  });

  test('falls back to outfit then favourite', () {
    final urls = entryPhotoUrls(const [
      StoredMedia(type: 'favourite', url: 'https://cdn.example/b.jpg'),
      StoredMedia(type: 'outfit', url: 'https://cdn.example/a.jpg'),
    ]);
    expect(urls, ['https://cdn.example/a.jpg', 'https://cdn.example/b.jpg']);
  });

  test('uses the legacy video when no video rows exist', () {
    expect(
      entryVideoUrls(const [], 'https://cdn.example/v.mp4'),
      ['https://cdn.example/v.mp4'],
    );
  });
}
