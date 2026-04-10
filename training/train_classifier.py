import os
import pandas as pd
import tensorflow as tf
import pickle
import json
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Embedding, GlobalAveragePooling1D, Dense


DATA_PATH = "data/processed/mindease_mood_dataset.csv"
MODEL_DIR = "model"

def map_emotion_to_mood(row):
    if row["joy"] == 1 or row["love"] == 1 or row["gratitude"] == 1:
        return "happy"
    elif row["sadness"] == 1 or row["grief"] == 1:
        return "sad"
    elif row["anger"] == 1 or row["annoyance"] == 1:
        return "angry"
    elif row["fear"] == 1 or row["nervousness"] == 1:
        return "anxious"
    elif row["confusion"] == 1:
        return "confused"
    elif row["disappointment"] == 1:
        return "stressed"
    elif row["neutral"] == 1:
        return "neutral"
    else:
        return None

def load_data():
    print("Loading data...")

    if not os.path.exists(DATA_PATH):
        raise FileNotFoundError(f"Dataset not found at {DATA_PATH}")

    file1 = "data/full_dataset/goemotions_1.csv"
    file2 = "data/full_dataset/goemotions_2.csv"
    file3 = "data/full_dataset/goemotions_3.csv"

    data1 = pd.read_csv(file1)
    data2 = pd.read_csv(file2)
    data3 = pd.read_csv(file3)

    data = pd.concat([data1, data2, data3], ignore_index=True)
    print(data.columns.tolist())
    print(data.head(1))

    # apply mapping AFTER loading
    data["mood"] = data.apply(map_emotion_to_mood, axis=1)
    data = data[data["mood"].notnull()]

    print(f"Loaded {len(data)} samples")
    print(data.head())

    # ✅ ADD HERE
    output_path = "data/processed/mindease_mood_dataset.csv"
    os.makedirs("data/processed", exist_ok=True)

    data[["text", "mood"]].to_csv(output_path, index=False)

    print(f"Processed dataset saved at: {output_path}")

    return data

def preprocess_data(data):
    print("Preprocessing data...")

    texts = data["text"].astype(str).values
    labels = data["mood"].values

    # Encode labels (happy → 0, sad → 1, etc.)
    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(labels)

    # Tokenize text
    tokenizer = Tokenizer(num_words=5000, oov_token="<OOV>")
    tokenizer.fit_on_texts(texts)

    sequences = tokenizer.texts_to_sequences(texts)
    X = pad_sequences(sequences, maxlen=50, padding='post')

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    print(f"Train size: {len(X_train)}, Test size: {len(X_test)}")

    return X_train, X_test, y_train, y_test, tokenizer, label_encoder


def build_model():
    print("Building model...")

    model = Sequential([
        Embedding(input_dim=5000, output_dim=16, input_length=50),
        GlobalAveragePooling1D(),
        Dense(24, activation="relu"),
        Dense(7, activation="softmax")
    ])

    model.compile(
        loss="sparse_categorical_crossentropy",
        optimizer="adam",
        metrics=["accuracy"]
    )

    return model

def train_model(model, X_train, y_train):
    print("Training model...")

    history = model.fit(
        X_train,
        y_train,
        epochs=10,
        batch_size=32,
        validation_split=0.1,
        verbose=1
    )

    return history

def evaluate_model(model, X_test, y_test):
    print("Evaluating model...")

    loss, accuracy = model.evaluate(X_test, y_test, verbose=1)

    print(f"Test Loss: {loss:.4f}")
    print(f"Test Accuracy: {accuracy:.4f}")

def convert_to_tflite(model):
    print("Saving TensorFlow model...")

    os.makedirs(MODEL_DIR, exist_ok=True)

    saved_model_path = os.path.join(MODEL_DIR, "mindease_classifier.keras")
    tflite_model_path = os.path.join(MODEL_DIR, "mindease_classifier_v1.tflite")

    model.save(saved_model_path)
    print(f"Model saved at: {saved_model_path}")

    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    with open(tflite_model_path, "wb") as f:
        f.write(tflite_model)

    print(f"TFLite model saved at: {tflite_model_path}")


def save_artifacts(tokenizer, label_encoder):
    print("Saving tokenizer and label encoder...")

    os.makedirs(MODEL_DIR, exist_ok=True)

    tokenizer_path = os.path.join(MODEL_DIR, "tokenizer_config.json")
    labels_path = os.path.join(MODEL_DIR, "labels.json")

    tokenizer_data = {
        "word_index": tokenizer.word_index,
        "num_words": 5000,
        "max_len": 50,
        "oov_token": "<OOV>"
    }

    labels_data = label_encoder.classes_.tolist()

    with open(tokenizer_path, "w", encoding="utf-8") as f:
        json.dump(tokenizer_data, f, ensure_ascii=False)

    with open(labels_path, "w", encoding="utf-8") as f:
        json.dump(labels_data, f, ensure_ascii=False)

    print(f"Tokenizer config saved at: {tokenizer_path}")
    print(f"Labels saved at: {labels_path}")



def main():
    data = load_data()
    X_train, X_test, y_train, y_test, tokenizer, label_encoder = preprocess_data(data)
    model = build_model()
    history = train_model(model, X_train, y_train)
    evaluate_model(model, X_test, y_test)
    save_artifacts(tokenizer, label_encoder)
    convert_to_tflite(model)

if __name__ == "__main__":
    main()