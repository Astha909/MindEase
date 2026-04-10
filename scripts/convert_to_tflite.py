import os
import tensorflow as tf

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR = os.path.join(BASE_DIR, "model", "tflite_classifier")
SAVED_MODEL_DIR = os.path.join(MODEL_DIR, "saved_model")
TFLITE_PATH = os.path.join(MODEL_DIR, "mood_classifier.tflite")

if not os.path.exists(SAVED_MODEL_DIR):
    raise FileNotFoundError(f"SavedModel not found at: {SAVED_MODEL_DIR}")

converter = tf.lite.TFLiteConverter.from_saved_model(SAVED_MODEL_DIR)

converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS
]

converter.optimizations = [tf.lite.Optimize.DEFAULT]

tflite_model = converter.convert()

with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)

print(f"TFLite model saved to: {TFLITE_PATH}")