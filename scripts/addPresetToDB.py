import json
import random
import os
import google.generativeai as genai
import sqlite3
from typing import Tuple, List, Optional
import concurrent.futures
import sys


def get_clean_words(filepath):
    """
    Extracts and cleans vocabulary words from a file.

    Args:
        filepath: Path to the file containing vocabulary words.

    Returns:
        A list of unique, cleaned vocabulary words
    """
    words = set()
    try:
        with open(filepath, "r", encoding="utf-8") as file:
            for line in file:
                parts = line.split("#")
                if parts:
                    word = parts[0].strip()
                    if word:  # Ensure word is not empty
                        words.add(word)
    except FileNotFoundError:
        print(f"Error: File not found at {filepath}")
        return []  # Or raise the exception, depending on desired behavior

    return list(words)


def get_word_id(word: str) -> Optional[int]:
    """
    Retrieves the ID of a word from the database.

    Args:
        word: The word to search for.

    Returns:
        The ID of the word if found, otherwise None.
    """
    try:
        conn = sqlite3.connect("vocabulary.db")  # Connect to the database
        cursor = conn.cursor()

        # Use a parameterized query to prevent SQL injection
        cursor.execute("SELECT id FROM words WHERE word = ?", (word,))
        result = cursor.fetchone()

        if result:
            return result[0]  # Return the ID
        else:
            return None  # Word not found

    except sqlite3.Error as e:
        print(f"Database error: {e}")
        return None
    finally:
        if conn:
            conn.close()


def create_default_preset_table(conn):
    """Creates the default_preset table if it doesn't exist."""
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS default_preset (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                word_ids TEXT
            )
        """
        )
        conn.commit()
    except sqlite3.Error as e:
        print(f"Database error creating table: {e}")


def insert_default_preset(conn, name: str, description: str, word_ids: list):
    """Inserts a new preset into the default_preset table."""
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO default_preset (name, description, word_ids)
            VALUES (?, ?, ?)
        """,
            (name, description, json.dumps(word_ids)),
        )
        conn.commit()
    except sqlite3.Error as e:
        print(f"Database error inserting preset: {e}")


def main(filepath: str):
    """Main function to add a preset to the database."""

    words = get_clean_words(filepath)
    if not words:
        print("No words found in the file.")
        return

    word_ids = []
    for word in words:
        word_id = get_word_id(word)
        if word_id:
            word_ids.append(str(word_id))  # Convert to string for joining
        else:
            print(f"Word '{word}' not found in the database.")

    if not word_ids:
        print("No word IDs found.")
        return

    try:
        conn = sqlite3.connect("vocabulary.db")
        create_default_preset_table(conn)  # Create table if it doesn't exist
        insert_default_preset(conn, "TOEFL", "", word_ids)
        print("Preset 'TOEFL' added successfully.")

    except sqlite3.Error as e:
        print(f"Database error: {e}")
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    filepath = "toefl_word_list.txt"
    main(filepath)
