import 'package:flutter/material.dart';

import 'chat_controller.dart';
import 'profile_controller.dart';
import 'wellness_controller.dart';
import 'emergency_controller.dart';

class HomeController extends ChangeNotifier {

  late final EmergencyController emergencyController;
  late final ChatController chatController;
  late final WellnessController wellnessController;
  late final ProfileController profileController;

  HomeController() {
    emergencyController = EmergencyController();

    chatController = ChatController(
      emergencyController: emergencyController,
    );

    wellnessController = WellnessController();
    profileController = ProfileController();
  }

  int selectedIndex = 0;

  void changeTab(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void openChat() {
    selectedIndex = 0;
    notifyListeners();
  }

  void openMood() {
    selectedIndex = 1;
    notifyListeners();
  }

  void openEmergency() {
    selectedIndex = 2;
    notifyListeners();
  }

  @override
  void dispose() {
    emergencyController.dispose();
    chatController.dispose();
    wellnessController.dispose();
    profileController.dispose();
    super.dispose();
  }
}