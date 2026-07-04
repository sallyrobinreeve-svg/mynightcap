import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entry_models.dart';

class EntryService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<EntryDetail> fetch(String entryId) async {
    final userId = _client.auth.currentUser?.id;

    final entry = await _client
        .from('entries')
        .select(
          'id, user_id, date_of_night, rating, prompts, created_at, video_url',
        )
        .eq('id', entryId)
        .maybeSingle();

    if (entry == null) {
      throw StateError('Entry not found or not visible.');
    }

    final authorId = entry['user_id'] as String;
    final prompts = (entry['prompts'] as Map?)?.cast<String, dynamic>() ?? {};
    final isMine = authorId == userId;

    final results = await Future.wait<dynamic>([
      _client
          .from('profiles')
          .select('display_name, username')
          .eq('id', authorId)
          .maybeSingle(),
      _client.from('photos').select('type, url').eq('entry_id', entryId),
      _client
          .from('timeline_steps')
          .select('type, location_name, time_at, notes, emoji, sort_order')
          .eq('entry_id', entryId)
          .order('sort_order', ascending: true),
      _client.from('reactions').select('user_id, type').eq('entry_id', entryId),
      _client
          .from('comments')
          .select('id, user_id, content, created_at')
          .eq('entry_id', entryId)
          .order('created_at', ascending: true),
    ]);

    final author = results[0] as Map<String, dynamic>?;
    final photos = (results[1] as List).cast<Map<String, dynamic>>();
    final timelineRows = (results[2] as List).cast<Map<String, dynamic>>();
    final reactions = (results[3] as List).cast<Map<String, dynamic>>();
    final commentRows = (results[4] as List).cast<Map<String, dynamic>>();

    final photoUrls = [
      for (final photo in photos)
        if (photo['type'] == 'favourite' || photo['type'] == 'outfit')
          photo['url'] as String,
    ];

    final timeline = [
      for (final step in timelineRows)
        TimelineStep(
          type: step['type'] as String,
          locationName: step['location_name'] as String?,
          timeAt: step['time_at'] as String?,
          notes: step['notes'] as String?,
          emoji: step['emoji'] as String?,
        ),
    ];

    final reactionCounts = <String, int>{};
    String? myReactionType;
    for (final reaction in reactions) {
      final type = reaction['type'] as String;
      reactionCounts[type] = (reactionCounts[type] ?? 0) + 1;
      if (reaction['user_id'] == userId) myReactionType = type;
    }

    final commenterIds = {
      for (final comment in commentRows) comment['user_id'] as String,
    }.toList();
    final nameById = <String, String?>{};
    if (commenterIds.isNotEmpty) {
      final profiles = await _client
          .from('profiles')
          .select('id, display_name, username')
          .inFilter('id', commenterIds);
      for (final profile in (profiles as List).cast<Map<String, dynamic>>()) {
        final displayName = profile['display_name'] as String?;
        final username = profile['username'] as String?;
        nameById[profile['id'] as String] =
            displayName?.trim().isNotEmpty == true
            ? displayName
            : (username?.trim().isNotEmpty == true ? '@$username' : null);
      }
    }

    final comments = [
      for (final comment in commentRows)
        EntryComment(
          id: comment['id'] as String,
          userId: comment['user_id'] as String,
          content: comment['content'] as String,
          createdAt: comment['created_at'] as String,
          authorName: nameById[comment['user_id']],
        ),
    ];

    final displayName = author?['display_name'] as String?;
    final username = author?['username'] as String?;
    final authorName = displayName?.trim().isNotEmpty == true
        ? displayName
        : (username?.trim().isNotEmpty == true ? '@$username' : null);

    return EntryDetail(
      id: entry['id'] as String,
      userId: authorId,
      dateOfNight: entry['date_of_night'] as String,
      rating: entry['rating'] as int?,
      prompts: _visiblePrompts(prompts, isMine),
      authorName: authorName,
      photoUrls: photoUrls,
      timeline: timeline,
      reactionCounts: reactionCounts,
      myReactionType: myReactionType,
      comments: comments,
      isMine: isMine,
      videoUrl: entry['video_url'] as String?,
      currentUserId: userId,
    );
  }

  Map<String, dynamic> _visiblePrompts(
    Map<String, dynamic> prompts,
    bool isMine,
  ) {
    if (isMine) return prompts;
    final filtered = Map<String, dynamic>.from(prompts);
    if (prompts['kissedPrivate'] == true) {
      filtered.remove('kissedAnyone');
      filtered.remove('kissedWho');
      filtered.remove('whoKissedWho');
    }
    filtered.remove('kissedPrivate');
    filtered.remove('whoKissedWhoPrivate');
    return filtered;
  }

  Future<void> toggleReaction({
    required String entryId,
    required String type,
    required String? currentType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (currentType == type) {
      await _client
          .from('reactions')
          .delete()
          .eq('entry_id', entryId)
          .eq('user_id', userId);
    } else {
      await _client.from('reactions').upsert({
        'entry_id': entryId,
        'user_id': userId,
        'type': type,
      }, onConflict: 'entry_id,user_id');
    }
  }

  Future<void> addComment({
    required String entryId,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('comments').insert({
      'entry_id': entryId,
      'user_id': userId,
      'content': content,
    });
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  Future<String> createEntry({
    required DateTime date,
    required int rating,
    required String visibility,
    required Map<String, dynamic> prompts,
    PickedUpload? outfit,
    PickedUpload? favourite,
    String? videoUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final entry = await _client
        .from('entries')
        .insert({
          'user_id': userId,
          'date_of_night': DateFormat('yyyy-MM-dd').format(date),
          'rating': rating,
          'prompts': prompts,
          'visibility': visibility,
          if (videoUrl != null) 'video_url': videoUrl,
        })
        .select('id')
        .single();

    final entryId = entry['id'] as String;
    final photoRows = [
      if (outfit != null)
        {'entry_id': entryId, 'type': 'outfit', 'url': outfit.url},
      if (favourite != null)
        {'entry_id': entryId, 'type': 'favourite', 'url': favourite.url},
    ];
    if (photoRows.isNotEmpty) {
      await _client.from('photos').insert(photoRows);
    }
    return entryId;
  }
}

final entryService = EntryService();
