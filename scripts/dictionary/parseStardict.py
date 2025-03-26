import gzip
import struct
import sqlite3
import sys
import os


def parse_stardict_dict_dz(dict_dz_path, db_path, ifo_path=None):
    """
    Parses a StarDict .dict.dz file and stores the word-definition pairs
    in an SQLite database. Correctly handles sametypesequence.

    Args:
        dict_dz_path: Path to the .dict.dz file.
        db_path: Path to the output SQLite database file.
        ifo_path: Optional path to the .ifo file. If provided,
                  sametypesequence is read from it. If not provided,
                  it is assumed sametypesequence is NOT used.
    """

    if os.path.exists(db_path):
        raise FileExistsError(f"Database file '{db_path}' already exists.")

    # Determine sametypesequence from .ifo file (if provided)
    sametypesequence = ""
    if ifo_path:
        try:
            with open(ifo_path, "r", encoding="utf-8") as ifo_file:
                for line in ifo_file:
                    if line.startswith("sametypesequence="):
                        sametypesequence = line.strip().split("=")[1]
                        break
        except FileNotFoundError:
            print(
                f"Warning: .ifo file not found at '{ifo_path}'. Assuming sametypesequence is NOT used."
            )
        except Exception as e:
            print(
                f"Error reading .ifo file: {e}. Assuming sametypesequence is NOT used."
            )

    print(f"DEBUG: sametypesequence = '{sametypesequence}'")

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS dictionary (
                word TEXT PRIMARY KEY,
                definition TEXT
            )
        """)
        conn.commit()

        with gzip.open(dict_dz_path, "rb") as f:
            # Load the corresponding .idx file to get word offsets and sizes.
            idx_path = dict_dz_path[:-7] + "idx"  # Replace .dict.dz with .idx
            if not os.path.exists(idx_path):
                idx_path += ".gz"  # Try .idx.gz if .idx doesn't exist
                if not os.path.exists(idx_path):
                    raise FileNotFoundError(
                        f"Could not find .idx or .idx.gz file for {dict_dz_path}"
                    )

            word_data = load_idx(idx_path)  # Load the index data

            entry_count = 0
            for word, (offset, size) in word_data.items():
                # Seek to the correct offset in the decompressed data
                f.seek(offset)
                entry_data = f.read(size)
                print(
                    f"DEBUG: Processing word: '{word}', offset: {offset}, size: {size}"
                )

                try:
                    if sametypesequence:
                        definition = parse_with_sametypesequence(
                            entry_data, sametypesequence
                        )
                    else:
                        definition = parse_without_sametypesequence(entry_data)

                    cursor.execute(
                        "INSERT INTO dictionary (word, definition) VALUES (?, ?)",
                        (word, definition),
                    )
                    entry_count += 1
                    print(f"DEBUG: Successfully inserted '{word}'")

                except sqlite3.IntegrityError:
                    print(f"Warning: Duplicate word '{word}' found. Skipping.")
                except ValueError as e:
                    print(f"Error parsing entry for '{word}': {e}")
                except sqlite3.Error as e:
                    print(f"SQLite error during insert: {e}")
                    conn.rollback()
                    raise

            conn.commit()
            print(f"Successfully parsed '{dict_dz_path}' and created '{db_path}'")
            print(f"Total entries processed: {entry_count}")

    except FileNotFoundError:
        print(
            f"Error: File '{dict_dz_path}' or its index file not found.",
            file=sys.stderr,
        )
        sys.exit(1)
    except gzip.BadGzipFile:
        print(f"Error: '{dict_dz_path}' is not a valid gzip file.", file=sys.stderr)
        sys.exit(1)
    except sqlite3.Error as e:
        print(f"SQLite error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if "conn" in locals():
            conn.close()


def load_idx(idx_path):
    """Loads the .idx or .idx.gz file and returns a dictionary
    mapping words to (offset, size) tuples."""
    word_data = {}

    if idx_path.endswith(".gz"):
        open_func = gzip.open
        mode = "rb"
    else:
        open_func = open
        mode = "rb"

    try:
        with open_func(idx_path, mode) as f:
            buffer = b""
            while True:
                chunk = f.read(4096)
                if not chunk:
                    break
                buffer += chunk

                while True:
                    word_end = buffer.find(b"\0")
                    if word_end == -1:
                        break
                    word = buffer[:word_end].decode("utf-8", errors="replace")

                    if len(buffer) < word_end + 1 + 8:  # word + null + offset + size
                        break

                    offset = struct.unpack(">I", buffer[word_end + 1 : word_end + 5])[0]
                    size = struct.unpack(">I", buffer[word_end + 5 : word_end + 9])[0]

                    word_data[word] = (offset, size)
                    buffer = buffer[word_end + 9 :]

    except Exception as e:
        raise ValueError(f"Error reading or parsing .idx file: {e}")

    return word_data


def parse_with_sametypesequence(data, sequence):
    """Parses a data entry assuming sametypesequence is used."""
    result = ""
    offset = 0
    for type_char in sequence:
        if type_char.islower():  # Null-terminated
            end = data.find(b"\0", offset)
            if end == -1:
                raise ValueError(f"Missing null terminator for type '{type_char}'")
            decoded = data[offset:end].decode("utf-8", errors="replace")
            offset = end + 1
        else:  # Size-prefixed
            if len(data) < offset + 4:
                raise ValueError(f"Missing size information for type '{type_char}'")
            size = struct.unpack(">I", data[offset : offset + 4])[0]
            offset += 4
            if len(data) < offset + size:
                raise ValueError(f"Data truncated for type '{type_char}'")
            decoded = data[offset : offset + size].decode("utf-8", errors="replace")
            offset += size

        result += decoded + "\n"  # Add newline separator for clarity

    return result.strip()


def parse_without_sametypesequence(data):
    """Parses a data entry assuming sametypesequence is NOT used."""
    result = ""
    offset = 0
    while offset < len(data):
        type_char = chr(data[offset])  # Correctly get the type character
        offset += 1

        print(f"  DEBUG: Parsing type: '{type_char}'")  # Debug: Show the type char

        if type_char.islower():  # Null-terminated
            end = data.find(b"\0", offset)
            if end == -1:
                raise ValueError(f"Missing null terminator for type '{type_char}'")
            try:
                decoded = data[offset:end].decode("utf-8", errors="replace")
            except UnicodeDecodeError:
                decoded = f"(Decoding Error: Invalid UTF-8 at offset {offset})"  # Handles decoding error gracefully
            offset = end + 1
            print(f"    DEBUG: Decoded (null-terminated): '{decoded}'")  # Debug

        elif type_char.isupper():  # Correct to check for uppercase
            # Size-prefixed
            if len(data) < offset + 4:
                raise ValueError(f"Missing size information for type '{type_char}'")
            size = struct.unpack(">I", data[offset : offset + 4])[0]
            offset += 4
            if len(data) < offset + size:
                raise ValueError(f"Data truncated for type '{type_char}'")

            try:
                decoded = data[offset : offset + size].decode("utf-8", errors="replace")
            except UnicodeDecodeError:
                decoded = f"(Decoding Error: Invalid UTF-8 at offset {offset})"  # Handles decoding error gracefully
            offset += size
            print(
                f"    DEBUG: Decoded (size-prefixed, size={size}): '{decoded}'"
            )  # Debug

        else:
            raise ValueError(
                f"Invalid type character: '{type_char}'"
            )  # Invalid type char

        result += f"[{type_char}] {decoded}\n"  # Include type char for clarity

    return result.strip()


if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print(
            "Usage: python script.py <path_to_dict.dz> <path_to_output.db> [path_to_ifo]"
        )
        sys.exit(1)

    dict_dz_file = sys.argv[1]
    sqlite_db_file = sys.argv[2]
    ifo_file = sys.argv[3] if len(sys.argv) == 4 else None
    parse_stardict_dict_dz(dict_dz_file, sqlite_db_file, ifo_file)

