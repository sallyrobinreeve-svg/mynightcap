import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads photo rows, retrying without sort_order if that column is not migrated yet.
Future<List<Map<String, dynamic>>> fetchPhotoRows(
  SupabaseClient client,
  List<String> entryIds,
) async {
  if (entryIds.isEmpty) return [];
  try {
    final rows = await client
        .from('photos')
        .select('entry_id, type, url, sort_order')
        .inFilter('entry_id', entryIds);
    return (rows as List).cast<Map<String, dynamic>>();
  } catch (_) {
    final rows = await client
        .from('photos')
        .select('entry_id, type, url')
        .inFilter('entry_id', entryIds);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}

Future<List<Map<String, dynamic>>> fetchPhotoRowsForEntry(
  SupabaseClient client,
  String entryId,
) {
  return fetchPhotoRows(client, [entryId]);
}
