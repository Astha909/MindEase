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

  int _selectedIndex = 0;

  String currentMood = "Happy";
  Color currentMoodColor = Colors.green;

  bool _isProfileOpening = false;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
  }

  void updateMood(String mood, Color color) {
    if (!mounted) return;

    setState(() {
      currentMood = mood;
      currentMoodColor = color;
    });
  }

  Future<void> _openProfile() async {
    if (_isProfileOpening) return;

    setState(() {
      _isProfileOpening = true;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileController: _homeController.profileController,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _isProfileOpening = false;
    });
  }

  void _changeTab(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    _homeController.changeTab(index);
  }

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ChatScreen(
            chatController: _homeController.chatController,
            userId: widget.userId,
            mood: currentMood,
            moodColor: currentMoodColor,
            onProfileTap: _openProfile,
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
      bottomNavigationBar: _buildBottomNav(),
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
          currentIndex: _selectedIndex,
          onTap: _changeTab,
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
