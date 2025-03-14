import json
import random
import os
import google.generativeai as genai


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


def generate_fill_in_the_blank_question(word, all_words):
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


if __name__ == "__main__":
    filepath = "toefl_word_list.txt"
    word_list = get_clean_words(filepath)
    if word_list:
        question, correct_answer, choices = generate_fill_in_the_blank_question(
            "ubiquitous", word_list
        )
        if question:
            print("Question:", question)
            print("Correct Answer:", correct_answer)
            print("Wrong Choices:", choices)
