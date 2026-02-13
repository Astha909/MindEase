import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/wellness_controller.dart';
import '../services/wellness_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final WellnessController _controller = WellnessController();
  final WellnessService _service = WellnessService();
  final TextEditingController _noteController = TextEditingController();

  String? selectedMood;

  final List<Map<String, String>> moods = [
    {"emoji": "😄", "label": "happy"},
    {"emoji": "😊", "label": "calm"},
    {"emoji": "😔", "label": "sad"},
    {"emoji": "😡", "label": "angry"},
    {"emoji": "😰", "label": "anxious"},
  ];

  final List<String> quotes = [
    "You survived 100% of your worst days 💜",
    "Small steps still count 💗",
    "Progress, not perfection 💙",
  ];

  final List<String> stressBusters = [
    "Listen to your favorite song 🎵",
    "Stretch for 5 minutes 🧘",
    "Watch something funny 😂",
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD6E4FF),
                    Color(0xFFE5D4FF),
                    Color(0xFFFFD6E8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "How are you feeling today?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// MOOD SELECTOR
                  Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: moods.map((mood) {
                      final isSelected = selectedMood == mood["label"];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMood = mood["label"];
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                mood["emoji"]!,
                                style: const TextStyle(fontSize: 30),
                              ),
                              const SizedBox(height: 5),
                              Text(mood["label"]!),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  /// NOTE FIELD
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Add a note (optional)...",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// SAVE BUTTON
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _controller.isLoading
                              ? null
                              : () async {
                                  if (selectedMood == null) return;

                                  await _controller.addMood(
                                    userId: userId,
                                    mood: selectedMood!,
                                    note: _noteController.text,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Mood Saved 💜")),
                                  );

                                  _noteController.clear();
                                  setState(() {
                                    selectedMood = null;
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _controller.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Save Mood"),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    "Motivational Quotes ✨",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  ...quotes.map(infoCard),

                  const SizedBox(height: 30),

                  const Text(
                    "Fun Stress Busters 🎉",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  ...stressBusters.map(infoCard),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget infoCard(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(text),
    );
  }
}
