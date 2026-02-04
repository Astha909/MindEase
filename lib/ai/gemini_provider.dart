import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai_provider.dart';
import '../config/api_keys.dart';

class GeminiProvider implements AIProvider {
  static const String _url =
      "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent";

  @override
  Future<String> getReply(String message) async {
    final response = await http.post(
      Uri.parse("$_url?key=$geminiApiKey"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                "You are a supportive mental health companion. "
                    "Be calm, empathetic, and non-judgmental. "
                    "Do not diagnose. Do not label conditions. "
                    "If there is self-harm or suicide intent, advise emergency help.\n\n"
                    "User message: $message"
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["candidates"] != null &&
          data["candidates"].isNotEmpty &&
          data["candidates"][0]["content"]["parts"] != null &&
          data["candidates"][0]["content"]["parts"].isNotEmpty) {
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }
    }

    return "I’m here with you. It seems I’m having trouble responding right now, but I’m listening.";
  }
}
