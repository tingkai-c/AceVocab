import { Card, Rating, State, ReviewLog, FSRSParameters } from 'ts-fsrs';

export interface StoredCard extends Card {
  id: string; // Vocabulary ID
  // No cardData!
}

export interface ReviewInput {
  cardId: string;
  rating: Rating;
}

export interface AppFSRSParameters extends FSRSParameters { }

// Supabase Types
export interface SupabaseCard {
  id: string;
  user_id: string;
  due: string;
  stability: number;
  difficulty: number;
  elapsed_days: number;
  scheduled_days: number;
  reps: number;
  lapses: number;
  state: number;
  last_review: string | null;
  // No card_data
}

export interface SupabaseReviewLog {
  id?: number; // auto generated
  card_id: string;
  user_id: string;
  rating: number;
  state: number;
  due: string;
  stability: number,
  difficulty: number,
  elapsed_days: number,
  last_elapsed_days: number,
  scheduled_days: number,
  review: string,
  log_data?: Record<string, any> // Optional: Store generated question/answers
  is_new: boolean
}


export interface CardWithReviewLog extends StoredCard {
  reviewLog: ReviewLog
}


// Add a type for your vocabulary data from SQLite
export interface Vocabulary {
  id: string;  // Matches the card ID
  vocab: string;
  // ... any other fields you have in your SQLite vocabulary table ...
}

export interface VocabularyPreset {
  id: string;
  name: string;
  description?: string;
  owner_id?: string; // Optional
  created_at?: string;
  is_public: boolean;
  presetWords: string[]; // Array of vocabulary IDs
}

// Add a type for Supabase representation of VocabularyPreset
export interface SupabaseVocabularyPreset {
  id: string;
  name: string;
  description: string | null;
  owner_id: string | null;
  created_at: string | null;
  is_public: boolean;
}

