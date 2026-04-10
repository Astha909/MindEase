import os
import json
import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences

def clean_text(text):
    text = str(text).lower().strip()
    text = text.replace("gussa", "angry")
    text = text.replace("dukhi", "sad")
    text = text.replace("akela", "lonely")
    text = text.replace("thaka", "tired")
    text = text.replace("tension", "anxious")
    text = text.replace("burnt out", "overwhelmed")
    return text


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, "data", "processed", "mindease_balanced.csv")
MODEL_DIR = os.path.join(BASE_DIR, "model", "tflite_classifier")

os.makedirs(MODEL_DIR, exist_ok=True)

# Load dataset
df = pd.read_csv(DATA_FILE)

# Basic cleanup
df = df.dropna(subset=["text", "mood"]).copy()
df["text"] = df["text"].apply(clean_text)
df["mood"] = df["mood"].astype(str).str.strip()

texts = df["text"].tolist()
labels = df["mood"].replace({
    "lonely": "sad",
    "tired": "sad"
}).tolist()

# Encode labels
label_encoder = LabelEncoder()
y = label_encoder.fit_transform(labels)
num_classes = len(label_encoder.classes_)

# Save label order for Flutter later
label_file = os.path.join(MODEL_DIR, "labels.txt")
with open(label_file, "w", encoding="utf-8") as f:
    for label in label_encoder.classes_:
        f.write(label + "\n")

# Train/test split
X_train, X_test, y_train, y_test = train_test_split(
    texts,
    y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

# Tokenizer-based preprocessing (TFLite-safe)
max_words = 10000
max_len = 40

tokenizer = Tokenizer(num_words=max_words, oov_token="<OOV>")
tokenizer.fit_on_texts(X_train)

X_train_seq = tokenizer.texts_to_sequences(X_train)
X_test_seq = tokenizer.texts_to_sequences(X_test)

X_train_pad = pad_sequences(X_train_seq, maxlen=max_len, padding="post", truncating="post")
X_test_pad = pad_sequences(X_test_seq, maxlen=max_len, padding="post", truncating="post")

y_train_arr = np.array(y_train, dtype=np.int32)
y_test_arr = np.array(y_test, dtype=np.int32)


# Save tokenizer for Flutter later
tokenizer_path = os.path.join(MODEL_DIR, "tokenizer.json")
with open(tokenizer_path, "w", encoding="utf-8") as f:
    f.write(tokenizer.to_json())

# Build model
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(max_len,), dtype=tf.int32),
    tf.keras.layers.Embedding(input_dim=max_words, output_dim=64),
    tf.keras.layers.GlobalAveragePooling1D(),
    tf.keras.layers.Dense(64, activation="relu"),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(num_classes, activation="softmax"),
])

model.compile(
    loss="sparse_categorical_crossentropy",
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0005),
    metrics=["accuracy"]
)

# Train
model.fit(
    X_train_pad,
    y_train_arr,
    validation_split=0.1,
    epochs=10,
    batch_size=32,
    verbose=1
)

# Evaluate
loss, accuracy = model.evaluate(X_test_pad, y_test_arr, verbose=0)
print(f"\nTest Accuracy: {accuracy:.4f}")

# Save SavedModel
saved_model_path = os.path.join(MODEL_DIR, "saved_model")
model.export(saved_model_path)

print(f"\nSavedModel exported to: {saved_model_path}")
print(f"Labels saved to: {label_file}")
print(f"Tokenizer saved to: {tokenizer_path}")