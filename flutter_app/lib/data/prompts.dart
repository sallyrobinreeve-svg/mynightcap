enum PromptInputType { text, textarea, slider, toggle, choices }

class PromptDefinition {
  const PromptDefinition({
    required this.id,
    required this.label,
    required this.category,
    required this.inputType,
    this.placeholder,
    this.sliderMin = 1,
    this.sliderMax = 10,
    this.toggleLabels = const ['Yes', 'No'],
    this.choices = const [],
    this.privateByDefault = false,
    this.canBePrivate = false,
  });

  final String id;
  final String label;
  final String category;
  final PromptInputType inputType;
  final String? placeholder;
  final int sliderMin;
  final int sliderMax;
  final List<String> toggleLabels;
  final List<String> choices;
  final bool privateByDefault;
  final bool canBePrivate;
}

const hiddenPromptIds = {'chaos'};

const defaultPromptIds = [
  'whoWasDrunkest',
  'funniestThing',
  'songOfNight',
  'oneWordVibe',
  'generalComment',
];

const promptDefinitions = [
  PromptDefinition(
    id: 'whoWasDrunkest',
    label: 'Who was the drunkest',
    category: 'Recap',
    inputType: PromptInputType.text,
    placeholder: 'Name',
    canBePrivate: true,
  ),
  PromptDefinition(
    id: 'funniestThing',
    label: 'The funniest bit',
    category: 'Recap',
    inputType: PromptInputType.textarea,
    placeholder: "The one you'll all repeat tomorrow",
    canBePrivate: true,
  ),
  PromptDefinition(
    id: 'quoteOfNight',
    label: 'Line of the night',
    category: 'Recap',
    inputType: PromptInputType.text,
    placeholder: 'What someone actually said',
  ),
  PromptDefinition(
    id: 'kissedAnyone',
    label: 'Anyone get kissed?',
    category: 'Recap',
    inputType: PromptInputType.toggle,
    privateByDefault: true,
  ),
  PromptDefinition(
    id: 'kissedWho',
    label: 'Who with?',
    category: 'Recap',
    inputType: PromptInputType.text,
    placeholder: 'Optional',
    privateByDefault: true,
  ),
  PromptDefinition(
    id: 'homeTime',
    label: 'Home time',
    category: 'Recap',
    inputType: PromptInputType.text,
    placeholder: '3am, sunrise, no idea',
  ),
  PromptDefinition(
    id: 'songOfNight',
    label: 'The song',
    category: 'Party',
    inputType: PromptInputType.text,
    placeholder: 'What was playing',
  ),
  PromptDefinition(
    id: 'oneWordVibe',
    label: 'One word',
    category: 'Reflection',
    inputType: PromptInputType.text,
    placeholder: "One word. That's it.",
  ),
  PromptDefinition(
    id: 'tonightsObjective',
    label: 'Mission of the night',
    category: 'Mission',
    inputType: PromptInputType.text,
    placeholder: 'What was the mission?',
  ),
  PromptDefinition(
    id: 'missionResult',
    label: 'Mission result',
    category: 'Mission',
    inputType: PromptInputType.text,
  ),
  PromptDefinition(
    id: 'generalComment',
    label: 'Notable mentions',
    category: 'Reflection',
    inputType: PromptInputType.textarea,
    placeholder: 'Anyone or anything else worth logging',
    canBePrivate: true,
  ),
  PromptDefinition(
    id: 'nightMvp',
    label: 'Who carried',
    category: 'Social',
    inputType: PromptInputType.text,
  ),
  PromptDefinition(
    id: 'drinkOfChoice',
    label: 'What you were drinking',
    category: 'Party',
    inputType: PromptInputType.text,
  ),
  PromptDefinition(
    id: 'coreMemory',
    label: "The bit you'll keep",
    category: 'Reflection',
    inputType: PromptInputType.textarea,
  ),
];

final promptLabelById = {
  for (final prompt in promptDefinitions) prompt.id: prompt.label,
};

List<PromptDefinition> defaultPrompts() {
  final byId = {for (final p in promptDefinitions) p.id: p};
  return [
    for (final id in defaultPromptIds)
      if (byId[id] != null) byId[id]!,
  ];
}

List<PromptDefinition> extraPrompts() {
  final defaults = defaultPromptIds.toSet();
  return [
    for (final prompt in promptDefinitions)
      if (!defaults.contains(prompt.id) && !hiddenPromptIds.contains(prompt.id))
        prompt,
  ];
}

String promptDisplayLabel(String id) => promptLabelById[id] ?? id;
