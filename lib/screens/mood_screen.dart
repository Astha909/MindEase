import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/wellness_controller.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final WellnessController _controller = WellnessController();
  final TextEditingController _noteController = TextEditingController();

  double _moodValue = 2;

  final List<String> moodLabels = [
    "Very Sad",
    "Sad",
    "Neutral",
    "Happy",
    "Very Happy"
  ];

  final List<String> moodEmojis = [
    "😭",
    "😔",
    "😐",
    "😊",
    "🤩",
  ];

  final List<List<Color>> gradients = [
    [Color(0xFFE3F2FD), Color(0xFFF8BBD0)],
    [Color(0xFFEDE7F6), Color(0xFFF8BBD0)],
    [Color(0xFFE1F5FE), Color(0xFFEDE7F6)],
    [Color(0xFFFCE4EC), Color(0xFFD1C4E9)],
    [Color(0xFFFFF1F8), Color(0xFFB3E5FC)],
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final currentGradient = gradients[_moodValue.round()];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: currentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              const Text(
                "Mood Meter",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              /// PREMIUM CARD
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    /// Emoji
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Text(
                        moodEmojis[_moodValue.round()],
                        key: ValueKey(_moodValue.round()),
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      moodLabels[_moodValue.round()],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// Circular Mood Meter
                    SizedBox(
                      height: 180,
                      width: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          /// Background circle
                          CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 12,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.grey.shade300,
                            ),
                          ),

                          /// Progress circle
                          CircularProgressIndicator(
                            value: (_moodValue + 1) / 5,
                            strokeWidth: 12,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF9C27B0),
                            ),
                          ),

                          /// Center value
                          Text(
                            "${((_moodValue + 1) * 20).toInt()}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF9C27B0),
                        inactiveTrackColor: Colors.purple.shade100,
                        thumbColor: const Color(0xFF9C27B0),
                        overlayColor: Colors.purple.withOpacity(0.2),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _moodValue,
                        min: 0,
                        max: 4,
                        divisions: 4,
                        onChanged: (value) {
                          setState(() {
                            _moodValue = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// Note
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Add a note...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    await _controller.addMood(
                      userId: userId,
                      mood: moodLabels[_moodValue.round()],
                      note: _noteController.text,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Mood Saved 💜"),
                      ),
                    );

                    _noteController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Save Mood",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
