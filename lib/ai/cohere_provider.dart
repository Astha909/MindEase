// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai_provider.dart';
import '../config/api_keys.dart';

class CohereProvider implements AIProvider {
  static const String _endpoint = "https://api.cohere.ai/v2/chat";



  @override
  Future<Map<String, dynamic>> getReply(String message) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        "Authorization": "Bearer $cohereApiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "command-a-03-2025",
        "messages": [
          {
            "role": "system",
            "content": """
              You are a supportive wellness assistant for a mental well-being app called MindEase.

              IMPORTANT RULES:
              - Do NOT diagnose any mental or medical condition.
              - Do NOT mention disorders, illnesses, or symptoms.
              - Do NOT use clinical or medical language.
              - Do NOT scare the user or use alarming words.
              - Do NOT suggest medication.
              - Do NOT mention that you are an AI model.
              - Keep the tone warm, casual, friendly, and human-like.
              - The chat reply must feel like a caring friend with light humor (when appropriate).
              - The chat reply must be SHORT (max 1–2 short sentences).
              - Do NOT give long explanations or advice in chat reply.
              - The chat reply should include 1 appropriate emoji when it fits naturally (not too many).
              
              TASK:
              1. Infer the user's current mood from the input (text OR provided mood).
              2. Generate a short, friendly, caring chat reply (1–2 short lines, with at most 1 emoji).
              3. Generate 2 simple wellness tips that are easy to follow (no emojis here).
              4. Suggest 1 small, gentle, FUN mini-activity or game the user can do right now (you may include 1 emoji here if it fits).
              
              Return ONLY valid JSON in this exact format:
              {
                "mood": "<one of: calm, happy, neutral, sad, anxious, angry, stressed, overwhelmed>",
                "chat_reply": "<short caring friend-like reply with at most 1 emoji>",
                "tips": [
                  "<wellness tip 1>",
                  "<wellness tip 2>"
                ],
                "activity": "<one small fun mini-game or playful activity>"
                "is_crisis": <true or false>,
                "crisis_level": "<none|mild|moderate|severe>"
              }"""
          },


          {
            "role": "user",
            "content": message
          }
        ],

        "temperature": 0.6
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
          final rawText = first["text"];

          try {
            final aiJson = jsonDecode(rawText);

            final mood = aiJson["mood"]?.toString();
            final tips = aiJson["tips"];
            final activity = aiJson["activity"];
            final chatReply = aiJson["chat_reply"]?.toString();
            final isCrisis = aiJson["is_crisis"] ?? false;
            final crisisLevel = aiJson["crisis_level"]?.toString() ?? "none";


            // 🔐 Save mood using your existing service



            if (chatReply != null && chatReply.isNotEmpty) {
              return {
                "mood": mood,
                "chat_reply": chatReply,
                "tips": tips ?? [],
                "activity": activity,
                "is_crisis": isCrisis,
                "crisis_level": crisisLevel,
              };


            }
          } catch (e) {
            print("JSON PARSE ERROR: $e");
            print("RAW AI TEXT: $rawText");
          }

          // fallback if JSON breaks
          return {
            "mood": "neutral",
            "chat_reply": rawText,
            "tips": [],
            "activity": ""
          };

        }

      }
    }
    return {
      "mood": "neutral",
      "chat_reply": "I’m here with you 🤍",
      "tips": [],
      "activity": ""
    };

  }
}
