import 'ai_provider.dart';

class AIService {
  final AIProvider provider;

  AIService(this.provider);

  Future<Map<String, dynamic>> getReply({
    required String message,
    required String detectedMood,
    required List<dynamic> tips,
    required String activity,
  }) {
    return provider.getReply(
      message: message,
      detectedMood: detectedMood,
      tips: tips,
      activity: activity,
    );
  }
}
