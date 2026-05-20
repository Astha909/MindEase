import 'package:flutter/material.dart';
import '../controllers/wellness_controller.dart';
import 'dart:math';
import 'dart:async';

class MoodScreen extends StatefulWidget {
  final String userId;
  final WellnessController wellnessController;

  final Function(
    String mood,
    Color color,
  ) onMoodChanged;

  const MoodScreen({
    super.key,
    required this.userId,
    required this.wellnessController,
    required this.onMoodChanged,
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

  bool _showSavedMessage = false;
  bool _savingMood = false;
  bool _analyzingMood = false;

  final TextEditingController _manualController = TextEditingController();
  StreamSubscription? _moodSubscription;

  final List<String> moods = [
    "Happy",
    "Sad",
    "Disgusted",
    "Angry",
    "Fearful",
    "Bad",
    "Surprised",
  ];

  final List<String> emojis = [
    "😄",
    "😢",
    "🤢",
    "😡",
    "😨",
    "😞",
    "😲",
  ];

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
    _moodSubscription = _controller.getMoodLogs(widget.userId).listen(
      (snapshot) {
        if (!mounted) return;

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data() as Map<String, dynamic>;

          final mood = data["mood"]?.toString();
          final streamTips = data["tips"];

          setState(() {
            _lastMood = mood;

            if (streamTips is List && streamTips.isNotEmpty) {
              _tips = streamTips;
            } else if (mood != null && mood.trim().isNotEmpty) {
              _tips = _getLocalTipsForMood(mood);
            }
          });
        }
      },
    );
  }

  List<String> _getLocalTipsForMood(String mood) {
    final cleanMood = mood.toLowerCase();

    if (cleanMood.contains("happy")) {
      return [
        "Enjoy this positive moment and notice what helped you feel this way.",
        "Share your happiness with someone you trust.",
        "Write down one thing you are grateful for today.",
      ];
    }

    if (cleanMood.contains("sad")) {
      return [
        "Take a few slow breaths and allow yourself to feel without judgment.",
        "Try a comforting activity like music, journaling, or a short walk.",
        "Reach out to someone safe if the sadness feels heavy.",
      ];
    }

    if (cleanMood.contains("angry")) {
      return [
        "Pause before reacting and take 5 deep breaths.",
        "Step away for a few minutes if possible.",
        "Write what triggered your anger before deciding what to do next.",
      ];
    }

    if (cleanMood.contains("fearful")) {
      return [
        "Ground yourself by naming 5 things you can see around you.",
        "Remind yourself that this feeling will pass.",
        "Try breathing slowly: inhale for 4 seconds, exhale for 6 seconds.",
      ];
    }

    if (cleanMood.contains("disgusted")) {
      return [
        "Take a short break from the situation if you can.",
        "Notice what caused the feeling and give yourself space.",
        "Drink water or do a quick reset activity.",
      ];
    }

    if (cleanMood.contains("surprised")) {
      return [
        "Pause and give yourself time to understand what happened.",
        "Notice whether the surprise feels positive or stressful.",
        "Take one small step before making a big decision.",
      ];
    }

    if (cleanMood.contains("bad")) {
      return [
        "Be gentle with yourself today.",
        "Try doing one small task that feels manageable.",
        "Talk to someone you trust if the feeling continues.",
      ];
    }

    return [
      "Take a moment to check in with yourself.",
      "Drink water and relax your shoulders.",
      "Write one sentence about how you feel right now.",
    ];
  }

