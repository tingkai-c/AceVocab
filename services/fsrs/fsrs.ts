// src/fsrs/fsrs.ts
import { fsrs, createEmptyCard, Rating, Grade } from "ts-fsrs";
import {
  StoredCard,
  ReviewInput,
  AppFSRSParameters,
  CardWithReviewLog,
  Vocabulary,
  VocabularyPreset,
} from "./types";
import {
  saveCard,
  loadCard,
  loadFSRSParameters,
  saveFSRSParameters,
  deleteCard,
  loadAllCards,
  synchronizeData,
  getSavedPreset
} from "./storage";
import { generatorParameters } from "ts-fsrs";
import { getVocabularyById } from "@/services/local_vocab_db"; // Import vocab functions
import {
  supabase,
  uploadReviewLogToSupabase,
  getUser,
  getAllVocabularyPresets,
} from "../supabase"; // Import supabase functions
import { MMKVLoader } from "react-native-mmkv-storage";
import { FSRS } from "ts-fsrs";

let currentParameters: AppFSRSParameters;

// Get the FSRS instance
let f: FSRS;

export const initFSRS = async () => {
  const user = await getUser();
  if (!user) {
    console.warn("User not logged in");
    return;
  }

  const loadedParams = await loadFSRSParameters();
  if (loadedParams) {
    currentParameters = loadedParams;
  } else {
    // Use default parameters if none are saved
    currentParameters = generatorParameters({
      request_retention: 0.9,
      maximum_interval: 36525,
      w: [
        0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14, 0.94, 2.18,
        0.05, 0.34, 1.26, 0.29, 2.61,
      ],
      enable_fuzz: true,
    }); // Set your defaults
    await saveFSRSParameters(currentParameters);
  }
  f = fsrs(currentParameters);
  await synchronizeData();
};

// Add Vocabulary card (when a user chooses to learn a new word)
export const addVocabularyCard = async (
  vocabId: string
): Promise<StoredCard> => {
  const vocab = await getVocabularyById(vocabId);
  if (!vocab) {
    throw new Error("Vocab not found in local db");
  }
  const newCard: StoredCard = {
    ...createEmptyCard(),
    id: vocabId, // Use the vocabulary ID!
  };
  await saveCard(newCard);
  return newCard;
};

export const reviewCard = async ({
  cardId,
  rating: grade,
  isNew,
}: {
  cardId: string;
  rating: Grade;
  isNew: boolean;
}): Promise<CardWithReviewLog> => {
  const card = await loadCard(cardId);
  if (!card) {
    throw new Error(`Card not found: ${cardId}`);
  }

  const now = new Date();

  const scheduledCard = f.next(card, now, grade)

  const updatedCard: StoredCard = {
    ...scheduledCard.card,
    id: card.id, // Keep the original ID
  };
  const result: CardWithReviewLog = {
    ...updatedCard,
    reviewLog: scheduledCard.log,
  };
  await saveCard(updatedCard);
  await uploadReviewLogToSupabase(scheduledCard.log, card.id, isNew); // Pass isNew
  return result;
};

// Example:  Get the next card to review (simplified)
export const getNextReviewCard = async (): Promise<StoredCard | null> => {
  const allCards = await loadAllCards();
  if (allCards.length === 0) {
    return null;
  }

  // Find the card with the earliest due date
  let nextCard: StoredCard | null = null;
  let earliestDue = new Date(8640000000000000); //A very large date.

  for (const card of allCards) {
    if (card.due < earliestDue) {
      earliestDue = card.due;
      nextCard = card;
    }
  }

  return nextCard;
};

export const deleteVocabularyCard = async (vocabId: string): Promise<void> => {
  await deleteCard(vocabId);
};

// Function to get a random word ID that the user hasn't added yet from their selected presets
const PRESETS_KEY = "user-presets";

// Load user selected presets from local storage
const loadSelectedPresetIds = async (): Promise<string[]> => {
  const storage = new MMKVLoader().initialize();
  try {
    const presetIds = await storage.getArrayAsync(PRESETS_KEY);
    return (presetIds as string[]) || [];
  } catch (error) {
    console.error("Error loading selected presets:", error);
    return [];
  }
};

// Save user selected presets to local storage
const saveSelectedPresetIds = async (presetIds: string[]): Promise<void> => {
  const storage = new MMKVLoader().initialize();
  try {
    await storage.setArrayAsync(PRESETS_KEY, presetIds);
  } catch (error) {
    console.error("Error saving selected presets:", error);
  }
};

export const addSelectedPresetId = async (presetId: string): Promise<void> => {
  const currentPresets = await loadSelectedPresetIds();
  if (!currentPresets.includes(presetId)) {
    currentPresets.push(presetId);
    await saveSelectedPresetIds(currentPresets);
  }
};

export const removeSelectedPresetId = async (
  presetId: string
): Promise<void> => {
  const currentPresets = await loadSelectedPresetIds();
  const newPresets = currentPresets.filter((id) => id !== presetId);
  await saveSelectedPresetIds(newPresets);
};

// Function to get a random word ID from user's selected presets
export const getRandomUnlearnedVocabularyId = async (): Promise<
  string | null
> => {
  // Load user's selected preset IDs from local storage (MMKV)
  const selectedPresetIds = await loadSelectedPresetIds();
  if (selectedPresetIds.length === 0) {
    console.warn("User has not selected any presets!");
    return null;
  }

  // Fetch preset details from local storage (and Supabase if not found locally)
  const selectedPresets: VocabularyPreset[] = [];
  for (const presetId of selectedPresetIds) {
    const preset = await getSavedPreset(presetId);
    if (preset) {
      selectedPresets.push(preset);
    }
  }

  // Flatten all vocabulary IDs from all selected presets into a single array
  const allPresetVocabIds: string[] = selectedPresets.reduce(
    (acc: string[], preset) => {
      return acc.concat(preset.presetWords);
    },
    []
  );

  // Remove duplicates by converting to a Set and back to an array
  const uniquePresetVocabIds = Array.from(new Set(allPresetVocabIds));

  // Get all cards the user has already added
  const learnedCards = await loadAllCards();
  const learnedCardIds = learnedCards.map((card) => card.id);

  // Find vocabulary IDs that haven't been added yet
  const unlearnedVocabIds = uniquePresetVocabIds.filter(
    (vocabId) => !learnedCardIds.includes(vocabId)
  );

  // If there are no unlearned words from the presets, return null
  if (unlearnedVocabIds.length === 0) {
    console.log("User has learned all words from selected presets!");
    return null;
  }

  // Pick a random ID from the unlearnedVocabIds array
  const randomIndex = Math.floor(Math.random() * unlearnedVocabIds.length);
  return unlearnedVocabIds[randomIndex];
};


export const getNextWord = async (): Promise<string | null> => {
  const reviewWord = await getNextReviewCard()
  if (reviewWord != null) {
    reviewWord.id
  }
  const exploreWord = await getRandomUnlearnedVocabularyId()

  if (exploreWord != null) {
    return exploreWord
  }
  return "hello"
}
