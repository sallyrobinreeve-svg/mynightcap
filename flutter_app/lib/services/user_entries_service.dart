import 'package:supabase_flutter/supabase_flutter.dart';

import '../entry_media.dart';
import 'photo_rows.dart';

class UserEntryTile {
  const UserEntryTile({
    required this.id,
    required this.dateOfNight,
    this.rating,
    this.photoUrl,
  });

  final String id;
  final String dateOfNight;
  final int? rating;
  final String? photoUrl;
}

class UserEntriesService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<UserEntryTile>> fetchForUser(String userId, {int limit = 60}) async {
    final entries = await _client
        .from('entries')
        .select('id, date_of_night, rating')
        .eq('user_id', userId)
        .order('date_of_night', ascending: false)
        .limit(limit);

    final entryRows = (entries as List).cast<Map<String, dynamic>>();
    if (entryRows.isEmpty) return [];

    final entryIds = [for (final row in entryRows) row['id'] as String];
    final photos = await fetchPhotoRows(_client, entryIds);

    final photosByEntry = <String, List<Map<String, dynamic>>>{};
    for (final photo in photos) {
      final entryId = photo['entry_id'] as String;
      photosByEntry.putIfAbsent(entryId, () => []).add(photo);
    }
    final photoByEntry = <String, String>{};
    for (final entry in photosByEntry.entries) {
      final thumb = entryThumbnailUrl(storedMediaFromRows(entry.value));
      if (thumb != null) photoByEntry[entry.key] = thumb;
    }

    return [
      for (final row in entryRows)
        UserEntryTile(
          id: row['id'] as String,
          dateOfNight: row['date_of_night'] as String,
          rating: row['rating'] as int?,
          photoUrl: photoByEntry[row['id'] as String],
        ),
    ];
  }

  Future<List<UserEntryTile>> fetchMine({int limit = 60}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    return fetchForUser(userId, limit: limit);
  }
}

final userEntriesService = UserEntriesService();
