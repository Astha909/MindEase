import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import '../controllers/emergency_controller.dart';
import 'chat_screen.dart';
import 'mood_screen.dart';
import 'emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // ✅ Keep const

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _homeController = HomeController();

  // ✅ EmergencyController instance WITHOUT importing or passing service
  late final EmergencyController _emergencyController;

  @override
  void initState() {
    super.initState();
    _emergencyController = EmergencyController(); // uses default constructor
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "MindEase",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: AnimatedBuilder(
        animation: _homeController,
        builder: (context, _) {
          switch (_homeController.selectedIndex) {
            case 0:
              return ChatScreen(
                chatController: _homeController.chatController,
              );
            case 1:
              return const MoodScreen();
            case 2:
              return EmergencyScreen(
                emergencyController: _emergencyController,
              );
            default:
              return const SizedBox();
          }
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _homeController,
        builder: (context, _) {
          return BottomNavigationBar(
            currentIndex: _homeController.selectedIndex,
            onTap: (index) {
              _homeController.changeTab(index);
            },
            selectedItemColor: Colors.purple,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: "Chat",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mood),
                label: "Mood",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.warning_amber_outlined),
                label: "Emergency",
              ),
            ],
          );
        },
      ),
    );
  }
}
