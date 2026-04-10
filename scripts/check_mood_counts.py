import csv
import os
from collections import Counter

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, "data", "processed", "mindease_balanced.csv")

counter = Counter()

with open(DATA_FILE, "r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        mood = row.get("mood", "").strip()
        if mood:
            counter[mood] += 1

print("Mood counts:\n")
for mood, count in sorted(counter.items()):
    print(f"{mood}: {count}")