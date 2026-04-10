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

class _MoodScreenState extends State<MoodScreen>
    with SingleTickerProviderStateMixin {
  late final WellnessController _controller;

  double _moodValue = 5;
  late AnimationController _animationController;

  List<dynamic> _tips = [];

  bool _isSaving = false;
  bool _showSaved = false;

  StreamSubscription? _moodSubscription;
  Timer? _debounce;

  String? _lastSavedMood;

  final List<String> moodLabels = [
    "Angry",
    "Upset",
    "Neutral",
    "Happy",
    "Excited"
  ];

  final List<Color> moodColors = [
    Colors.redAccent,
    Colors.orange,
    Colors.yellow,
    Colors.lightGreen,
    Colors.greenAccent
  ];

  final List<String> moodEmojis = [
    "😡",
    "😟",
    "😐",
    "🙂",
    "🤩",
  ];

  @override
  void initState() {
    super.initState();

    _controller = widget.wellnessController;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _listenToLatestMood();
  }

  void _listenToLatestMood() {
    _moodSubscription =
        _controller.getMoodLogs(widget.userId).listen((snapshot) {
      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;

        setState(() {
          _tips = (data["tips"] is List) ? data["tips"] : [];
        });
      }
    });
  }

  int _getMoodIndex(double value) {
    if (value <= 2) return 0;
    if (value <= 4) return 1;
    if (value <= 6) return 2;
    if (value <= 8) return 3;
    return 4;
  }

  String _getMoodMessage(int index) {
    switch (index) {
      case 0:
        return "Take it easy 💛";
      case 1:
        return "You got this 🌱";
      case 2:
        return "Steady vibes ✨";
      case 3:
        return "Nice! Keep it up 😄";
      case 4:
        return "Energy level 100 🚀";
      default:
        return "";
    }
  }

  Future<void> _saveMood() async {
    final index = _getMoodIndex(_moodValue);

    if (_lastSavedMood == moodLabels[index]) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _controller.analyzeManualMood(
        userId: widget.userId,
        moodInput: moodLabels[index],
      );

      _lastSavedMood = moodLabels[index];

      setState(() => _showSaved = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mood saved successfully")),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showSaved = false);
        }
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onSliderEnd() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _saveMood);
  }

  Future<void> _undoMood() async {
    await _controller.deleteLatestMood(widget.userId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Last mood removed")),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _moodSubscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = _getMoodIndex(_moodValue);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "Mood Meter",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// MAIN CARD
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade50,
                          Colors.blue.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        /// Emoji
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            moodEmojis[index],
                            key: ValueKey(index),
                            style: const TextStyle(fontSize: 70),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Mood Label
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            moodLabels[index],
                            key: ValueKey(index),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// Fun Message
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _getMoodMessage(index),
                            key: ValueKey(index),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// Circle
                        SizedBox(
                          height: 200,
                          width: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(200, 200),
                                painter: CircularMoodPainter(_moodValue),
                              ),
                              Text(
                                "${_moodValue.toInt()}/10",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: moodColors[index],
                            thumbColor: moodColors[index],
                          ),
                          child: Slider(
                            value: _moodValue,
                            min: 0,
                            max: 10,
                            divisions: 10,
                            onChanged: (value) {
                              setState(() {
                                _moodValue = value;
                              });
                            },
                            onChangeEnd: (_) => _onSliderEnd(),
                          ),
                        ),

                        if (_showSaved)
                          const Text(
                            "✓ Mood saved",
                            style: TextStyle(color: Colors.green),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Undo
                  TextButton(
                    onPressed: _undoMood,
                    child: const Text("Undo last mood"),
                  ),

                  const SizedBox(height: 20),

                  /// Wellness Tips
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 158, 212, 228),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Wellness",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _tips.isEmpty
                            ? const Text(
                                "Log your mood to see tips 💡",
                                style: TextStyle(color: Colors.grey),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _tips
                                    .map((tip) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Text("• $tip"),
                                        ))
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Loading
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.2),
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

class CircularMoodPainter extends CustomPainter {
  final double value;
  CircularMoodPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 15;
    double radius = (size.width - strokeWidth) / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    Paint background = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Paint foreground = Paint()
      ..shader = const SweepGradient(
        colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, background);

    double angle = 2 * pi * (value / 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      angle,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
