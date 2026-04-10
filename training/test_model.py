import tensorflow as tf
import numpy as np
import pickle

# load model
model = tf.lite.Interpreter(model_path="model/mindease_classifier_v1.tflite")
model.allocate_tensors()

input_details = model.get_input_details()
output_details = model.get_output_details()

# load tokenizer & label encoder
with open("model/tokenizer.pkl", "rb") as f:
    tokenizer = pickle.load(f)

with open("model/label_encoder.pkl", "rb") as f:
    label_encoder = pickle.load(f)

def predict(text):
    sequence = tokenizer.texts_to_sequences([text])
    padded = tf.keras.preprocessing.sequence.pad_sequences(sequence, maxlen=50)

    model.set_tensor(input_details[0]['index'], padded.astype(np.float32))
    model.invoke()

    output = model.get_tensor(output_details[0]['index'])
    predicted_index = np.argmax(output)

    return label_encoder.inverse_transform([predicted_index])[0]

# test
print(predict("I feel very sad and alone"))
print(predict("I am so happy today!"))
print(predict("I am really angry right now"))