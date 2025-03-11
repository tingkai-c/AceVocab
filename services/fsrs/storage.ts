import { MMKVLoader } from "react-native-mmkv-storage";
import { StoredCard, AppFSRSParameters, CardWithReviewLog, VocabularyPreset } from "./types";
import {
  uploadCardToSupabase,
  fetchCardsFromSupabase,
  deleteCardFromSupabase,
  uploadFSRSParametersToSupabase,
  fetchFSRSParametersFromSupabase,
  uploadReviewLogToSupabase,
  isLoggedIn,
} from "../supabase"; // Import Supabase functions
import { supabase } from "../supabase";
import { Platform } from "react-native";
import { ReviewLog } from "ts-fsrs";
import { getPreset } from "../supabase";
const storage = new MMKVLoader().withInstanceID("fsrs-storage").initialize();

const CARD_KEY_PREFIX = "card:";
const PARAMETERS_KEY = "fsrs-parameters";
const PRESET_PREFIX = "preset:"

const DEFAULT_PRESET_ID = "0ea81186-374c-4a4d-8d47-51ced2403a29"

// --- Helper for Sync ---
const syncCard = async (card: StoredCard) => {
  try {
    if (await isLoggedIn()) {
      await uploadCardToSupabase(card);
    }
  } catch (e) {
    console.error("Sync Card Failed", e);
  }
};

const syncDeleteCard = async (cardId: string) => {
  try {
    if (await isLoggedIn()) {
      await deleteCardFromSupabase(cardId);
    }
  } catch (e) {
    console.error("Sync Card Deletion Failed", e);
  }
};

const syncParameters = async (params: AppFSRSParameters) => {
  try {
    if (await isLoggedIn()) {
      await uploadFSRSParametersToSupabase(params);
    }
  } catch (e) {
    console.error("Sync Parameters Failed", e);
  }
};

const syncReviewLog = async (
  reviewLog: ReviewLog,
  cardId: string,
  isNew: boolean
) => {
  try {
    if (await isLoggedIn()) {
      await uploadReviewLogToSupabase(reviewLog, cardId, isNew);
    }
  } catch (e) {
    console.error("Sync Review Log Failed", e);
  }
};

// --- Card Operations ---

export const saveCard = async (card: StoredCard): Promise<void> => {
  try {
    await storage.setMapAsync(`${CARD_KEY_PREFIX}${card.id}`, card);
    await syncCard(card); // Sync to Supabase
  } catch (error) {
    console.error("Error saving card:", error);
    throw error;
  }
};

export const loadCard = async (cardId: string): Promise<StoredCard | null> => {
  // Always load from local storage first
  try {
    const card = await storage.getMapAsync(`${CARD_KEY_PREFIX}${cardId}`);
    return card as StoredCard | null;
  } catch (error) {
    console.error("Error loading card:", error);
    return null;
  }
};

export const getAllCardIds = async (): Promise<string[]> => {
  // Local First
  try {
    const allKeys = await storage.indexer.getKeys();
    const filteredKeys = allKeys.filter((key: string) =>
      key.startsWith(CARD_KEY_PREFIX)
    );
    return filteredKeys.map((key: string) => key.replace(CARD_KEY_PREFIX, ""));
  } catch (e) {
    console.error("Error get all card ids:", e);
    return [];
  }
};

export const loadAllCards = async (): Promise<StoredCard[]> => {
  // Local First
  try {
    const cardIds = await getAllCardIds();
    const cards: StoredCard[] = [];
    for (const cardId of cardIds) {
      const card = await loadCard(cardId);
      if (card !== null) {
        cards.push(card);
      }
    }
    return cards;
  } catch (error) {
    console.error("loadAllCards failed", error);
    return [];
  }
};

export const deleteCard = async (cardId: string): Promise<void> => {
  try {
    await storage.removeItem(`${CARD_KEY_PREFIX}${cardId}`);
    await syncDeleteCard(cardId); // Sync deletion
  } catch (e) {
    console.error("Error deleting card:", e);
  }
};

// --- FSRS Parameters Operations ---

export const saveFSRSParameters = async (
  params: AppFSRSParameters
): Promise<void> => {
  try {
    await storage.setMapAsync(PARAMETERS_KEY, params);
    await syncParameters(params); // Sync parameters
  } catch (error) {
    console.error("Error saving FSRS parameters:", error);
    throw error;
  }
};

