import 'package:flutter/material.dart';

import 'chat_controller.dart';
import 'wellness_controller.dart';
import 'emergency_controller.dart';

class HomeController extends ChangeNotifier {
  final ChatController chatController = ChatController();
  final WellnessController wellnessController = WellnessController();
  final EmergencyController emergencyController = EmergencyController();

  int selectedIndex = 0;

  void changeTab(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  // Future ready methods
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
}
