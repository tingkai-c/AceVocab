import sqlite3


def describe_database(db_path):
    """
    Connects to a SQLite database and prints its schema.

    Args:
        db_path: The path to the SQLite database file.
    """
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Get the list of tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()

        if not tables:
            print("No tables found in the database.")
            return

        print("Tables in the database:")
        for table_name in tables:
            table_name = table_name[0]  # Extract table name from tuple
            print(f"\nTable: {table_name}")

            # Get table schema (column names, types, etc.)
            cursor.execute(f"PRAGMA table_info({table_name});")
            columns = cursor.fetchall()

            print("  Columns:")
            for column in columns:
                column_name = column[1]
                column_type = column[2]
                not_null = "NOT NULL" if column[3] else ""
                default_value = column[4]
                primary_key = "PRIMARY KEY" if column[5] else ""

                print(
                    f"    - {column_name} ({column_type}) {not_null} {primary_key} Default: {default_value}"
                )

            # Get row count
            cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
            row_count = cursor.fetchone()[0]
            print(f"  Row Count: {row_count}")

            # Get foreign key information
            cursor.execute(f"PRAGMA foreign_key_list({table_name});")
            foreign_keys = cursor.fetchall()
            if foreign_keys:
                print("  Foreign Keys:")
                for fk in foreign_keys:
                    ref_table = fk[2]
                    from_col = fk[3]
                    to_col = fk[4]
                    print(f"    - {from_col} -> {ref_table}.{to_col}")

    except sqlite3.Error as e:
        print(f"An error occurred: {e}")
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    db_file = "vocabulary.db"  # Replace with your database file name
    describe_database(db_file)