export const loadFSRSParameters =
  async (): Promise<AppFSRSParameters | null> => {
    // Load locally
    try {
      const params = await storage.getMapAsync(PARAMETERS_KEY);
      return params as AppFSRSParameters | null;
    } catch (error) {
      console.error("Error loading FSRS parameters:", error);
      return null;
    }
  };

// --- Review Log ---
export const saveReviewLog = async (
  reviewLog: ReviewLog,
  cardId: string,
  isNew: boolean
): Promise<void> => {
  // We don't store the review log locally. Only on Supabase.
  await syncReviewLog(reviewLog, cardId, isNew);
};

// --- Preset Operations ---
export const getAllPresetIDs = async (): Promise<string[]> => {
  // Local First
  try {
    const allKeys = await storage.indexer.getKeys();
    const filteredKeys = allKeys.filter((key: string) =>
      key.startsWith(PRESET_PREFIX)
    );
    return filteredKeys.map((key: string) => key.replace(PRESET_PREFIX, ""));
  } catch (e) {
    console.error("Error get all card ids:", e);
    return [];
  }
};

export const getAllSavedPreset = async (): Promise<VocabularyPreset[]> => {
  try {
    const presetIds = await getAllPresetIDs();
    const presets: VocabularyPreset[] = [];
    for (const presetId of presetIds) {
      const preset = await getSavedPreset(presetId);
      if (preset) {
        presets.push(preset);
      }
    }
    return presets;
  } catch (error) {
    console.error("Error loading presets:", error);
    return [];
  }
};



export const getSavedPreset = async (presetId: string): Promise<VocabularyPreset | null> => {
  try {
    let preset = await storage.getMapAsync(`${PRESET_PREFIX}${presetId}`);
    if (preset) {
      return preset as VocabularyPreset;
    }
  } catch (error) {
    console.error("Error loading preset from local:", error);
    return null;
  }


  // If not found locally, try fetching from Supabase
  try {
    let preset = await getPreset(presetId);
    if (preset) {
      // Save locally for future use
      await storage.setMapAsync(`${PRESET_PREFIX}${presetId}`, preset);
      return preset as VocabularyPreset;
    }
  } catch (error) {
    console.error("Error loading preset from supabase:", error);
    return null;
  }


  return null;
};

export const savePresets = async (preset: VocabularyPreset): Promise<void> => {
  try {
    await storage.setMapAsync(`${PRESET_PREFIX}${preset.id}`, preset);
  } catch (error) {
    console.error("Error saving preset:", error);
  }
};

// --- Initial Sync ---

export const synchronizeData = async (): Promise<void> => {
  if (!(await isLoggedIn())) {
    console.log("User not logged in, skipping sync.");
    return;
  }

  try {
    // 1. Fetch data from Supabase
    const supabaseCards = await fetchCardsFromSupabase();
    const supabaseParams = await fetchFSRSParametersFromSupabase();

    // 2. Merge with local data (Supabase wins in case of conflicts)
    if (supabaseCards.length > 0) {
      for (const supabaseCard of supabaseCards) {
        await storage.setMapAsync(
          `${CARD_KEY_PREFIX}${supabaseCard.id}`,
          supabaseCard
        );
      }
    }

    if (supabaseParams) {
      await storage.setMapAsync(PARAMETERS_KEY, supabaseParams);
    }

    // 3. Upload any local-only cards or parameters
    const localCards = await loadAllCards();
    for (const localCard of localCards) {
      //Check if the card exists on supabase
      const existingSupabaseCard = supabaseCards.find(
        (c) => c.id === localCard.id
      );
      if (!existingSupabaseCard) {
        // If it does not exists on supabase, upload.
        await uploadCardToSupabase(localCard);
      }
    }

    const localParams = await loadFSRSParameters();
    if (!supabaseParams && localParams) {
      await uploadFSRSParametersToSupabase(localParams);
    }
  } catch (error) {
    console.error("Error during synchronization:", error);
  }
};

export const clearAll = async (): Promise<void> => {
  try {
    await storage.clearStore();
  } catch (e) {
    console.error("Error clearing the storage", e);
  }
};
