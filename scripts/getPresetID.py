import re
import sqlite3
import csv
import uuid


def process_word_list(filepath):
    """
    Processes a text file containing a word list, extracting single-word entries and converting them to lowercase.

    Args:
        filepath (str): The path to the text file.

    Returns:
        list: A list of lowercase single words extracted from the file.
    """
    words = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            # Split the line by '#' and then by ';', taking the first part
            parts = line.split("#")[0].split(";")
            if parts:
                word = parts[0].strip()  # Remove leading/trailing whitespace

                # Check if the word contains spaces
                if " " not in word:
                    words.append(word.lower())
    return words


def create_word_to_id_mapping(db_path, word_list):
    """
    Creates a mapping of words to their corresponding IDs in the database.

    Args:
        db_path (str): The path to the SQLite database.
        word_list (list): A list of words to map to IDs.

    Returns:
        dict: A dictionary mapping words to their IDs.
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    word_to_id = {}
    for word in word_list:
        cursor.execute("SELECT id FROM words WHERE word = ?", (word,))
        result = cursor.fetchone()
        if result:
            word_to_id[word] = result[0]
    conn.close()
    return word_to_id


def output_csv(word_to_id, output_filepath, uuid_str):
    """
    Outputs a CSV file containing the specified UUID and the word IDs.

    Args:
        word_to_id (dict): A dictionary mapping words to their IDs.
        output_filepath (str): The path to the output CSV file.
        uuid_str (str): The UUID string to be included in the CSV.
    """
    with open(output_filepath, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["uuid", "word_id"])  # Header row
        for word, word_id in word_to_id.items():
            writer.writerow([uuid_str, word_id])


if __name__ == "__main__":
    # Configuration
    txt_filepath = "toefl_word_list.txt"  # Replace with your actual file path
    db_filepath = "vocabulary.db"  # Replace with your database file path
    csv_output_filepath = "word_ids.csv"
    static_uuid = "0ea81186-374c-4a4d-8d47-51ced2403a29"

    # Process the word list
    words = process_word_list(txt_filepath)

    # Create the word-to-ID mapping
    word_to_id = create_word_to_id_mapping(db_filepath, words)

    # Output the CSV file
    output_csv(word_to_id, csv_output_filepath, static_uuid)

    print(f"CSV file '{csv_output_filepath}' created successfully.")
