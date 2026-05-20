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

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _homeController;

  String currentMood = "Happy";
  Color currentMoodColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
  }

  void updateMood(String mood, Color color) {
    setState(() {
      currentMood = mood;
      currentMoodColor = color;
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileController: _homeController.profileController,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _homeController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: IndexedStack(
            index: _homeController.selectedIndex,
            children: [
              ChatScreen(
                chatController: _homeController.chatController,
                userId: widget.userId,
                mood: currentMood,
                moodColor: currentMoodColor,
              ),
              MoodScreen(
                userId: widget.userId,
                wellnessController: _homeController.wellnessController,
                onMoodChanged: updateMood,
              ),
              EmergencyScreen(
                userId: widget.userId,
                emergencyController: _homeController.emergencyController,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: currentMoodColor,
            elevation: 6,
            onPressed: _openProfile,
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBottomNav() {
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
          backgroundColor: Colors.white.withOpacity(0.94),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mood_outlined),
              activeIcon: Icon(Icons.mood_rounded),
              label: "Mood",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_outlined),
              activeIcon: Icon(Icons.warning_amber_rounded),
              label: "Emergency",
            ),
          ],
        ),
      ),
    );
  }
}
