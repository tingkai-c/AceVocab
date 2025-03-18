import time
import requests
from bs4 import BeautifulSoup
import json
import random


def extract_word_data(word, language_pair="english-chinese-traditional", max_retries=3):
    """Extracts word data from Cambridge Dictionary with retries."""
    base_url = "https://dictionary.cambridge.org/dictionary"
    url = f"{base_url}/{language_pair}/{word}"
    print(f"Fetching: {url}")

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36"
    }

    retries = 0
    while retries < max_retries:
        try:
            response = requests.get(url, headers=headers)
            response.raise_for_status()  # Raise an exception for bad status codes
            break  # break out of loop
        except requests.exceptions.RequestException as e:
            retries += 1
            wait_time = (2**retries) + random.uniform(0, 1)  # exponential backoff
            print(f"Error fetching {url}: {e}, retry {retries} in {wait_time} seconds")
            time.sleep(wait_time)
    else:  # no break from loop
        print(f"Failed to fetch {url} after multiple retries")
        return None

    soup = BeautifulSoup(response.content, "html.parser")
    word_data = {
        "word": word,
        "language_pair": language_pair,
        "definitions": [],
        "idioms": [],
    }

    # find each entry
    entries = soup.find_all("div", class_="entry")
    for entry in entries:
        pos_header = entry.find("div", class_="pos-header")
        if pos_header:
            pos = pos_header.find("span", class_="pos").text.strip()
        else:
            pos = "unknown"

        pos_body = entry.find("div", class_="pos-body")
        if pos_body:
            senses = pos_body.find_all("div", class_="dsense")
            for sense in senses:
                definition_data = {
                    "part_of_speech": pos,
                    "definition": "no definition",
                    "examples": [],
                    "translation": "no translation",
                    "phrases": [],
                }
                definition_blocks = sense.find_all("div", class_="def-block")
                for definition_block in definition_blocks:
                    ddef_h = definition_block.find("div", class_="ddef_h")
                    if ddef_h:
                        definition_data["definition"] = ddef_h.find(
                            "div", class_="def"
                        ).text.strip()

                    examples = definition_block.find_all("div", class_="examp dexamp")
                    example_texts = [example.text.strip() for example in examples]
                    definition_data["examples"] = example_texts

                    translation = definition_block.find("span", class_="trans dtrans")
                    if translation:
                        definition_data["translation"] = translation.text.strip()

                # Extract phrases related to this sense
                phrase_blocks = sense.find_all(
                    "div", class_="phrase-block dphrase-block"
                )
                for phrase_block in phrase_blocks:
                    phrase_head = phrase_block.find("div", class_="phrase-head")
                    if phrase_head:
                        phrase_title = phrase_head.find(
                            "span", class_="phrase-title"
                        ).text.strip()
                    else:
                        phrase_title = "no title"

                    phrase_body = phrase_block.find("div", class_="phrase-body")
                    if phrase_body:
                        phrase_def_blocks = phrase_body.find_all(
                            "div", class_="def-block"
                        )
                        for phrase_def_block in phrase_def_blocks:
                            phrase_ddef_h = phrase_def_block.find(
                                "div", class_="ddef_h"
                            )
                            if phrase_ddef_h:
                                phrase_definition_text = phrase_ddef_h.find(
                                    "div", class_="def"
                                ).text.strip()
                            else:
                                phrase_definition_text = "no phrase definition"

                            phrase_examples = phrase_def_block.find_all(
                                "div", class_="examp dexamp"
                            )
                            phrase_example_texts = [
                                example.text.strip() for example in phrase_examples
                            ]
                            definition_data["phrases"].append(
                                {
                                    "phrase": phrase_title,
                                    "definition": phrase_definition_text,
                                    "examples": phrase_example_texts,
                                }
                            )
                word_data["definitions"].append(definition_data)

            idiom_section = entry.find("div", class_="xref idioms")
            if idiom_section:
                idiom_links = idiom_section.find_all("a")
                for link in idiom_links:
                    word_data["idioms"].append(
                        {
                            "idiom": link.text.strip(),
                            "url": "https://dictionary.cambridge.org" + link["href"],
                        }
                    )
    return word_data


if __name__ == "__main__":
    words = ["account"]
    all_word_data = {}
    for word in words:
        data = extract_word_data(word)
        if data:
            all_word_data[word] = data
        time.sleep(1)  # add a 1-second delay between requests

    # Output data
    print(json.dumps(all_word_data, indent=4, ensure_ascii=False))
