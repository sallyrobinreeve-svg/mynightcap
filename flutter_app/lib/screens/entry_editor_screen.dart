import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../data/prompts.dart';
import '../entry_media.dart';
import '../models/entry_models.dart';
import '../models/friend_models.dart';
import '../services/content_filter.dart';
import '../services/entry_service.dart';
import '../services/friends_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/entry_prompt_sections.dart';
import '../widgets/night_widgets.dart';
import '../widgets/timeline_editor.dart';

class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({this.entryId, super.key});

  final String? entryId;

  bool get isEditing => entryId != null;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  DateTime date = DateTime.now();
  int? rating;
  String visibility = 'friends';
  List<_DraftMedia> photos = [];
  List<_DraftMedia> videos = [];
  int _mediaSeq = 0;
  bool saving = false;
  bool loading = false;
  String? message;
  final Map<String, dynamic> promptValues = {};
  final List<EditableTimelineStep> timelineSteps = [];
  final Set<String> taggedUserIds = {};
  List<UserProfile> friends = [];
  bool showAllPrompts = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      friends = await friendsService.friends();
      if (widget.entryId != null) {
        final data = await entryService.fetchForEdit(widget.entryId!);
        date = data.date;
        rating = data.rating;
        visibility = data.visibility;
        promptValues
          ..clear()
          ..addAll(data.prompts);
        photos = [
          for (final url in data.photoUrls)
            _DraftMedia(id: url, kind: 'photo', url: url),
        ];
        videos = [
          for (final url in data.videoUrls)
            _DraftMedia(id: url, kind: 'video', url: url),
        ];
        timelineSteps
          ..clear()
          ..addAll(data.timeline);
        taggedUserIds
          ..clear()
          ..addAll(data.taggedUserIds);
        _normalizePromptValues();
      }
    } catch (_) {
      message = 'Could not load entry.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool get _mediaBusy =>
      photos.any((item) => item.uploading) || videos.any((item) => item.uploading);

  List<String> _readyUrls(List<_DraftMedia> items) => [
        for (final item in items)
          if (item.url != null) item.url!,
      ];

  Future<void> addPhotos() async {
    final remaining = maxEntryPhotos - photos.length;
    if (remaining <= 0) {
      setState(() => message = 'You can add up to 10 photos.');
      return;
    }
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
      limit: remaining,
    );
    if (files.isEmpty || !mounted) return;
    final added = <_DraftMedia>[];
    for (final file in files.take(remaining)) {
      added.add(
        _DraftMedia(
          id: 'photo-${_mediaSeq++}',
          kind: 'photo',
          localPath: file.path,
          contentType: file.mimeType ?? 'image/jpeg',
          uploading: true,
        ),
      );
    }
    setState(() {
      message = null;
      photos = [...photos, ...added];
    });
    for (final draft in added) {
      unawaited(_uploadDraft(draft));
    }
  }

  Future<void> addVideo() async {
    if (videos.length >= maxEntryVideos) {
      setState(() => message = 'You can add up to 5 videos.');
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final draft = _DraftMedia(
      id: 'video-${_mediaSeq++}',
      kind: 'video',
      localPath: file.path,
      contentType: file.mimeType ?? 'video/mp4',
      uploading: true,
    );
    setState(() {
      message = null;
      videos = [...videos, draft];
    });
    unawaited(_uploadDraft(draft));
  }

  Future<void> _uploadDraft(_DraftMedia draft) async {
    final path = draft.localPath;
    if (path == null) return;
    try {
      final upload = await uploadLocalFile(
        path,
        draft.kind,
        contentType: draft.contentType,
      );
      if (!mounted) return;
      setState(() {
        draft
          ..url = upload.url
          ..uploading = false
          ..failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        draft
          ..uploading = false
          ..failed = true;
        message = draft.kind == 'video'
            ? 'A video did not upload. Retry it below.'
            : 'A photo did not upload. Retry it below.';
      });
    }
  }

  void _move(List<_DraftMedia> items, int index, int direction) {
    final next = index + direction;
    if (next < 0 || next >= items.length) return;
    final item = items.removeAt(index);
    items.insert(next, item);
  }

  void _normalizePromptValues() {
    if (promptValues['tonightsObjective'] != null &&
        promptValues['tonightsObjective'].toString().trim().isNotEmpty) {
      promptValues['hasMission'] = true;
    }
    final kissed = promptValues['kissedAnyone'];
    if (kissed is String) {
      promptValues['kissedAnyone'] = kissed.toLowerCase() == 'yes';
    }
  }

  Future<void> saveEntry() async {
    if (rating == null) {
      setState(() => message = 'Choose a rating before posting.');
      return;
    }
    if (_mediaBusy) {
      setState(() => message = 'Wait for photos and videos to finish uploading.');
      return;
    }
    if (photos.any((item) => item.failed) || videos.any((item) => item.failed)) {
      setState(
        () => message = 'Retry or remove media that failed to upload.',
      );
      return;
    }
    setState(() {
      saving = true;
      message = null;
    });
    try {
      if (widget.isEditing) {
        await entryService.updateEntry(
          entryId: widget.entryId!,
          date: date,
          rating: rating!,
          visibility: visibility,
          prompts: promptValues,
          photoUrls: _readyUrls(photos),
          videoUrls: _readyUrls(videos),
          timeline: timelineSteps,
          taggedUserIds: taggedUserIds.toList(),
        );
      } else {
        await entryService.createEntry(
          date: date,
          rating: rating!,
          visibility: visibility,
          prompts: promptValues,
          photoUrls: _readyUrls(photos),
          videoUrls: _readyUrls(videos),
          timeline: timelineSteps,
          taggedUserIds: taggedUserIds.toList(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Entry updated.' : 'Entry posted.'),
        ),
      );
      if (widget.isEditing) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          rating = null;
          photos = [];
          videos = [];
          promptValues.clear();
          timelineSteps.clear();
          taggedUserIds.clear();
        });
      }
    } on ContentFilterException {
      setState(() => message = ContentFilterException.message);
    } catch (_) {
      setState(
        () => message =
            'Could not save entry. Check your connection and permissions.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const NightScaffold(
        title: 'Create',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final prompts = showAllPrompts
        ? [...defaultPrompts(), ...extraPrompts()]
        : defaultPrompts();

    return NightScaffold(
      title: widget.isEditing ? 'Edit entry' : 'Create',
      child: ListView(
        children: [
          NightCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATE OF NIGHT',
                  style: TextStyle(
                    color: NightColors.muted,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(DateFormat.yMMMMd().format(date)),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: NightColors.accent,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'RATE THE NIGHT',
                  style: TextStyle(
                    color: NightColors.muted,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                StarRating(
                  value: rating,
                  onChanged: (value) => setState(() => rating = value),
                ),
                const SizedBox(height: 18),
                _MediaSection(
                  title: 'Photos',
                  countLabel: '${photos.length} / $maxEntryPhotos',
                  items: photos,
                  emptyLabel: 'Add photos',
                  icon: Icons.photo_library_outlined,
                  onAdd: photos.length >= maxEntryPhotos ? null : addPhotos,
                  onMove: (index, direction) =>
                      setState(() => _move(photos, index, direction)),
                  onRemove: (index) => setState(() => photos.removeAt(index)),
                  onRetry: (index) {
                    final item = photos[index];
                    setState(() {
                      item
                        ..failed = false
                        ..uploading = true;
                      message = null;
                    });
                    unawaited(_uploadDraft(item));
                  },
                ),
                const SizedBox(height: 12),
                _MediaSection(
                  title: 'Videos',
                  countLabel: '${videos.length} / $maxEntryVideos',
                  items: videos,
                  emptyLabel: 'Add video',
                  icon: Icons.videocam_outlined,
                  onAdd: videos.length >= maxEntryVideos ? null : addVideo,
                  onMove: (index, direction) =>
                      setState(() => _move(videos, index, direction)),
                  onRemove: (index) => setState(() => videos.removeAt(index)),
                  onRetry: (index) {
                    final item = videos[index];
                    setState(() {
                      item
                        ..failed = false
                        ..uploading = true;
                      message = null;
                    });
                    unawaited(_uploadDraft(item));
                  },
                ),
                const SizedBox(height: 18),
                TimelineEditor(
                  steps: timelineSteps,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tag friends',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (friends.isEmpty)
                  const Text(
                    'Add friends first to tag them on entries.',
                    style: TextStyle(color: NightColors.muted),
                  )
                else
                  for (final friend in friends)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: taggedUserIds.contains(friend.id),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            taggedUserIds.add(friend.id);
                          } else {
                            taggedUserIds.remove(friend.id);
                          }
                        });
                      },
                      title: Text(friend.name),
                      subtitle: friend.username == null
                          ? null
                          : Text('@${friend.username}'),
                    ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Prompts',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() => showAllPrompts = !showAllPrompts),
                      child: Text(showAllPrompts ? 'Show fewer' : 'Show all'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                MissionPromptSection(
                  promptValues: promptValues,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 18),
                KissPromptSection(
                  promptValues: promptValues,
                  onChanged: () => setState(() {}),
                ),
                for (final prompt in prompts) ...[
                  const SizedBox(height: 18),
                  PromptFieldWithPrivacy(
                    prompt: prompt,
                    promptValues: promptValues,
                    onChanged: () => setState(() {}),
                  ),
                ],
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: nightInputDecoration('Visibility'),
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                    DropdownMenuItem(value: 'friends', child: Text('Friends')),
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                  ],
                  onChanged: (value) =>
                      setState(() => visibility = value ?? 'friends'),
                ),
                if (message != null) StatusText(message!),
                const SizedBox(height: 18),
                NeonButton(
                  onPressed: saving ? null : saveEntry,
                  label: saving
                      ? 'Saving...'
                      : widget.isEditing
                      ? 'Save changes'
                      : 'Post night',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftMedia {
  _DraftMedia({
    required this.id,
    required this.kind,
    this.localPath,
    this.url,
    this.contentType,
    this.uploading = false,
    this.failed = false,
  });

  final String id;
  final String kind;
  final String? localPath;
  String? url;
  final String? contentType;
  bool uploading;
  bool failed;
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.title,
    required this.countLabel,
    required this.items,
    required this.emptyLabel,
    required this.icon,
    required this.onAdd,
    required this.onMove,
    required this.onRemove,
    required this.onRetry,
  });

  final String title;
  final String countLabel;
  final List<_DraftMedia> items;
  final String emptyLabel;
  final IconData icon;
  final VoidCallback? onAdd;
  final void Function(int index, int direction) onMove;
  final void Function(int index) onRemove;
  final void Function(int index) onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(countLabel, style: const TextStyle(color: NightColors.muted)),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _ClipThumb(item: items[i]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[i].failed
                        ? '$title ${i + 1} failed'
                        : items[i].uploading
                            ? 'Uploading ${title.toLowerCase()} ${i + 1}'
                            : '$title ${i + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (items[i].failed)
                  IconButton(
                    tooltip: 'Retry upload',
                    onPressed: () => onRetry(i),
                    icon: const Icon(Icons.refresh),
                  ),
                IconButton(
                  tooltip: 'Move up',
                  onPressed: i == 0 ? null : () => onMove(i, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: i == items.length - 1 ? null : () => onMove(i, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () => onRemove(i),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        if (onAdd != null)
          PhotoButton(
            label: emptyLabel,
            icon: icon,
            filled: items.isNotEmpty,
            onTap: onAdd!,
          ),
      ],
    );
  }
}

class _ClipThumb extends StatelessWidget {
  const _ClipThumb({required this.item});

  final _DraftMedia item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: NightColors.card,
              child: item.kind == 'video'
                  ? _VideoStill(item: item)
                  : _PhotoStill(item: item),
            ),
            if (item.uploading)
              const ColoredBox(
                color: Color(0x88000000),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoStill extends StatelessWidget {
  const _PhotoStill({required this.item});

  final _DraftMedia item;

  @override
  Widget build(BuildContext context) {
    final local = item.localPath;
    if (local != null && local.isNotEmpty) {
      return Image.file(
        File(local),
        fit: BoxFit.cover,
        cacheWidth: 228,
        errorBuilder: (_, _, _) =>
            const _MissingThumb(icon: Icons.image_not_supported_outlined),
      );
    }
    final url = item.url;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        cacheWidth: 228,
        errorBuilder: (_, _, _) =>
            const _MissingThumb(icon: Icons.image_not_supported_outlined),
      );
    }
    return const _MissingThumb(icon: Icons.photo_outlined);
  }
}

class _VideoStill extends StatefulWidget {
  const _VideoStill({required this.item});

  final _DraftMedia item;

  @override
  State<_VideoStill> createState() => _VideoStillState();
}

class _VideoStillState extends State<_VideoStill> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final local = widget.item.localPath;
    final url = widget.item.url;
    final VideoPlayerController controller;
    if (local != null && local.isNotEmpty) {
      controller = VideoPlayerController.file(File(local));
    } else if (url != null && url.isNotEmpty) {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      return;
    }
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setVolume(0);
      await controller.pause();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      await controller.dispose();
      if (identical(_controller, controller)) _controller = null;
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final size = controller?.value.size;
    if (!_ready || controller == null || size == null || size.width == 0 || size.height == 0) {
      return const _MissingThumb(icon: Icons.videocam_outlined);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

class _MissingThumb extends StatelessWidget {
  const _MissingThumb({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: NightColors.card,
      child: Icon(icon, color: NightColors.muted),
    );
  }
}
