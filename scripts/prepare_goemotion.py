import csv
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data", "full_dataset")
OUTPUT_DIR = os.path.join(BASE_DIR, "data", "processed")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "mindease_mood_dataset.csv")

TARGET_MOODS = [
    "happy",
    "neutral",
    "sad",
    "anxious",
    "angry",
    "stressed",
    "lonely",
    "confused",
    "tired",
    "overwhelmed",
]

EMOTION_TO_MOOD = {
    "joy": "happy",
    "amusement": "happy",
    "love": "happy",
    "optimism": "happy",
    "gratitude": "happy",
    "approval": "happy",
    "admiration": "happy",
    "caring": "happy",
    "excitement": "happy",
    "pride": "happy",
    "relief": "happy",

    "neutral": "neutral",

    "sadness": "sad",
    "grief": "sad",
    "remorse": "sad",
    "disappointment": "sad",

    "fear": "anxious",
    "nervousness": "anxious",

    "anger": "angry",
    "annoyance": "angry",
    "disapproval": "angry",
    "disgust": "angry",

    "embarrassment": "stressed",

    "confusion": "confused",
    "realization": "confused",

    "desire": "overwhelmed",
    "curiosity": "confused",
    "surprise": "confused",
}

PRIORITY_ORDER = [
    "anger",
    "fear",
    "nervousness",
    "sadness",
    "grief",
    "remorse",
    "disappointment",
    "embarrassment",
    "confusion",
    "realization",
    "neutral",
    "joy",
    "amusement",
    "love",
    "optimism",
    "gratitude",
    "approval",
    "admiration",
    "caring",
    "excitement",
    "pride",
    "relief",
    "annoyance",
    "disapproval",
    "disgust",
    "desire",
    "curiosity",
    "surprise",
]


def get_csv_files():
    return [
        os.path.join(DATA_DIR, "goemotions_1.csv"),
        os.path.join(DATA_DIR, "goemotions_2.csv"),
        os.path.join(DATA_DIR, "goemotions_3.csv"),
    ]


def detect_active_emotions(row):
    active = []
    for emotion in EMOTION_TO_MOOD.keys():
        value = row.get(emotion, "0").strip()
        if value == "1":
            active.append(emotion)
    return active


def choose_primary_emotion(active_emotions):
    for emotion in PRIORITY_ORDER:
        if emotion in active_emotions:
            return emotion
    return None


def normalize_text(text):
    return " ".join(text.strip().lower().split())


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    total_rows = 0
    kept_rows = 0

    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as out_file:
        writer = csv.DictWriter(out_file, fieldnames=["text", "mood"])
        writer.writeheader()

        for file_path in get_csv_files():
            if not os.path.exists(file_path):
                print(f"Missing file: {file_path}")
                continue

            print(f"Reading: {file_path}")

            with open(file_path, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)

                for row in reader:
                    total_rows += 1

                    text = normalize_text(row.get("text", ""))
                    if not text:
                        continue

                    active_emotions = detect_active_emotions(row)
                    if not active_emotions:
                        continue

                    primary_emotion = choose_primary_emotion(active_emotions)
                    if not primary_emotion:
                        continue

                    mapped_mood = EMOTION_TO_MOOD.get(primary_emotion)
                    if not mapped_mood:
                        continue

                    writer.writerow({
                        "text": text,
                        "mood": mapped_mood,
                    })
                    kept_rows += 1

    print(f"Done. Total rows read: {total_rows}")
    print(f"Done. Rows kept: {kept_rows}")
    print(f"Saved file: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()