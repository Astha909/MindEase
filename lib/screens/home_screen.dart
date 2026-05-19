import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';

import 'chat_screen.dart';
import 'mood_screen.dart';
import 'emergency_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({
    super.key,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final HomeController _homeController;
  late final AnimationController _bgController;

  String currentMood = "Happy";
  Color currentMoodColor = Colors.green;

  @override
  void initState() {
    super.initState();

    _homeController = HomeController();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  void updateMood(
    String mood,
    Color color,
  ) {
    setState(() {
      currentMood = mood;
      currentMoodColor = color;
    });
  }

  List<Color> getHomeGradient() {
    switch (currentMood.toLowerCase()) {
      case "happy":
        return [
          const Color(0xFFFFD89B),
          const Color(0xFFFFB6B9),
          const Color(0xFFFFECD2),
        ];

      case "sad":
        return [
          const Color(0xFF0F2027),
          const Color(0xFF203A43),
          const Color(0xFF2C5364),
        ];

      case "angry":
        return [
          const Color(0xFF870000),
          const Color(0xFF190A05),
          const Color(0xFFFF512F),
        ];

      case "fearful":
        return [
          const Color(0xFF232526),
          const Color(0xFF414345),
          const Color(0xFF000000),
        ];

      case "disgusted":
        return [
          const Color(0xFF654EA3),
          const Color(0xFFEAAFC8),
          const Color(0xFF5B247A),
        ];

      case "surprised":
        return [
          const Color(0xFFF7971E),
          const Color(0xFFFFD200),
          const Color(0xFFFFF6B7),
        ];

      default:
        return [
          const Color(0xFFF3E5F5),
          const Color(0xFFE1F5FE),
          const Color(0xFFD1C4E9),
          const Color(0xFFB3E5FC),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(0, 163, 145, 145),
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(0, 138, 105, 105),
            elevation: 0,
            surfaceTintColor: const Color.fromARGB(0, 159, 124, 124),
            centerTitle: true,
            title: const Text(
              "Chhotu AI",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          currentMoodColor,
                          currentMoodColor.withOpacity(0.65),
                        ],
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF5D9CEC),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  -1 + (_bgController.value * 2),
                  -1,
                ),
                end: Alignment(
                  1,
                  1 - (_bgController.value * 2),
                ),
                colors: getHomeGradient(),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          currentMoodColor.withOpacity(0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -60,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          currentMoodColor.withOpacity(0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: AnimatedBuilder(
                    animation: _homeController,
                    builder: (context, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        layoutBuilder: (
                          currentChild,
                          previousChildren,
                        ) {
                          return Stack(
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: _buildCurrentScreen(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AnimatedBuilder(
            animation: _homeController,
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: currentMoodColor.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BottomNavigationBar(
                    currentIndex: _homeController.selectedIndex,
                    onTap: (index) {
                      if (index == _homeController.selectedIndex) return;
                      _homeController.changeTab(index);
                    },
                    selectedItemColor: currentMoodColor,
                    unselectedItemColor: Colors.grey,
                    backgroundColor: Colors.white.withOpacity(0.92),
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat_bubble_outline),
                        label: "Chat",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.mood_outlined),
                        label: "Mood",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.warning_amber_outlined),
                        label: "Emergency",
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    switch (_homeController.selectedIndex) {
      case 0:
        return ChatScreen(
          key: const ValueKey(0),
          chatController: _homeController.chatController,
          userId: widget.userId,
          mood: currentMood,
          moodColor: currentMoodColor,
        );

      case 1:
        return MoodScreen(
          key: const ValueKey(1),
          userId: widget.userId,
          wellnessController: _homeController.wellnessController,
          onMoodChanged: updateMood,
        );

      case 2:
        return EmergencyScreen(
          key: const ValueKey(2),
          userId: widget.userId,
          emergencyController: _homeController.emergencyController,
        );

      default:
        return const SizedBox();
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _homeController.dispose();
    super.dispose();
  }
}
