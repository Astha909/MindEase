import joblib
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR = os.path.join(BASE_DIR, "model")

model = joblib.load(os.path.join(MODEL_DIR, "mood_model.pkl"))
vectorizer = joblib.load(os.path.join(MODEL_DIR, "vectorizer.pkl"))

def predict(text):
    vec = vectorizer.transform([text])
    return model.predict(vec)[0]

# test cases
tests = [
    "i feel very sad and alone",
    "i am so happy today",
    "i am stressed about exams",
    "i feel confused and lost",
    "i am very angry right now",
]

for t in tests:
    print(t, "→", predict(t))