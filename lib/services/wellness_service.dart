// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/wellness_tips_data.dart';

class WellnessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedSampleTips() async {
    final tips = sampleWellnessTips;

    final existing =
        await _firestore.collection('wellness_tips').limit(1).get();

    if (existing.docs.isNotEmpty) return;
    for (final tip in tips) {
      await _firestore.collection('wellness_tips').add({
        ...tip,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ADD mood log
  Future<void> addMoodLog({
    required String userId,
    required String mood,
    String? note,
    List<dynamic>? tips,
  }) async {
    if (userId.trim().isEmpty || mood.trim().isEmpty) {
      throw Exception(
        "Invalid mood log data",
      );
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_logs')
        .add({
      'userId': userId,
      'mood': mood.trim(),
      'note': note?.trim() ?? '',
      'tips': tips ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // GET mood logs (latest first)
  // UPDATED getMoodLogs()

  Stream<QuerySnapshot> getMoodLogs(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .handleError((e, stack) {
      print("Mood logs stream error: $e");
      print(stack);
    });
  }

  // GET wellness tips
  // UPDATED getWellnessTips()

  Stream<QuerySnapshot> getWellnessTips() {
    return _firestore
        .collection('wellness_tips')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .handleError((e, stack) {
      print("Wellness tips stream error: $e");
      print(stack);
    });
  }

  // DELETE latest mood log
  Future<void> deleteLatestMood(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_logs')
        .where(
          'userId',
          isEqualTo: userId,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(1)
        .get()
        .timeout(
          const Duration(seconds: 10),
        );

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

// UPDATED fetchLatestMood()

  Future<String?> fetchLatestMood(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.data()['mood'];
  }

  // WEEKLY mood analytics
  Future<Map<String, int>> getWeeklyMoodStats(
    String userId,
  ) async {
    final lastWeek = DateTime.now().subtract(
      const Duration(days: 7),
    );

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_logs')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeek),
        )
        .get();

    final Map<String, int> stats = {};

    for (final doc in snapshot.docs) {
      final mood = doc.data()['mood'] ?? 'unknown';

      stats[mood] = (stats[mood] ?? 0) + 1;
    }

    return stats;
  }

// MONTHLY mood analytics
  Future<Map<String, int>> getMonthlyMoodStats(
    String userId,
  ) async {
    final lastMonth = DateTime.now().subtract(
      const Duration(days: 30),
    );

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_logs')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(lastMonth),
        )
        .get();

    final Map<String, int> stats = {};

    for (final doc in snapshot.docs) {
      final mood = doc.data()['mood'] ?? 'unknown';

      stats[mood] = (stats[mood] ?? 0) + 1;
    }

    return stats;
  }

// MOOD trend data
  Future<List<Map<String, dynamic>>> getMoodTrendData(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_logs')
        .orderBy(
          'createdAt',
          descending: false,
        )
        .limit(30)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        "mood": data["mood"],
        "date": (data["createdAt"] as Timestamp).toDate().toIso8601String(),
      };
    }).toList();
  }

  // SAVE reminder settings
  Future<void> saveReminder({
    required String userId,
    required String time,
    required bool enabled,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .doc('daily_checkin')
        .set({
      'time': time,
      'enabled': enabled,
      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }

// GET reminder settings
  Future<Map<String, dynamic>?>
  getReminder(
      String userId,
      ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .doc('daily_checkin')
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  // UPDATED getTipsForMood()

  Future<List<dynamic>> getTipsForMood(String mood) async {
    final moodMap = {
      "sad": ["support", "self-care", "mindset"],
      "anxious": ["anxiety", "mindfulness", "relaxation"],
      "stressed": ["stress", "relaxation", "physical"],
      "overwhelmed": ["productivity", "mindfulness", "support"],
      "angry": ["reflection", "relaxation"],
      "lonely": ["support", "self-care"],
      "tired": ["sleep", "health"],
    };

    final allowedCategories = moodMap[mood] ?? ["mindset"];

    final snapshot = await _firestore
        .collection('wellness_tips')
        .where(
          'category',
          whereIn: allowedCategories,
        )
        .limit(5)
        .get()
        .timeout(const Duration(seconds: 10));

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return "${data["emoji"]} ${data["content"]}";
    }).toList();
  }

  // GET activity suggestion based on mood
  Future<String> getActivityForMood(String mood) async {
    final activities = {
      "sad": "Take a short walk outside.",
      "anxious": "Try a 5-minute breathing exercise.",
      "stressed": "Stretch your body and relax your shoulders.",
      "overwhelmed": "Break tasks into smaller steps.",
      "angry": "Pause and take deep breaths.",
      "lonely": "Reach out to someone you trust.",
      "tired": "Take proper rest and hydrate yourself.",
    };

    return activities[mood] ?? "Take a few mindful breaths.";
  }
}
