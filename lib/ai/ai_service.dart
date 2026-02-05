
import 'ai_provider.dart';

class AIService {
  final AIProvider provider;

  AIService(this.provider);

  Future<String> getReply(String message) {
    return provider.getReply(message);
  }
}
