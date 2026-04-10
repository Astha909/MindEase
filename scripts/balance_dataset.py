import csv
import os
from collections import defaultdict

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_FILE = os.path.join(BASE_DIR, "data", "processed", "mindease_mood_dataset.csv")
OUTPUT_FILE = os.path.join(BASE_DIR, "data", "processed", "mindease_balanced.csv")

MAX_PER_CLASS = 20000

buckets = defaultdict(list)

# Read data
with open(INPUT_FILE, "r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        mood = row["mood"]
        buckets[mood].append(row)

# Balance
balanced_data = []

for mood, rows in buckets.items():
    if len(rows) > MAX_PER_CLASS:
        balanced_data.extend(rows[:MAX_PER_CLASS])
    else:
        balanced_data.extend(rows)

# Save
with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["text", "mood"])
    writer.writeheader()
    writer.writerows(balanced_data)

print("Balanced dataset created")