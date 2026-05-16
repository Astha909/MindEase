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

  /// CURRENT MOOD STATE
  String currentMood = "Happy";

  Color currentMoodColor = Colors.green;

  @override
  void initState() {
    super.initState();

    _homeController = HomeController();
  }

  /// UPDATE MOOD FROM MOOD SCREEN
  void updateMood(
    String mood,
    Color color,
  ) {
    setState(() {
      currentMood = mood;
      currentMoodColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "MindEase",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
            ),
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
                duration: const Duration(
                  milliseconds: 300,
                ),
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF5D9CEC),
                      Color(0xFFA0D995),
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
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _homeController,
          builder: (context, _) {
            return AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 300,
              ),
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
      bottomNavigationBar: AnimatedBuilder(
        animation: _homeController,
        builder: (context, _) {
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                currentIndex: _homeController.selectedIndex,
                onTap: (index) {
                  if (index == _homeController.selectedIndex) {
                    return;
                  }

                  _homeController.changeTab(index);
                },
                selectedItemColor: currentMoodColor,
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.white,
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
                    icon: Icon(
                      Icons.warning_amber_outlined,
                    ),
                    label: "Emergency",
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_homeController.selectedIndex) {
      /// CHAT
      case 0:
        return ChatScreen(
          key: const ValueKey(0),
          chatController: _homeController.chatController,
          userId: widget.userId,
          mood: currentMood,
          moodColor: currentMoodColor,
        );

      /// MOOD
      case 1:
        return MoodScreen(
          key: const ValueKey(1),
          userId: widget.userId,
          wellnessController: _homeController.wellnessController,
          onMoodChanged: updateMood,
        );

      /// EMERGENCY
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
    _homeController.dispose();

    super.dispose();
  }
}
