import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/emergency_service.dart';
import 'services/wellness_service.dart';
import 'ai/ai_service.dart';
import 'ai/mock_ai_provider.dart' ;






void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ai = AIService(MockAIProvider());
  final reply = await ai.getReply("I feel very anxious and stressed");
  print("AI REPLY: $reply");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

void testMoodLog() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final wellnessService = WellnessService();

  await wellnessService.addMoodLog(
    userId: user.uid,
    mood: "overwhelmed",
    note: "Too many things at once",
  );

  print("Mood log added");
}


void testEmergencyTrigger() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final emergencyService = EmergencyService();

  final testMessage = "I feel hopeless and want to die";

  if (emergencyService.isEmergencyMessage(testMessage)) {
    await emergencyService.saveEmergencyLog(
      userId: user.uid,
      triggerType: "keyword",
      detectedText: testMessage,
      keywordsFound: ["hopeless", "want to die"],
    );

    print("🚨 Emergency log saved");
  } else {
    print("No emergency detected");
  }
}


void testEmergencyContact() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("User not logged in");
    return;
  }

  final emergencyService = EmergencyService();

  await emergencyService.addEmergencyContact(
    userId: user.uid,
    name: "Test Contact",
    phone: "9999999999",
    relation: "Friend",
  );

  print("Emergency contact added");
}

void startListening(String chatId) {
  final chatService = ChatService();

  chatService.listenToMessages(chatId).listen((snapshot) {
    for (var doc in snapshot.docs) {
      print("New Message: ${doc['text']} | Sender: ${doc['sender']}");
    }
  });
}

void testChat() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("User not logged in");
    return;
  }

  final chatService = ChatService();
  final chatId = await chatService.getOrCreateChat(user.uid);


  //startListening(chatId);


  await chatService.sendMessage(
    chatId: chatId,
    sender: "user",
    text: "Realtime test message",
  );
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthTestScreen(),
    );
  }
}

class AuthTestScreen extends StatelessWidget {
  const AuthTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Auth Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await AuthService().registerWithEmail(
                email: "verify@mindease.com",
                password: "password12",
                name: "Lucky Sharma",
                age: 21,
                gender: "male",
                sexuality: "straight",
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("REGISTER + PROFILE CREATED")),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("ERROR: $e")),
              );
            }
          },
          child: const Text("Test Register + Profile"),
        ),

      ),
    );
  }
}
