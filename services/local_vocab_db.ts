
// src/fsrs/vocab.ts
import * as SQLite from 'expo-sqlite';
import * as FileSystem from 'expo-file-system';
import { Asset } from 'expo-asset';
import { Vocabulary } from './fsrs/types';

let db: SQLite.SQLiteDatabase | null = null;

export const openVocabularyDB = async (): Promise<void> => {
  if (db) {
    return; // Already open
  }

  const localFolder = FileSystem.documentDirectory + "SQLite";
  const dbName = "vocabulary.db";
  const localURI = localFolder + "/" + dbName;

  try {
    // Ensure the SQLite directory exists
    const dirInfo = await FileSystem.getInfoAsync(localFolder);
    if (!dirInfo.exists) {
      await FileSystem.makeDirectoryAsync(localFolder, { intermediates: true });
    }

    // Check if the database file already exists locally
    const fileInfo = await FileSystem.getInfoAsync(localURI);
    if (!fileInfo.exists) {
      // Download the database asset
      const asset = Asset.fromModule(require('@/assets/vocabulary.db')); // Correct path to your asset
      await asset.downloadAsync();

      // Copy the downloaded asset to the local file system
      if (asset.localUri) {
        await FileSystem.copyAsync({
          from: asset.localUri,
          to: localURI,
        });
      } else {
        throw new Error("Failed to download vocab db")
      }

      console.log('Vocabulary database copied to local storage.');
    } else {
      console.log('Vocabulary database already exists locally.');
    }

    // Open the database
    db = await SQLite.openDatabaseAsync(dbName);
    console.log("DB opened")
    // Create Table


    console.log('Vocabulary database opened successfully.');

  } catch (error) {
    console.error('Error opening vocabulary database:', error);
    throw error; // Re-throw to handle it higher up
  }
};


// Close the database when your app is unmounted or goes to the background
export const closeVocabularyDB = async () => {
  if (db) {
    await db.closeAsync();
    db = null;
    console.log('Vocabulary database closed.');
  }
};


// Function to get vocabulary data by ID
export const getVocabularyById = async (id: string): Promise<Vocabulary | null> => {
  if (!db) {
    await openVocabularyDB();
  }
  try {
    const result = (await db?.getAllAsync(
      "SELECT word FROM words WHERE id = ?",
      [id]
    )) as { word: string }[];
    return { vocab: result[0].word, id };
  } catch (error) {
    console.error("Error fetching word:", error);
    throw error;
  }

};

export const getWordID = async (word: string): Promise<number | null> => {


  if (!db) {
    await openVocabularyDB();
  }
  try {
    const result = (await db?.getAllAsync(
      "SELECT id FROM words WHERE word = ?",
      [word]
    )) as { id: number }[];
    // console.log("Fetched word ID:", result[0].id);
    return result[0].id;
  } catch (error) {
    console.error("Error fetching word ID:", error);
    throw error;
  }

  return null;


}
