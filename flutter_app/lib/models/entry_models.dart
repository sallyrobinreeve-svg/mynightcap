class EntryComment {
  const EntryComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String userId;
  final String content;
  final String createdAt;
  final String? authorName;
}

class TimelineStep {
  const TimelineStep({
    required this.type,
    this.locationName,
    this.timeAt,
    this.notes,
    this.emoji,
  });

  final String type;
  final String? locationName;
  final String? timeAt;
  final String? notes;
  final String? emoji;
}

class EntryDetail {
  const EntryDetail({
    required this.id,
    required this.userId,
    required this.dateOfNight,
    required this.rating,
    required this.prompts,
    required this.authorName,
    required this.photoUrls,
    required this.timeline,
    required this.reactionCounts,
    required this.myReactionType,
    required this.comments,
    required this.isMine,
    this.videoUrl,
    this.currentUserId,
  });

  final String id;
  final String userId;
  final String dateOfNight;
  final int? rating;
  final Map<String, dynamic> prompts;
  final String? authorName;
  final List<String> photoUrls;
  final List<TimelineStep> timeline;
  final Map<String, int> reactionCounts;
  final String? myReactionType;
  final List<EntryComment> comments;
  final bool isMine;
  final String? videoUrl;
  final String? currentUserId;
}

class PickedUpload {
  const PickedUpload({required this.path, required this.url});
  final String path;
  final String url;
}
