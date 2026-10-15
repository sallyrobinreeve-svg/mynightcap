import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  List<String> photoUrls = [];
  List<String> videoUrls = [];
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
        photoUrls = [...data.photoUrls];
        videoUrls = [...data.videoUrls];
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

  Future<void> addPhotos() async {
    final remaining = maxEntryPhotos - photoUrls.length;
    if (remaining <= 0) {
      setState(() => message = 'You can add up to 10 photos.');
      return;
    }
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 88, limit: remaining);
    if (files.isEmpty) return;
    setState(() => message = null);
    try {
      final added = <String>[];
      for (final file in files.take(remaining)) {
        final upload = await uploadPickedFile(file, 'photo');
        added.add(upload.url);
      }
      if (!mounted) return;
      setState(() => photoUrls = [...photoUrls, ...added]);
    } catch (_) {
      setState(() => message = 'Photo upload failed. Please try again.');
    }
  }

  Future<void> addVideo() async {
    if (videoUrls.length >= maxEntryVideos) {
      setState(() => message = 'You can add up to 5 videos.');
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => message = null);
    try {
      final upload = await uploadVideoFile(file);
      if (!mounted) return;
      setState(() => videoUrls = [...videoUrls, upload.url]);
    } catch (_) {
      setState(() => message = 'Video upload failed. Please try again.');
    }
  }

  void _move(List<String> urls, int index, int direction) {
    final next = index + direction;
    if (next < 0 || next >= urls.length) return;
    final item = urls.removeAt(index);
    urls.insert(next, item);
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
          photoUrls: photoUrls,
          videoUrls: videoUrls,
          timeline: timelineSteps,
          taggedUserIds: taggedUserIds.toList(),
        );
      } else {
        await entryService.createEntry(
          date: date,
          rating: rating!,
          visibility: visibility,
          prompts: promptValues,
          photoUrls: photoUrls,
          videoUrls: videoUrls,
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
          photoUrls = [];
          videoUrls = [];
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
                  countLabel: '${photoUrls.length} / $maxEntryPhotos',
                  urls: photoUrls,
                  emptyLabel: 'Add photos',
                  icon: Icons.photo_library_outlined,
                  onAdd: photoUrls.length >= maxEntryPhotos ? null : addPhotos,
                  onMove: (index, direction) =>
                      setState(() => _move(photoUrls, index, direction)),
                  onRemove: (index) =>
                      setState(() => photoUrls.removeAt(index)),
                ),
                const SizedBox(height: 12),
                _MediaSection(
                  title: 'Videos',
                  countLabel: '${videoUrls.length} / $maxEntryVideos',
                  urls: videoUrls,
                  emptyLabel: 'Add video',
                  icon: Icons.videocam_outlined,
                  onAdd: videoUrls.length >= maxEntryVideos ? null : addVideo,
                  onMove: (index, direction) =>
                      setState(() => _move(videoUrls, index, direction)),
                  onRemove: (index) =>
                      setState(() => videoUrls.removeAt(index)),
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

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.title,
    required this.countLabel,
    required this.urls,
    required this.emptyLabel,
    required this.icon,
    required this.onAdd,
    required this.onMove,
    required this.onRemove,
  });

  final String title;
  final String countLabel;
  final List<String> urls;
  final String emptyLabel;
  final IconData icon;
  final VoidCallback? onAdd;
  final void Function(int index, int direction) onMove;
  final void Function(int index) onRemove;

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
        for (var i = 0; i < urls.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$title ${i + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  tooltip: 'Move up',
                  onPressed: i == 0 ? null : () => onMove(i, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: i == urls.length - 1 ? null : () => onMove(i, 1),
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
            filled: urls.isNotEmpty,
            onTap: onAdd!,
          ),
      ],
    );
  }
}
