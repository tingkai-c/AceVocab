import csv
import sqlite3
import re
import json


def parse_csv_to_sqlite(csv_filepath, db_filepath):
    try:
        conn = sqlite3.connect(db_filepath)
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS words (
                word TEXT PRIMARY KEY,
                description TEXT
            )
        """)

        with open(csv_filepath, "r", encoding="utf-8") as file:
            reader = csv.reader(file)
            for row in reader:
                if not row:  # Skip empty rows
                    continue

                try:
                    word = row[0].strip()
                    rest_of_line = ",".join(
                        row[1:]
                    ).strip()  # Rejoin in case of commas in definition

                    # Remove pronunciation
                    rest_of_line = re.sub(r"\/[^\/]+\/\s*", "", rest_of_line)

                    # Parse US Variant
                    us_variant_match = re.search(r"\(US\s(.*?)\)", rest_of_line)
                    us_variant = (
                        us_variant_match.group(1).strip() if us_variant_match else None
                    )
                    if us_variant:
                        rest_of_line = re.sub(
                            r"\(US\s(.*?)\)", "", rest_of_line
                        )  # remove us variant

                    # Find all numbered definitions, add linebreaks, and keep only the text after the number
                    descriptions = []
                    for match in re.finditer(
                        r"\b\d+\s+(.*?)(?=\b\d+\s|\Z)", rest_of_line, re.DOTALL
                    ):
                        # Add line break after each colon
                        cleaned_description = match.group(1).replace(": ", ":\n")
                        descriptions.append(cleaned_description)

                    if us_variant:
                        descriptions.append("US Variant: " + us_variant)

                    description_json = json.dumps(descriptions)

                    cursor.execute(
                        "INSERT OR REPLACE INTO words (word, description) VALUES (?, ?)",
                        (word, description_json),
                    )

                except Exception as e:
                    print(f"Error processing row: {row}, Error: {e}")
                    continue

        conn.commit()
        print("Parsing complete. Data inserted into the database.")

    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_filepath}")
    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
    finally:
        if conn:
            conn.close()


# Example usage (same as before)
csv_file = "dictionary.csv"  # Replace with your CSV file path
db_file = "dictionary.db"  # Replace with your desired DB file path

parse_csv_to_sqlite(csv_file, db_file)


# Verification Code
def verify_data(db_filepath, word_to_check):
    try:
        conn = sqlite3.connect(db_filepath)
        cursor = conn.cursor()

        cursor.execute("SELECT description FROM words WHERE word = ?", (word_to_check,))
        result = cursor.fetchone()

        if result:
            descriptions = json.loads(result[0])
            print(f"Descriptions for '{word_to_check}':")
            for i, desc in enumerate(descriptions):
                print(f"  {i + 1}. {desc}")
        else:
            print(f"Word '{word_to_check}' not found in the database.")

    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
    finally:
        if conn:
            conn.close()


# Example Usage
verify_data(db_file, "light")
verify_data(db_file, "accordingly")
verify_data(db_file, "ligature")
verify_data(db_file, "account")
verify_data(db_file, "empty")  # test non-existing word
