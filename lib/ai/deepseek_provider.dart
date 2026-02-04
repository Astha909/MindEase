import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai_provider.dart';
import '../config/api_keys.dart';

class DeepSeekProvider implements AIProvider {
  static const String _baseUrl = "https://api.deepseek.com/v1/chat/completions";

  @override
  Future<String> getReply(String message) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $deepSeekApiKey",
      },
      body: jsonEncode({
        "model": "deepseek-chat",
        "messages": [
          {
            "role": "system",
            "content":
            "You are a supportive mental health companion. "
                "Be empathetic, calm, and non-judgmental. "
                "Do not diagnose or label conditions. "
                "If the user expresses self-harm or immediate danger, "
                "encourage them to contact emergency services or a trusted person."
          },
          {
            "role": "user",
            "content": message
          }
        ],
        "temperature": 0.7
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"];
    } else {
      throw Exception(
        "DeepSeek API error: ${response.statusCode} ${response.body}",
      );
    }
  }
}
