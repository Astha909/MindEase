// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';

class LocalMoodClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _tokenizer = {};
  int maxLen = 40;

  bool get isLoaded => _interpreter != null;

  static const List<MapEntry<String, String>> keywordRules = [
    MapEntry('burnt out', 'overwhelmed'),
    MapEntry('too much', 'overwhelmed'),
    MapEntry('burnout', 'overwhelmed'),
    MapEntry('overwhelmed', 'overwhelmed'),

    MapEntry('stressed', 'stressed'),
    MapEntry('stress', 'stressed'),
    MapEntry('pressure', 'stressed'),
    MapEntry('burden', 'stressed'),

    MapEntry('anxious', 'anxious'),
    MapEntry('worried', 'anxious'),
    MapEntry('nervous', 'anxious'),
    MapEntry('tension', 'anxious'),
    MapEntry('fear', 'anxious'),

    MapEntry('angry', 'angry'),
    MapEntry('gussa', 'angry'),
    MapEntry('frustrated', 'angry'),
    MapEntry('mad', 'angry'),

    MapEntry('lonely', 'lonely'),
    MapEntry('alone', 'lonely'),
    MapEntry('akela', 'lonely'),

    MapEntry('confused', 'confused'),
    MapEntry('lost', 'confused'),
    MapEntry('unsure', 'confused'),

    MapEntry('tired', 'tired'),
    MapEntry('exhausted', 'tired'),
    MapEntry('thaka', 'tired'),

    MapEntry('sad', 'sad'),
    MapEntry('down', 'sad'),
    MapEntry('crying', 'sad'),
    MapEntry('cry', 'sad'),
    MapEntry('dukhi', 'sad'),

    MapEntry('excited', 'happy'),
    MapEntry('happy', 'happy'),
    MapEntry('great', 'happy'),
    MapEntry('good', 'happy'),
    MapEntry('fine', 'happy'),
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/ml/mood_classifier.tflite',
      );

      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData.split('\n').where((e) => e.isNotEmpty).toList();

      final tokenizerData = await rootBundle.loadString('assets/ml/tokenizer.json');
      _tokenizer = jsonDecode(tokenizerData) as Map<String, dynamic>;

      print("✅ TFLite model loaded");
      debugModelInfo();
    } catch (e) {
      print("❌ Model load failed: $e");
    }
  }

  List<int> _textToSequence(String text) {
    final config = _tokenizer['config'] as Map<String, dynamic>;
    final wordIndexRaw = config['word_index'];

    final Map<String, dynamic> wordIndex;
    if (wordIndexRaw is String) {
      wordIndex = jsonDecode(wordIndexRaw) as Map<String, dynamic>;
    } else {
      wordIndex = Map<String, dynamic>.from(wordIndexRaw as Map);
    }

    final words = text.toLowerCase().trim().split(RegExp(r'\s+'));
    final List<int> sequence = [];

    for (final word in words) {
      final value = wordIndex[word];
      if (value != null) {
        sequence.add(int.parse(value.toString()));
      } else {
        sequence.add(1); // OOV token
      }
    }

    return sequence;
  }

  List<int> _padSequence(List<int> seq) {
    if (seq.length >= maxLen) {
      return seq.sublist(0, maxLen);
    }
    return [...seq, ...List.filled(maxLen - seq.length, 0)];
  }

  String predict(String text) {
    final inputText = text.toLowerCase().trim();

    if (_interpreter == null || _labels.isEmpty || _tokenizer.isEmpty) {
      return _fallbackPredict(inputText);
    }

    try {
      final sequence = _textToSequence(inputText);
      final padded = _padSequence(sequence);

      final input = [padded];
      final output = [List<double>.filled(_labels.length, 0.0)];

      _interpreter!.run(input, output);

      final scores = output[0];
      int bestIndex = 0;
      double bestScore = scores[0];

      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > bestScore) {
          bestScore = scores[i];
          bestIndex = i;
        }
      }

      print("🧠 TFLite mood: ${_labels[bestIndex]} ($bestScore)");
      return _labels[bestIndex];
    } catch (e) {
      print("❌ Prediction failed: $e");
      return _fallbackPredict(inputText);
    }
  }

  String _fallbackPredict(String input) {
    for (final rule in keywordRules) {
      final pattern = RegExp(r'\b' + RegExp.escape(rule.key) + r'\b');
      if (pattern.hasMatch(input)) {
        return rule.value;
      }
    }
    return 'neutral';
  }

  void debugModelInfo() {
    if (_interpreter == null) {
      print("❌ Interpreter not loaded");
      return;
    }

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    print("📥 Input shape: ${inputTensor.shape}");
    print("📥 Input type: ${inputTensor.type}");
    print("📤 Output shape: ${outputTensor.shape}");
    print("📤 Output type: ${outputTensor.type}");
  }
}