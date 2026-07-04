import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/prompts.dart';
import '../models/entry_models.dart';
import '../services/entry_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/night_widgets.dart';

class CreateEntryScreen extends StatefulWidget {
  const CreateEntryScreen({super.key});

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  DateTime date = DateTime.now();
  int? rating;
  String visibility = 'friends';
  PickedUpload? outfit;
  PickedUpload? favourite;
  String? videoUrl;
  bool saving = false;
  String? message;
  final Map<String, dynamic> promptValues = {};
  bool showAllPrompts = false;

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
        } else {
          favourite = upload;
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
      await entryService.createEntry(
        date: date,
        rating: rating!,
        visibility: visibility,
        prompts: promptValues,
        outfit: outfit,
        favourite: favourite,
        videoUrl: videoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry posted.')),
      );
      setState(() {
        rating = null;
        outfit = null;
        favourite = null;
        videoUrl = null;
        promptValues.clear();
      });
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
        promptValues.remove('${prompt.id}Private');
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
    final prompts = showAllPrompts
        ? [...defaultPrompts(), ...extraPrompts()]
        : defaultPrompts();

    return NightScaffold(
      title: 'Create',
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
                        label: outfit == null ? 'Outfit photo' : 'Outfit added',
                        icon: Icons.checkroom,
                        onTap: () => pickPhoto('outfit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PhotoButton(
                        label: favourite == null
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
                const SizedBox(height: 8),
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
                    child: Text(saving ? 'Posting...' : 'Post entry'),
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

class _PromptField extends StatelessWidget {
  const _PromptField({
    required this.prompt,
    required this.value,
    required this.onChanged,
  });

  final PromptDefinition prompt;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt.label, style: const TextStyle(color: NightColors.muted)),
        const SizedBox(height: 6),
        switch (prompt.inputType) {
          PromptInputType.textarea => TextField(
            maxLines: 3,
            decoration: nightInputDecoration(prompt.placeholder ?? 'Your answer'),
            onChanged: onChanged,
          ),
          PromptInputType.slider => Slider(
            value: (value as num?)?.toDouble() ?? prompt.sliderMin.toDouble(),
            min: prompt.sliderMin.toDouble(),
            max: prompt.sliderMax.toDouble(),
            divisions: prompt.sliderMax - prompt.sliderMin,
            label: '${value ?? prompt.sliderMin}',
            onChanged: onChanged,
          ),
          PromptInputType.toggle => SegmentedButton<String>(
            segments: [
              ButtonSegment(value: prompt.toggleLabels[0], label: Text(prompt.toggleLabels[0])),
              ButtonSegment(value: prompt.toggleLabels[1], label: Text(prompt.toggleLabels[1])),
            ],
            selected: {value?.toString() ?? prompt.toggleLabels[1]},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
          PromptInputType.choices => Wrap(
            spacing: 8,
            children: [
              for (final choice in prompt.choices)
                ChoiceChip(
                  label: Text(choice),
                  selected: value == choice,
                  onSelected: (_) => onChanged(choice),
                ),
            ],
          ),
          PromptInputType.text => TextField(
            decoration: nightInputDecoration(prompt.placeholder ?? 'Your answer'),
            onChanged: onChanged,
          ),
        },
      ],
    );
  }
}
