export type PromptInputType = "text" | "textarea" | "slider" | "toggle" | "choices";

export interface PromptDefinition {
  id: string;
  label: string;
  category: string;
  inputType: PromptInputType;
  placeholder?: string;
  sliderMin?: number;
  sliderMax?: number;
  toggleLabels?: [string, string];
  choices?: string[];
  privateByDefault?: boolean;
}

export const PROMPT_CATEGORIES = [
  "Recap",
  "Story",
  "Social",
  "Party",
  "Chaotic",
  "Reflection",
  "The plan",
] as const;

export const PROMPTS: PromptDefinition[] = [
  {
    id: "chaos",
    label: "Chaos level",
    category: "Recap",
    inputType: "slider",
    sliderMin: 1,
    sliderMax: 10,
  },
  {
    id: "whoWasDrunkest",
    label: "Who was most gone",
    category: "Recap",
    inputType: "text",
    placeholder: "Name",
  },
  {
    id: "funniestThing",
    label: "The funniest bit",
    category: "Recap",
    inputType: "textarea",
    placeholder: "The one you'll all repeat tomorrow",
  },
  {
    id: "quoteOfNight",
    label: "Line of the night",
    category: "Recap",
    inputType: "text",
    placeholder: "What someone actually said",
  },
  {
    id: "kissedAnyone",
    label: "Anyone get kissed?",
    category: "Recap",
    inputType: "toggle",
    toggleLabels: ["Yes", "No"],
    privateByDefault: true,
  },
  {
    id: "kissedWho",
    label: "Who with?",
    category: "Recap",
    inputType: "text",
    placeholder: "Optional",
  },
  {
    id: "homeTime",
    label: "Home time",
    category: "Recap",
    inputType: "text",
    placeholder: "3am, sunrise, no idea",
  },
  {
    id: "mainCharacter",
    label: "Who ran it",
    category: "Story",
    inputType: "textarea",
    placeholder: "Who thought the night was about them",
  },
  {
    id: "plotTwist",
    label: "The turn",
    category: "Story",
    inputType: "textarea",
    placeholder: "When it stopped going to plan",
  },
  {
    id: "mostEmbarrassing",
    label: "The cringe",
    category: "Story",
    inputType: "textarea",
    placeholder: "The bit you'd rather skip",
  },
  {
    id: "highlight",
    label: "Best bit",
    category: "Story",
    inputType: "textarea",
  },
  {
    id: "lowestPoint",
    label: "When it dipped",
    category: "Story",
    inputType: "textarea",
  },
  {
    id: "nightMvp",
    label: "Who carried",
    category: "Social",
    inputType: "text",
  },
  {
    id: "lostSoldier",
    label: "Who we lost",
    category: "Social",
    inputType: "text",
    placeholder: "Last seen…",
  },
  {
    id: "unexpectedLegend",
    label: "Who came out of nowhere",
    category: "Social",
    inputType: "text",
  },
  {
    id: "metAnyoneNew",
    label: "Anyone new?",
    category: "Social",
    inputType: "text",
  },
  {
    id: "songOfNight",
    label: "The song",
    category: "Party",
    inputType: "text",
    placeholder: "What was playing",
  },
  {
    id: "drinkOfChoice",
    label: "What you were drinking",
    category: "Party",
    inputType: "text",
  },
  {
    id: "danceFloorRating",
    label: "Dancefloor",
    category: "Party",
    inputType: "slider",
    sliderMin: 1,
    sliderMax: 10,
  },
  {
    id: "bestLocation",
    label: "Best stop",
    category: "Party",
    inputType: "text",
  },
  {
    id: "biggestRedFlag",
    label: "The warning",
    category: "Chaotic",
    inputType: "textarea",
    placeholder: "The bit that should've been a no",
  },
  {
    id: "memoryGap",
    label: "Missing hours",
    category: "Chaotic",
    inputType: "textarea",
  },
  {
    id: "morningInvestigation",
    label: "What you reconstructed",
    category: "Chaotic",
    inputType: "textarea",
    placeholder: "Receipts, photos, group chat",
  },
  {
    id: "regretLevel",
    label: "Regret",
    category: "Chaotic",
    inputType: "slider",
    sliderMin: 1,
    sliderMax: 10,
  },
  {
    id: "coreMemory",
    label: "The bit you'll keep",
    category: "Reflection",
    inputType: "textarea",
  },
  {
    id: "oneWordVibe",
    label: "One word",
    category: "Reflection",
    inputType: "text",
    placeholder: "One word. That's it.",
  },
  {
    id: "wouldRepeat",
    label: "Do it again?",
    category: "Reflection",
    inputType: "toggle",
    toggleLabels: ["Yes", "No"],
  },
  {
    id: "tonightsObjective",
    label: "The plan",
    category: "The plan",
    inputType: "text",
    placeholder: "What you were going for",
  },
  {
    id: "missionResult",
    label: "Did it land?",
    category: "The plan",
    inputType: "text",
  },
  {
    id: "bonusAchievement",
    label: "Unplanned win",
    category: "The plan",
    inputType: "text",
  },
  {
    id: "generalComment",
    label: "Anything else",
    category: "Reflection",
    inputType: "textarea",
    placeholder: "The rest of it",
  },
];

export const DEFAULT_PROMPT_IDS = [
  "chaos",
  "whoWasDrunkest",
  "funniestThing",
  "kissedAnyone",
  "songOfNight",
  "oneWordVibe",
  "tonightsObjective",
  "generalComment",
];

export const TIMELINE_EMOJIS = ["🥂", "🏠", "🎉", "🍻", "🎶", "🕺", "🏃", "📱", "🍕", "☕", "🌟", "💃", "🎭", "🔥", "💫"];
