from stardict import DictCsv, StarDict

# Read the CSV data
csv_dict = DictCsv("path/to/your/ecdict.csv")

# Create or open an SQLite database
sqlite_db = StarDict("path/to/your/dict.db")

# Iterate through the CSV data and insert into SQLite
for row in csv_dict.query_batch():
    sqlite_db.register(row)
sqlite_db.commit()
