// will not change in future

abstract class AIProvider {
  Future<Map<String, dynamic>> getReply({
    required String message,
    required String detectedMood,
    required List<dynamic> tips,
    required String activity,
  });
}
