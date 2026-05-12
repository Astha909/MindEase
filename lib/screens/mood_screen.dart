import 'package:flutter/material.dart';
import '../controllers/wellness_controller.dart';
import 'dart:math';
import 'dart:async';

class MoodScreen extends StatefulWidget {
  final String userId;
  final WellnessController wellnessController;

  const MoodScreen({
    super.key,
    required this.userId,
    required this.wellnessController,
  });

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> with TickerProviderStateMixin {
  late final WellnessController _controller;

  int _selectedIndex = 0;
  double _intensity = 5;

  List<dynamic> _tips = [];
  String? _lastMood;

  bool _isSaving = false;

  final TextEditingController _manualController = TextEditingController();

  StreamSubscription? _moodSubscription;

  final List<String> moods = [
    "Happy",
    "Sad",
    "Disgusted",
    "Angry",
    "Fearful",
    "Bad",
    "Surprised"
  ];

  final List<String> emojis = ["😄", "😢", "🤢", "😡", "😨", "😞", "😲"];

  final List<Color> moodColors = [
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.orange,
    Colors.grey,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.wellnessController;
    _listenToLatestMood();
  }

  void _listenToLatestMood() {
    _moodSubscription =
        _controller.getMoodLogs(widget.userId).listen((snapshot) {
      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;

        setState(() {
          _tips = data["tips"] ?? [];
          _lastMood = data["mood"];
        });
      }
    });
  }

  Future<void> _saveMood(String mood) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _controller.analyzeManualMood(
        userId: widget.userId,
        moodInput: mood,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("$mood saved"),
          action: SnackBarAction(
            label: "UNDO",
            onPressed: () {
              _controller.deleteLatestMood(widget.userId);
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleMoodTap(Offset localPos) {
    final center = const Offset(140, 140);

    final angle = atan2(
      localPos.dy - center.dy,
      localPos.dx - center.dx,
    );

    int index = ((angle + pi) / (2 * pi / moods.length)).floor();

    if (index < 0) index = 0;
    if (index >= moods.length) index = moods.length - 1;

    setState(() {
      _selectedIndex = index;
    });
  }

  void _saveSelectedMood() {
    final mood = "${moods[_selectedIndex]} (${_intensity.toInt()}/10)";

    _saveMood(mood);
  }

  @override
  void dispose() {
    _moodSubscription?.cancel();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = moodColors[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "Mood Meter",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Track how you feel today",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// LAST MOOD
                  if (_lastMood != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Last mood: $_lastMood",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 25),

                  /// PIZZA MOOD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          selectedColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTapUp: (details) {
                            final box = context.findRenderObject() as RenderBox;

                            final localPos = box.globalToLocal(
                              details.globalPosition,
                            );

                            _handleMoodTap(localPos);
                          },
                          child: SizedBox(
                            height: 280,
                            width: 280,
                            child: CustomPaint(
                              painter: PizzaPainter(
                                selectedIndex: _selectedIndex,
                                moodColors: moodColors,
                                moods: moods,
                              ),
                              child: Center(
                                child: AnimatedScale(
                                  scale: 1.1,
                                  duration: const Duration(milliseconds: 250),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: Text(
                                      emojis[_selectedIndex],
                                      key: ValueKey(_selectedIndex),
                                      style: const TextStyle(
                                        fontSize: 58,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            moods[_selectedIndex],
                            key: ValueKey(moods[_selectedIndex]),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: selectedColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// INTENSITY
                        Column(
                          children: [
                            Text(
                              "Intensity ${_intensity.toInt()}/10",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: selectedColor,
                                thumbColor: selectedColor,
                              ),
                              child: Slider(
                                value: _intensity,
                                min: 1,
                                max: 10,
                                divisions: 9,
                                onChanged: (v) {
                                  setState(() {
                                    _intensity = v;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedColor,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: _saveSelectedMood,
                            child: const Text(
                              "Save Mood",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// MANUAL MOOD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_rounded),
                            SizedBox(width: 10),
                            Text(
                              "Describe Your Mood",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _manualController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Write what you're feeling...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_manualController.text.trim().isEmpty) {
                                return;
                              }

                              _saveMood(
                                _manualController.text.trim(),
                              );

                              _manualController.clear();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              "Analyze Mood",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// WELLNESS TIPS
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.lightBlue.shade100,
                          Colors.purple.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb),
                            SizedBox(width: 10),
                            Text(
                              "Wellness Tips",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _tips.isEmpty
                            ? const Text(
                                "Log a mood to receive wellness guidance 💡",
                              )
                            : Column(
                                children: _tips
                                    .map(
                                      (tip) => Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          "• $tip",
                                          style: const TextStyle(
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PizzaPainter extends CustomPainter {
  final int selectedIndex;
  final List<String> moods;
  final List<Color> moodColors;

  PizzaPainter({
    required this.selectedIndex,
    required this.moods,
    required this.moodColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final radius = size.width / 2;

    final sweep = 2 * pi / moods.length;

    for (int i = 0; i < moods.length; i++) {
      final paint = Paint()
        ..color = i == selectedIndex
            ? moodColors[i]
            : moodColors[i].withOpacity(0.35);

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        i * sweep,
        sweep,
        true,
        paint,
      );
    }

    /// INNER CIRCLE
    canvas.drawCircle(
      center,
      55,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
