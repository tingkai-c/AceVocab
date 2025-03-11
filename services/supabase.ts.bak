import "react-native-url-polyfill/auto";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { createClient } from "@supabase/supabase-js";
import DatabaseService from "./local_database_service";
import NetInfo from "@react-native-community/netinfo";

const supabaseUrl = "https://ndlvkbhcwtntrhtkdllg.supabase.co";
const supabaseAnonKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kbHZrYmhjd3RudHJodGtkbGxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwMjg5OTAsImV4cCI6MjA1MjYwNDk5MH0.3apSGbuNmXhHLtNMKQzrozoJoZ8GkIkXiep4nOSgpis";

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});

export class WordData {
  seenCorrect: number;
  seenWrong: number;
  correct: number;
  wrong: number;

  constructor(
    id: number,
    seenCorrect: number,
    seenWrong: number,
    correct: number,
    wrong: number
  ) {
    this.seenCorrect = seenCorrect;
    this.seenWrong = seenWrong;
    this.correct = correct;
    this.wrong = wrong;
  }
  getPriority(): number {
    return (
      (this.seenWrong * 0.15 + this.wrong) /
      (this.seenCorrect * 0.15 + this.correct + 1)
    );
  }
}

export enum AnswerType {
  Correct = "Correct",
  Wrong = "Wrong",
  SeenCorrect = "SeenCorrect",
  SeenWrong = "SeenWrong",
}

const checkNetwork = async () => {
  try {
    const networkState = await NetInfo.fetch();
    return networkState.isConnected;
  } catch (e) {
    console.error("Error checking network:", e);
    return false;
  }
};

class SupabaseService {
  static userWords: { [wordId: string]: WordData } = {};

  static async getUser() {
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser();
    if (error) {
      console.error("Error getting user:", error);
      return null;
    }
    return user;
  }

  static async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) {
      console.error("Error signing out:", error);
      throw error;
    }
    this.userWords = {}; // Clear cached words
  }

  static async initializeProfile(userId: string) {
    const { error } = await supabase.from("profiles").upsert({
      id: userId,
      words: JSON.stringify({}),
      created_at: new Date().toISOString(),
    });

    if (error) {
      console.error("Error initializing profile:", error);
      throw error;
    }
  }

  static async fetchUserWords(): Promise<{ [wordId: string]: WordData }> {
    try {
      // Check network first
      const isConnected = await checkNetwork();
      if (!isConnected) {
        console.log("No network connection");
        return this.userWords; // Return cached data if available
      }

      const user = await this.getUser();
      if (!user) {
        console.log("No user found");
        return {};
      }

      // Add timeout for supabase requests
      const timeoutPromise = new Promise<{ data: null; error: Error }>(
        (_, reject) =>
          setTimeout(
            () =>
              reject({
                data: null,
                error: new Error("Request timeout"),
              }),
            10000
          )
      );

      // Actual request
      const requestPromise = supabase
        .from("profiles")
        .select("words")
        .eq("id", user.id)
        .single();

      // Race between timeout and actual request
      const { data, error } = await Promise.race([
        requestPromise,
        timeoutPromise,
      ]);

      if (error || !data || !data.words) {
        console.log("Error or no data:", error);
        return this.userWords; // Return cached data on error
      }

      try {
        // Handle multiple levels of JSON encoding
        let parsedWords = data.words;
        while (typeof parsedWords === "string") {
          try {
            parsedWords = JSON.parse(parsedWords);
          } catch {
            break;
          }
        }

        // Convert to WordData objects
        const result: { [wordId: string]: WordData } = {};
        for (const [id, data] of Object.entries(parsedWords)) {
          const wordData = data as {
            seenCorrect: number;
            seenWrong: number;
            correct: number;
            wrong: number;
          };
          result[id] = new WordData(
            parseInt(id),
            wordData.seenCorrect,
            wordData.seenWrong,
            wordData.correct,
            wordData.wrong
          );
        }
        this.userWords = result;
        return result;
      } catch (e) {
        console.error("Error parsing words data:", e);
        return {};
      }
    } catch (e) {
      console.error("Error fetching user words:", e);
      return this.userWords; // Return cached data on error
    }
  }

  static async getUserWords(): Promise<string[]> {
    const user = await this.getUser();
    if (!user) {
      console.log("No user found");
      return [];
    }

    const { data, error } = await supabase
      .from("profiles")
      .select("words")
      .eq("id", user.id)
      .single();

    if (error || !data || !data.words) {
      console.log("Error or no data:", error);
      return [];
    }

    try {
      // Handle multiple levels of JSON encoding
      let parsedWords = data.words;
      while (typeof parsedWords === "string") {
        try {
          parsedWords = JSON.parse(parsedWords);
        } catch {
          break;
        }
      }

      // Convert to WordData objects
      const result: string[] = [];
      for (const [id, data] of Object.entries(parsedWords)) {
        result.push(id);
      }
      return result;
    } catch (e) {
      console.error("Error parsing words data:", e);
      return [];
    }
  }

  static async updateUserWord(word: string, answerType: AnswerType) {
    const user = await this.getUser();
    if (!user) return;

    // Get word ID first
    const wordID = await DatabaseService.getWordID(word);
    if (!wordID) {
      console.error("Word ID not found for:", word);
      return;
    }

    // Get current words data
    let words = await this.fetchUserWords();

    // Update or create word data
    if (wordID in words) {
      const existingWord = words[wordID];
      switch (answerType) {
        case AnswerType.Correct:
          existingWord.correct++;
          break;
        case AnswerType.Wrong:
          existingWord.wrong++;
          break;
        case AnswerType.SeenCorrect:
          existingWord.seenCorrect++;
          break;
        case AnswerType.SeenWrong:
          existingWord.seenWrong++;
          break;
      }
    } else {
      words[wordID] = new WordData(wordID, 0, 0, 0, 0);
      switch (answerType) {
        case AnswerType.Correct:
          words[wordID].correct = 1;
          break;
        case AnswerType.Wrong:
          words[wordID].wrong = 1;
          break;
        case AnswerType.SeenCorrect:
          words[wordID].seenCorrect = 1;
          break;
        case AnswerType.SeenWrong:
          words[wordID].seenWrong = 1;
          break;
      }
    }

    // Update database with single JSON encoding
    const updates = {
      id: user.id,
      words: JSON.stringify(words),
    };

    const { error } = await supabase.from("profiles").upsert(updates);
    if (error) {
      console.error("Error updating word data:", error);
    }
  }

  static async getWordsForPreset(presetId: string): Promise<number[]> {
    const { data, error } = await supabase
      .from("preset_words")
      .select("word_id")
      .eq("preset_id", presetId);

    if (error) {
      console.error("Error fetching words for preset:", error);
      return [];
    }

    return data.map((item) => item.word_id);
  }

  static async getWordData(wordId: number): Promise<WordData> {
    const userWords = await this.fetchUserWords();
    return userWords[wordId];
  }
}

// Add auth state change listener to initialize profile for new users
supabase.auth.onAuthStateChange(async (event, session) => {
  if (event === "SIGNED_IN" && session?.user) {
    try {
      await SupabaseService.initializeProfile(session.user.id);
    } catch (error) {
      console.error("Error in auth state change handler:", error);
    }
  }
});

export default SupabaseService;
