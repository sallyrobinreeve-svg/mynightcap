import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/prompts.dart';
import '../models/entry_models.dart';
import '../models/friend_models.dart';
import '../services/entry_service.dart';
import '../services/friends_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
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
  PickedUpload? outfit;
  PickedUpload? favourite;
  String? outfitUrl;
  String? favouriteUrl;
  String? videoUrl;
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
        outfitUrl = data.outfitUrl;
        favouriteUrl = data.favouriteUrl;
        videoUrl = data.videoUrl;
        timelineSteps
          ..clear()
          ..addAll(data.timeline);
        taggedUserIds
          ..clear()
          ..addAll(data.taggedUserIds);
      }
    } catch (_) {
      message = 'Could not load entry.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickPhoto(String type) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null) return;
    setState(() => message = null);
    try {
      final upload = await uploadPickedFile(file, type);
      setState(() {
        if (type == 'outfit') {
          outfit = upload;
          outfitUrl = upload.url;
        } else {
          favourite = upload;
          favouriteUrl = upload.url;
        }
      });
    } catch (_) {
      setState(() => message = 'Photo upload failed. Please try again.');
    }
  }

  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => message = null);
    try {
      final upload = await uploadVideoFile(file);
      setState(() => videoUrl = upload.url);
    } catch (_) {
      setState(() => message = 'Video upload failed. Please try again.');
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
          outfit: outfit,
          favourite: favourite,
          existingOutfitUrl: outfit == null ? outfitUrl : null,
          existingFavouriteUrl: favourite == null ? favouriteUrl : null,
          videoUrl: videoUrl,
          timeline: timelineSteps,
          taggedUserIds: taggedUserIds.toList(),
        );
      } else {
        await entryService.createEntry(
          date: date,
          rating: rating!,
          visibility: visibility,
          prompts: promptValues,
          outfit: outfit,
          favourite: favourite,
          videoUrl: videoUrl,
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
          outfit = null;
          favourite = null;
          outfitUrl = null;
          favouriteUrl = null;
          videoUrl = null;
          promptValues.clear();
          timelineSteps.clear();
          taggedUserIds.clear();
        });
      }
    } catch (_) {
      setState(
        () => message =
            'Could not save entry. Check your connection and permissions.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _setPromptValue(PromptDefinition prompt, dynamic value) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      promptValues.remove(prompt.id);
      if (prompt.privateByDefault) {
        promptValues.remove('kissedPrivate');
      }
      return;
    }
    promptValues[prompt.id] = value;
    if (prompt.id == 'kissedAnyone' && value == prompt.toggleLabels.first) {
      promptValues['kissedPrivate'] = true;
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of night'),
                  subtitle: Text(DateFormat.yMMMMd().format(date)),
                  trailing: const Icon(Icons.calendar_today),
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
                const Text('Rating'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(5, (i) {
                    final value = i + 1;
                    return ChoiceChip(
                      label: Text('$value'),
                      selected: rating == value,
                      onSelected: (_) => setState(() => rating = value),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PhotoButton(
                        label: outfitUrl == null ? 'Outfit photo' : 'Outfit added',
                        icon: Icons.checkroom,
                        onTap: () => pickPhoto('outfit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PhotoButton(
                        label: favouriteUrl == null
                            ? 'Favourite photo'
                            : 'Favourite added',
                        icon: Icons.favorite,
                        onTap: () => pickPhoto('favourite'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PhotoButton(
                  label: videoUrl == null ? 'Add video' : 'Video added',
                  icon: Icons.videocam_outlined,
                  onTap: pickVideo,
                ),
                const SizedBox(height: 18),
                TimelineEditor(
                  steps: timelineSteps,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 18),
                const Text('Tag friends', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    const Text('Prompts', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => showAllPrompts = !showAllPrompts),
                      child: Text(showAllPrompts ? 'Show fewer' : 'Show all'),
                    ),
                  ],
                ),
                for (final prompt in prompts) ...[
                  const SizedBox(height: 10),
                  _PromptField(
                    prompt: prompt,
                    value: promptValues[prompt.id],
                    onChanged: (value) => setState(() => _setPromptValue(prompt, value)),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : saveEntry,
                    child: Text(
                      saving
                          ? 'Saving...'
                          : widget.isEditing
                          ? 'Save changes'
                          : 'Post entry',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptField extends StatefulWidget {
  const _PromptField({
    required this.prompt,
    required this.value,
    required this.onChanged,
  });

  final PromptDefinition prompt;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<_PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<_PromptField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _PromptField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value?.toString() != _textController.text) {
      _textController.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt.label, style: const TextStyle(color: NightColors.muted)),
        const SizedBox(height: 6),
        switch (prompt.inputType) {
          PromptInputType.textarea => TextField(
            controller: _textController,
            maxLines: 3,
            decoration: nightInputDecoration(prompt.placeholder ?? 'Your answer'),
            onChanged: widget.onChanged,
          ),
          PromptInputType.slider => Slider(
            value: (widget.value as num?)?.toDouble() ?? prompt.sliderMin.toDouble(),
            min: prompt.sliderMin.toDouble(),
            max: prompt.sliderMax.toDouble(),
            divisions: prompt.sliderMax - prompt.sliderMin,
            label: '${widget.value ?? prompt.sliderMin}',
            onChanged: widget.onChanged,
          ),
          PromptInputType.toggle => SegmentedButton<String>(
            segments: [
              ButtonSegment(value: prompt.toggleLabels[0], label: Text(prompt.toggleLabels[0])),
              ButtonSegment(value: prompt.toggleLabels[1], label: Text(prompt.toggleLabels[1])),
            ],
            selected: {widget.value?.toString() ?? prompt.toggleLabels[1]},
            onSelectionChanged: (selection) => widget.onChanged(selection.first),
          ),
          PromptInputType.choices => Wrap(
            spacing: 8,
            children: [
              for (final choice in prompt.choices)
                ChoiceChip(
                  label: Text(choice),
                  selected: widget.value == choice,
                  onSelected: (_) => widget.onChanged(choice),
                ),
            ],
          ),
          PromptInputType.text => TextField(
            controller: _textController,
            decoration: nightInputDecoration(prompt.placeholder ?? 'Your answer'),
            onChanged: widget.onChanged,
          ),
        },
      ],
    );
  }
}
