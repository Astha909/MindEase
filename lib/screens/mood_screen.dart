import 'package:flutter/material.dart';
import '../controllers/wellness_controller.dart';
import 'dart:math';

class MoodScreen extends StatefulWidget {
  final String userId;

  const MoodScreen({super.key, required this.userId});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen>
    with SingleTickerProviderStateMixin {
  final WellnessController _controller = WellnessController();

  double _moodValue = 5;
  late AnimationController _animationController;

  List<dynamic> _tips = [];
  bool _isSaving = false;

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
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _listenToLatestMood();
  }

  void _listenToLatestMood() {
    _controller.getMoodLogs(widget.userId).listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _tips = data["tips"] ?? [];
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

  Future<void> _saveMood() async {
    final index = _getMoodIndex(_moodValue);

    setState(() => _isSaving = true);

    await _controller.analyzeManualMood(
      userId: widget.userId,
      moodInput: moodLabels[index],
    );

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final index = _getMoodIndex(_moodValue);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
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

              /// PREMIUM CARD
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      moodEmojis[index],
                      style: const TextStyle(fontSize: 70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      moodLabels[index],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 30),

                    /// Circular Mood Meter
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
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    /// Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: moodColors[index],
                        inactiveTrackColor: Colors.grey.shade300,
                        thumbColor: moodColors[index],
                        overlayColor: moodColors[index].withOpacity(0.2),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 12),
                      ),
                      child: Slider(
                        value: _moodValue,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _moodValue = value;
                            _animationController.forward(from: 0);
                          });
                        },
                        onChangeEnd: (value) {
                          _saveMood();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// WELLNESS SECTION (Backend Tips)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 158, 212, 228),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Wellness",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    _tips.isEmpty
                        ? const Text(
                            "Content updating",
                            style: TextStyle(color: Colors.grey),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _tips
                                .map((tip) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
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
      ),
    );
  }
}

/// Custom painter for circular mood meter
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
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Paint foreground = Paint()
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
