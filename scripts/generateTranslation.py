import sqlite3
import google.generativeai as genai
import os
import re  # Import the regular expression module
from dotenv import load_dotenv

# Load environment variables (API Key)
load_dotenv()
GOOGLE_API_KEY = os.getenv("GEMENI_API_KEY")
if not GOOGLE_API_KEY:
    raise ValueError(
        "Google API key not found in .env file.  Create a .env file with GOOGLE_API_KEY=<your key>"
    )

# Configure the Google Generative AI model
genai.configure(api_key=GOOGLE_API_KEY)
model = genai.GenerativeModel("gemini-2.0-pro")


def translate_to_traditional_chinese(sentence):
    """Translates a sentence to Traditional Chinese using Google Gemini Pro.

    Args:
        sentence: The sentence to translate.

    Returns:
        The translated sentence, or None if an error occurs.  Prints any errors.
    """
    try:
        prompt = f"請將這個句子翻譯成繁體中文。不要使用簡體字。你的翻譯要語意通順，精準，並只能回傳該翻譯。以下是你要翻譯的句子：{sentence}"
        response = model.generate_content(prompt)

        if response.text:
            return response.text.strip()  # Remove leading/trailing whitespace
        else:
            print(f"Warning: Empty response from Gemini for sentence: {sentence}")
            return None  # Or perhaps raise an exception

    except Exception as e:
        print(f"Error during translation: {e}")
        return None


def update_database_with_translations(db_path):
    """Adds a 'translation' column to the 'questions' table and populates it.

    Args:
        db_path: Path to the SQLite database file.
    """
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # 1. Add the 'translation' column (if it doesn't exist)
        try:
            cursor.execute("ALTER TABLE questions ADD COLUMN translation TEXT")
            print("Added 'translation' column to 'questions' table.")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e):
                print("The 'translation' column already exists.")
            else:
                raise  # Re-raise other OperationalErrors

        # 2. Iterate through each question
        cursor.execute("SELECT id, question, correct_answer FROM questions")
        questions = cursor.fetchall()

        for question_id, question_text, correct_answer in questions:
            # 3. Construct the full sentence using regular expressions
            full_sentence = re.sub(r"_+", correct_answer, question_text)  # Use regex!

            # 4. Get the translation
            translated_sentence = translate_to_traditional_chinese(full_sentence)

            # 5. Update the database
            if translated_sentence:
                cursor.execute(
                    "UPDATE questions SET translation = ? WHERE id = ?",
                    (translated_sentence, question_id),
                )
                print(f"Updated translation for question ID {question_id}")
            else:
                print(
                    f"Skipped updating question ID {question_id} due to translation error."
                )

        conn.commit()  # Save changes
        print("Database update complete.")

    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
    finally:
        if conn:
            conn.close()


# --- Main Execution ---
if __name__ == "__main__":
    db_file = "vocabulary.db"  # Replace with your actual database file name
    update_database_with_translations(db_file)
