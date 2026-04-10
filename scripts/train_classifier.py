import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
import os
import joblib

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, "data", "processed", "mindease_balanced.csv")
MODEL_DIR = os.path.join(BASE_DIR, "model")

os.makedirs(MODEL_DIR, exist_ok=True)

# Load data
df = pd.read_csv(DATA_FILE)

X = df["text"]
y = df["mood"]

# Split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# Vectorize
vectorizer = TfidfVectorizer(max_features=10000)
X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

# Train
model = LogisticRegression(
    max_iter=200
)
model.fit(X_train_vec, y_train)

# Evaluate
y_pred = model.predict(X_test_vec)

print("\nClassification Report:\n")
print(classification_report(y_test, y_pred))

# Save
joblib.dump(model, os.path.join(MODEL_DIR, "mood_model.pkl"))
joblib.dump(vectorizer, os.path.join(MODEL_DIR, "vectorizer.pkl"))

print("\nModel saved successfully")