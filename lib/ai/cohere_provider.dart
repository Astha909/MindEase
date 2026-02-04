import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai_provider.dart';
import '../config/api_keys.dart';

class CohereProvider implements AIProvider {
  static const String _endpoint = "https://api.cohere.ai/v1/chat";

  @override
  Future<String> getReply(String message) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        "Authorization": "Bearer $cohereApiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "command-r",
        "message": message,
        "preamble":
        "You are a supportive mental health companion. "
            "Be empathetic, calm, and non-judgmental. "
            "Do not diagnose or label conditions. "
            "If the user expresses self-harm or suicide intent, "
            "encourage them to contact emergency services or a trusted person.",
        "temperature": 0.6,
      }),

    );

    print("STATUS CODE: ${response.statusCode}");
    print("RAW BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ✅ CORRECT RESPONSE PARSING (2025)
      final content = data["message"]?["content"];
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first["type"] == "text") {
          return first["text"];
        }
      }
    }

    return "I’m here with you, but I’m having trouble responding right now.";
  }
}