  void _showSuccessMessage() {
    setState(() {
      _showSavedMessage = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _showSavedMessage = false;
      });
    });
  }

  Future<void> _saveSelectedMood() async {
    if (_savingMood || _analyzingMood || _controller.isLoading) return;

    final mood = moods[_selectedIndex];
    final intensityNote = "Intensity: ${_intensity.toInt()}/10";

    setState(() {
      _savingMood = true;
      _showSavedMessage = false;
    });

    await _controller.addMood(
      userId: widget.userId,
      mood: mood,
      note: intensityNote,
      isManual: true,
    );

    if (!mounted) return;

    if (_controller.errorMessage == null) {
      setState(() {
        _lastMood = "$mood (${_intensity.toInt()}/10)";
        _tips = _getLocalTipsForMood(mood);
      });

      widget.onMoodChanged(
        mood,
        moodColors[_selectedIndex],
      );

      _showSuccessMessage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _savingMood = false;
      });
    }
  }

  Future<void> _analyzeManualMood() async {
    if (_savingMood || _analyzingMood || _controller.isLoading) return;

    final text = _manualController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mood input cannot be empty"),
        ),
      );
      return;
    }

    setState(() {
      _analyzingMood = true;
      _showSavedMessage = false;
    });

    await _controller.analyzeManualMood(
      userId: widget.userId,
      moodInput: text,
    );

    if (!mounted) return;

    if (_controller.errorMessage == null) {
      _manualController.clear();
      _showSuccessMessage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _analyzingMood = false;
      });
    }
  }

  void _handleMoodTap(Offset localPos) {
    if (_savingMood || _analyzingMood || _controller.isLoading) return;

    const center = Offset(140, 140);

    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    double angle = atan2(dy, dx);
    angle += pi / 2;

    if (angle < 0) {
      angle += 2 * pi;
    }

    final sweep = 2 * pi / moods.length;

    int index = (angle / sweep).floor();

    if (index >= moods.length) {
      index = moods.length - 1;
    }

    setState(() {
      _selectedIndex = index;
      _tips = _getLocalTipsForMood(moods[index]);
    });
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
    final errorMessage = _controller.errorMessage;

    final controlsDisabled =
        _savingMood || _analyzingMood || _controller.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 25),
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
                      onTapUp: controlsDisabled
                          ? null
                          : (details) {
                              _handleMoodTap(details.localPosition);
                            },
                      child: SizedBox(
                        height: 280,
                        width: 280,
                        child: CustomPaint(
                          painter: PizzaPainter(
                            selectedIndex: _selectedIndex,
                            moodColors: moodColors,
                            moods: moods,
                            emojis: emojis,
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
                            onChanged: controlsDisabled
                                ? null
                                : (v) {
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
                          disabledBackgroundColor:
                              selectedColor.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: controlsDisabled ? null : _saveSelectedMood,
                        child: _savingMood
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Save Mood",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showSavedMessage
                          ? Container(
                              key: const ValueKey("saved_message"),
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Mood saved successfully",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
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
                      enabled: !controlsDisabled,
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
                        onPressed: controlsDisabled ? null : _analyzeManualMood,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _analyzingMood
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Analyze Mood"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      selectedColor.withOpacity(0.18),
                      Colors.white,
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
                            "Select or log a mood to receive wellness guidance 💡",
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
                                      borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}

class PizzaPainter extends CustomPainter {
  final int selectedIndex;
  final List<String> moods;
  final List<Color> moodColors;
  final List<String> emojis;

  PizzaPainter({
    required this.selectedIndex,
    required this.moods,
    required this.moodColors,
    required this.emojis,
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
        (i * sweep) - (pi / 2),
        sweep,
        true,
        paint,
      );

      final angle = ((i * sweep) - (pi / 2)) + (sweep / 2);
      final labelRadius = radius * 0.72;

      final dx = center.dx + labelRadius * cos(angle);
      final dy = center.dy + labelRadius * sin(angle);

      final emojiPainter = TextPainter(
        text: TextSpan(
          text: emojis[i],
          style: const TextStyle(fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      );

      emojiPainter.layout();

      emojiPainter.paint(
        canvas,
        Offset(
          dx - 12,
          dy - 18,
        ),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: moods[i],
          style: TextStyle(
            color: i == selectedIndex ? Colors.white : Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout(maxWidth: 55);

      textPainter.paint(
        canvas,
        Offset(
          dx - (textPainter.width / 2),
          dy + 4,
        ),
      );
    }

    canvas.drawCircle(
      center,
      55,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant PizzaPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.moodColors != moodColors ||
        oldDelegate.moods != moods ||
        oldDelegate.emojis != emojis;
  }
}
