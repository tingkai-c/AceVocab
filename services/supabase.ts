
import { createClient, SupabaseClient } from "@supabase/supabase-js";
import {
  StoredCard,
  SupabaseCard,
  AppFSRSParameters,
  SupabaseReviewLog,
  CardWithReviewLog,
  VocabularyPreset,
  SupabaseVocabularyPreset,
  Vocabulary,
} from "./fsrs/types";
import { State, Rating, ReviewLog } from "ts-fsrs";
import { Platform } from "react-native";
import "react-native-url-polyfill/auto";
import AsyncStorage from "@react-native-async-storage/async-storage";

const supabaseUrl = "https://ndlvkbhcwtntrhtkdllg.supabase.co";
const supabaseAnonKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kbHZrYmhjd3RudHJodGtkbGxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwMjg5OTAsImV4cCI6MjA1MjYwNDk5MH0.3apSGbuNmXhHLtNMKQzrozoJoZ8GkIkXiep4nOSgpis";

export const supabase: SupabaseClient = createClient(
  supabaseUrl,
  supabaseAnonKey,
  {
    auth: {
      storage: AsyncStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  }
);

// Helper function to convert a StoredCard to SupabaseCard
const cardToSupabase = (card: StoredCard, userId: string): SupabaseCard => ({
  id: card.id,
  user_id: userId,
  due: card.due.toISOString(), // Convert Date to ISO string
  stability: card.stability,
  difficulty: card.difficulty,
  elapsed_days: card.elapsed_days,
  scheduled_days: card.scheduled_days,
  reps: card.reps,
  lapses: card.lapses,
  state: card.state as number, // Cast enum to number
  last_review: card.last_review?.toISOString() ?? null, // Handle optional date
});

// Helper function to convert a SupabaseCard back to StoredCard
const supabaseToCard = (supabaseCard: SupabaseCard): StoredCard => ({
  id: supabaseCard.id,
  due: new Date(supabaseCard.due), // Convert ISO string back to Date
  stability: supabaseCard.stability,
  difficulty: supabaseCard.difficulty,
  elapsed_days: supabaseCard.elapsed_days,
  scheduled_days: supabaseCard.scheduled_days,
  reps: supabaseCard.reps,
  lapses: supabaseCard.lapses,
  state: supabaseCard.state as State, // Cast number back to enum
  last_review: supabaseCard.last_review
    ? new Date(supabaseCard.last_review)
    : undefined,
});

const reviewLogToSupabase = (
  reviewLog: ReviewLog,
  cardId: string,
  userId: string,
  isNew: boolean
): SupabaseReviewLog => {
  return {
    card_id: cardId,
    user_id: userId,
    rating: reviewLog.rating as number,
    state: reviewLog.state as number,
    due: reviewLog.due.toISOString(),
    stability: reviewLog.stability,
    difficulty: reviewLog.difficulty,
    elapsed_days: reviewLog.elapsed_days,
    last_elapsed_days: reviewLog.last_elapsed_days,
    scheduled_days: reviewLog.scheduled_days,
    review: reviewLog.review.toISOString(),
    is_new: isNew,
  };
};

// Helper function to convert VocabularyPreset to SupabaseVocabularyPreset
const presetToSupabase = (
  preset: VocabularyPreset
): SupabaseVocabularyPreset => ({
  id: preset.id,
  name: preset.name,
  description: preset.description ?? null,
  owner_id: preset.owner_id ?? null,
  created_at: preset.created_at ?? null,
  is_public: preset.is_public,
});

// Helper function to convert SupabaseVocabularyPreset to VocabularyPreset
const supabaseToPreset = (
  supabasePreset: SupabaseVocabularyPreset, presetWords: string[]
): VocabularyPreset => ({
  id: supabasePreset.id,
  name: supabasePreset.name,
  description: supabasePreset.description ?? undefined,
  owner_id: supabasePreset.owner_id ?? undefined,
  created_at: supabasePreset.created_at ?? undefined,
  is_public: supabasePreset.is_public,
  presetWords: presetWords
});

// --- Card Operations ---

export const fetchCardsFromSupabase = async (): Promise<StoredCard[]> => {
  const user = await supabase.auth.getUser();

  if (!user.data || !user.data.user) {
    console.warn("User not logged in");
    return [];
  }
  const userId = user.data.user.id;

  const { data, error } = await supabase
    .from("cards")
    .select("*")
    .eq("user_id", userId);

  if (error) {
    console.error("Error fetching cards from Supabase:", error);
    throw error;
  }

  return data ? data.map(supabaseToCard) : [];
};

export const uploadCardToSupabase = async (card: StoredCard): Promise<void> => {
  const user = await supabase.auth.getUser();
  if (!user.data || !user.data.user) {
    console.warn("User not logged in");
    return; // Or throw an error, depending on your needs
  }
  const userId = user.data.user.id;
  const supabaseCard = cardToSupabase(card, userId);
  // Use .upsert with the composite key for conflict handling
  const { error } = await supabase
    .from("cards")
    .upsert(supabaseCard, { onConflict: "id,user_id" });

  if (error) {
    console.error("Error uploading card to Supabase:", error);
    throw error;
  }
};

export const deleteCardFromSupabase = async (cardId: string): Promise<void> => {
  const user = await supabase.auth.getUser();
  if (!user.data || !user.data.user) {
    console.warn("User not logged in");
    return;
  }
  const userId = user.data.user.id;

  const { error } = await supabase
    .from("cards")
    .delete()
    .eq("id", cardId)
    .eq("user_id", userId);

  if (error) {
    console.error("Error deleting card from Supabase:", error);
    throw error;
  }
};

// --- FSRS Parameters Operations ---

export const fetchFSRSParametersFromSupabase =
  async (): Promise<AppFSRSParameters | null> => {
    const user = await supabase.auth.getUser();
    if (!user.data || !user.data.user) {
      console.warn("User not logged in");
      return null;
    }
    const userId = user.data.user.id;
    const { data, error } = await supabase
      .from("fsrs_parameters")
      .select("parameters")
      .eq("user_id", userId)
      .single(); // Use single() since there should be only one row per user

    if (error) {
      if (error.code === "PGRST116") {
        //PGRST116 means that no record was found
        return null; // No parameters found, return null (use defaults)
      }
      console.error("Error fetching FSRS parameters from Supabase:", error);
      throw error;
    }

    return data ? (data.parameters as AppFSRSParameters) : null;
  };

export const uploadFSRSParametersToSupabase = async (
  params: AppFSRSParameters
): Promise<void> => {
  const user = await supabase.auth.getUser();
  if (!user.data || !user.data.user) {
    console.warn("User not logged in");
    return;
  }
  const userId = user.data.user.id;
  const { error } = await supabase
    .from("fsrs_parameters")
    .upsert([{ user_id: userId, parameters: params }]);

  if (error) {
    console.error("Error uploading FSRS parameters to Supabase:", error);
    throw error;
  }
};

// --- Review Logs ---
export const uploadReviewLogToSupabase = async (
  reviewLog: ReviewLog,
  cardId: string,
  isNew: boolean
): Promise<void> => {
  const user = await supabase.auth.getUser();
  if (!user.data || !user.data.user) {
    console.warn("User not logged in");
    return;
  }
  const userId = user.data.user.id;

  const supabaseLog = reviewLogToSupabase(reviewLog, cardId, userId, isNew);
  const { error } = await supabase.from("review_logs").insert([supabaseLog]);

  if (error) {
    console.error("Error uploading review log to Supabase:", error);
    throw error;
  }
};

export const fetchReviewLogs = async (
  cardId: string
): Promise<SupabaseReviewLog[]> => {
  const user = await supabase.auth.getUser();
  if (!user.data || !user.data.user) {
    console.warn("User not logged in");
    return [];
  }
  const userId = user.data.user.id;
  const { data, error } = await supabase
    .from("review_logs")
    .select("*")
    .eq("card_id", cardId)
    .eq("user_id", userId);

  if (error) {
    console.error("Error fetching review log to Supabase:", error);
    throw error;
  }
  return data ? data : [];
};

// --- Vocabulary Preset Operations ---
// Create Preset
export const uploadVocabularyPreset = async (
  preset: VocabularyPreset
): Promise<void> => {
  const supabasePreset = presetToSupabase(preset);
  const { error } = await supabase
    .from("vocabulary_presets")
    .insert([supabasePreset]);

  if (error) {
    console.error("Failed to create preset", error);
    throw error;
  }
};

// Get Presets
export const getAllVocabularyPresets = async (): Promise<SupabaseVocabularyPreset[]> => {
  const { data, error } = await supabase
    .from("presets")
    .select("*")
    .eq("is_public", true);

  if (error) {
    console.error("Error fetching vocabulary presets:", error);
    throw error;
  }

  return data;
};

export const getVocabularyPresetWordIDs = async (presetID: string): Promise<string[]> => {
  const { data, error } = await supabase
    .from("preset_words")
    .select("preset_id,word_id")
    .eq("preset_id", presetID)
  if (error) {
    console.error("Error fetching words for preset ${presetID}")
  }
  const list: string[] | undefined = data?.map((item) => item.word_id)
  return list ?? []
}

export const getPreset = async (presetID: string): Promise<VocabularyPreset | null> => {
  const { data, error } = await supabase
    .from("presets")
    .select("*")
    .eq("id", presetID)
    .single();

  const words = await getVocabularyPresetWordIDs(presetID)

  if (error) {
    console.error("Error fetching preset info:", error);
    throw error;
  }

  if (!data) {
    console.warn(`No preset found with ID: ${presetID}`);
    return null;
  }

  return supabaseToPreset(data, words);
};

// Get Presets created by user.
export const getUserCreatedPresets = async (): Promise<VocabularyPreset[]> => {
  const user = await supabase.auth.getUser();
  if (!user.data || !user.data.user) {
    console.warn("User not logged in");
    return [];
  }
  const userId = user.data.user.id;
  const { data, error } = await supabase
    .from("presets")
    .select("id")
    .eq("created_by", userId);

  if (error) {
    console.error("Failed to fetch user created presets", error);
    throw error;
  }

  const presetIds = data ? data.map((item) => item.id) : [];
  const presets: VocabularyPreset[] = [];

  for (const presetId of presetIds) {
    const preset = await getPreset(presetId);
    if (preset) {
      presets.push(preset);
    }
  }

  return presets;
};

// Delete Preset
export const deleteVocabularyPreset = async (
  presetId: string
): Promise<void> => {
  const user = await supabase.auth.getUser();
  if (!user.data || !user.data.user) {
    console.warn("User not logged in");
    return;
  }
  const userId = user.data.user.id;
  const { error } = await supabase
    .from("vocabulary_presets")
    .delete()
    .eq("id", presetId)
    .eq("user_id", userId);

  if (error) {
    console.error("Failed to delete preset", error);
    throw error;
  }
};

// User-related functions (from your original SupabaseService)

export async function getUser() {
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();
  if (error) {
    console.warn("Error getting user:", error);
    return null;
  }
  return user;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) {
    console.error("Error signing out:", error);
    throw error;
  }
}

export async function isLoggedIn(): Promise<boolean> {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  return session != null;
}

export async function initializeProfile(userId: string) {
  const { error } = await supabase.from("profiles").upsert({
    id: userId,
    created_at: new Date().toISOString(),
  });

  if (error) {
    console.error("Error initializing profile:", error);
    throw error;
  }
}

// Add auth state change listener

supabase.auth.onAuthStateChange(async (event, session) => {
  if (event === "SIGNED_IN" && session?.user) {
    try {
      await initializeProfile(session.user.id);
    } catch (error) {
      console.error("Error in auth state change handler:", error);
    }
  }
});
