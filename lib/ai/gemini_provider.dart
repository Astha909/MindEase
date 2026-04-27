import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai_provider.dart';
import '../config/api_keys.dart';

class GeminiProvider implements AIProvider {

  static const String _endpoint =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent";

  @override
  Future<Map<String,dynamic>> getReply(String message) async {

    final response = await http.post(
      Uri.parse("$_endpoint?key=$geminiApiKey"),
      headers: {
        "Content-Type":"application/json",
      },
      body: jsonEncode({
        "contents":[
          {
            "parts":[
              {
                "text": """
You are a supportive wellness assistant.

Return ONLY valid JSON:
{
 "mood":"",
 "chat_reply":"",
 "tips":["",""],
 "activity":"",
 "is_crisis":false,
 "crisis_level":"none"
}

User input:
$message
"""
              }
            ]
          }
        ]
      }),
    );

    if(response.statusCode==200){

      final data=jsonDecode(response.body);

      final rawText =
      data["candidates"][0]["content"]["parts"][0]["text"];

      final jsonStart = rawText.indexOf('{');
      final jsonEnd = rawText.lastIndexOf('}');

      final cleanedText =
      rawText.substring(jsonStart,jsonEnd+1);

      return jsonDecode(cleanedText);
    }

    return {
      "mood":"neutral",
      "chat_reply":"I'm here with you 🤍",
      "tips":[],
      "activity":"",
      "crisis_level":"none"
    };
  }
}