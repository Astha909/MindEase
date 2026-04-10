import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MoodClassifier {
  late Interpreter _interpreter;
  Map<String, int> wordIndex = {};
  List<String> labels = [];

  final int maxLen = 50;

  bool isLoaded = false;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/model/mindease_classifier_v1.tflite',
    );

    String tokenizerJson =
    await rootBundle.loadString('assets/model/tokenizer_config.json');
    Map<String, dynamic> tokenizerData = json.decode(tokenizerJson);
    wordIndex = Map<String, int>.from(tokenizerData["word_index"]);

    String labelsJson =
    await rootBundle.loadString('assets/model/labels.json');
    labels = List<String>.from(json.decode(labelsJson));

    isLoaded = true;
  }

  List<int> _textToSequence(String text) {
    List<String> words = text.toLowerCase().split(" ");
    return words.map((word) => wordIndex[word] ?? 1).toList(); // 1 = OOV
  }

  List<int> _padSequence(List<int> sequence) {
    if (sequence.length > maxLen) {
      return sequence.sublist(0, maxLen);
    }
    return sequence + List.filled(maxLen - sequence.length, 0);
  }

  String predict(String text) {
    if (!isLoaded) {
      return "neutral";
    }
    var seq = _textToSequence(text);
    var padded = _padSequence(seq);

    var input = [padded.map((e) => e.toDouble()).toList()];
    var output = List.generate(1, (index) => List.filled(labels.length, 0.0));

    _interpreter.run(input, output);

    int maxIndex = 0;
    double maxValue = output[0][0];

    for (int i = 1; i < output[0].length; i++) {
      if (output[0][i] > maxValue) {
        maxValue = output[0][i];
        maxIndex = i;
      }
    }

    return labels[maxIndex];
  }
}