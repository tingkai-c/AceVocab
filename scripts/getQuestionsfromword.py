import json
import random
import os
import google.generativeai as genai
import sqlite3
from typing import Tuple, List, Optional
import concurrent.futures


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


def call_gemini_api(prompt):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY environment variable not set.")

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("gemini-2.0-flash-lite")

    try:
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"Error calling Gemini API: {e}")
        return ""  # Return an empty string on error


def generate_fill_in_the_blank_question(
    word, all_words
) -> Tuple[Optional[str], Optional[str], Optional[List[str]]]:
    """
    Generates a fill-in-the-blank question using the Gemini API.

    Args:
        word: The target word for the question.

    Returns:
        A dictionary containing the question, correct answer, and choices.
    """
    prompt = f"Make a “fill in the blank” question with the word “{word}” The sentence should be in undergraduate level. Also generate three wrong choices that might be misused by a student. \n\nMake sure the sentence have adequate context in order to ensure only one answer is applicable.\n\nReturn the sentence and options in the following json format:\n\n{{”question”: “”, correctAnswer: “” ,“wrongChoices”: [””, ””, ””]}}"
    response_text = call_gemini_api(prompt)

    print(f"Raw response: {response_text}")

    # Clean the response text
    cleaned_response = response_text.strip()
    cleaned_response = cleaned_response.replace("```json", "").replace("```", "")

    try:
        response_json = json.loads(cleaned_response)
        question = response_json["question"]
        correct_answer = response_json["correctAnswer"]
        choices = response_json["wrongChoices"]

        # Remove any empty strings that might be present
        choices = [choice for choice in choices if choice]

        # If more than 4 choices, reduce to 4 by:
        # 1. Keep correct answer
        # 2. Randomly select among the rest
        if len(choices) > 3:
            other_choices = [c for c in choices if c != correct_answer]
            random.shuffle(other_choices)
            choices = [correct_answer] + other_choices[:3]

        # If less than 4 choices, fill with random words
        while len(choices) < 3:
            random_word = random.choice(all_words)
            if random_word != correct_answer and random_word not in choices:
                choices.append(random_word)

        random.shuffle(choices)  # Shuffle for randomness

        return question, correct_answer, choices

    except (json.JSONDecodeError, KeyError) as e:
        print(f"Error processing Gemini response: {e}")
        return None, None, None
    except Exception as e:
        print("another error", e)
        return None, None, None

        return None, None, None


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


def add_question_to_db(
    question: str, correct_answer: str, choices: List[str]
) -> Optional[int]:
    """
    Adds a question and its associated data to the database.

    Args:
        question: The question text.
        correct_answer: The correct answer.
        choices: A list of three wrong answer choices.

    Returns:
        question id if successfully added.
    """
    if len(choices) != 3:
        raise ValueError("The choices list must contain exactly three wrong answers.")

    word_id = get_word_id(correct_answer)
    if word_id is None:
        print(f"Error: Word '{correct_answer}' not found in the 'words' table.")
        return None

    try:
        conn = sqlite3.connect("vocabulary.db")
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO questions (word_id, question, correct_answer, wrong_answer1, wrong_answer2, wrong_answer3)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (word_id, question, correct_answer, choices[0], choices[1], choices[2]),
        )
        conn.commit()
        print(f"Question added to database with ID: {cursor.lastrowid}")
        return cursor.lastrowid

    except sqlite3.IntegrityError as e:
        print(f"Database integrity error: {e}")
        print(
            "This usually means a foreign key constraint failed (e.g., word_id does not exist)."
        )
        return None
    except sqlite3.Error as e:
        print(f"Database error: {e}")
        return None
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    filepath = "toefl_word_list.txt"  # Assuming 'words.txt' in the same directory
    all_words = get_clean_words(filepath)
    if not all_words:
        print("No words found. Exiting.")
        exit()

    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        for word in all_words:
            # Use submit to schedule the function for execution and return a Future object
            future = executor.submit(
                generate_fill_in_the_blank_question, word, all_words
            )

            try:
                # Get the result from the Future, which will block until the function is done
                question, correct_answer, choices = future.result()

                if question and correct_answer and choices:
                    # Add the question to the database
                    question_id = add_question_to_db(question, correct_answer, choices)
                    if question_id:
                        print(f"Added question for word '{word}' with ID {question_id}")

            except Exception as e:
                print(f"Error processing word '{word}': {e}")
