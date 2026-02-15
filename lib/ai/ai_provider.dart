//will not change in future
abstract class AIProvider {
  Future<Map<String, dynamic>> getReply(String message);
}
