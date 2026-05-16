import 'package:cloud_firestore/cloud_firestore.dart';


class WellnessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> seedSampleTips() async {
    final tips = [
      {
        "title": "Take Deep Breaths",
        "content":
        "Pause for 1 minute and take slow, deep breaths. Inhale for 4 seconds, hold for 4, exhale for 4.",
        "category": "anxiety",
        "emoji": "🫁"
      },
      {
        "title": "Stay Hydrated",
        "content":
        "Drink enough water daily. Dehydration can increase fatigue and mood swings.",
        "category": "physical",
        "emoji": "💧"
      },
      {
        "title": "Get 7–8 Hours Sleep",
        "content":
        "Proper sleep helps regulate mood, memory, and stress levels.",
        "category": "sleep",
        "emoji": "😴"
      },
      {
        "title": "Go for a Walk",
        "content":
        "A 15-minute walk outside can significantly reduce stress and clear your mind.",
        "category": "stress",
        "emoji": "🚶‍♂️"
      },
      {
        "title": "Limit Social Media",
        "content":
        "Reduce scrolling time to avoid comparison and information overload.",
        "category": "digital",
        "emoji": "📵"
      },
      {
        "title": "Practice Gratitude",
        "content":
        "Write down 3 things you're grateful for today. It shifts focus toward positivity.",
        "category": "mindset",
        "emoji": "🙏"
      },
      {
        "title": "Talk to Someone",
        "content":
        "Sharing your feelings with a trusted person reduces emotional burden.",
        "category": "support",
        "emoji": "🗣️"
      },
      {
        "title": "Stretch Your Body",
        "content":
        "Light stretching releases tension built up from stress.",
        "category": "physical",
        "emoji": "🤸"
      },
      {
        "title": "Break Big Tasks",
        "content":
        "Divide overwhelming tasks into smaller, manageable steps.",
        "category": "productivity",
        "emoji": "🧩"
      },
      {
        "title": "Reduce Caffeine",
        "content":
        "Too much caffeine can increase anxiety and restlessness.",
        "category": "health",
        "emoji": "☕"
      },
      {
        "title": "Write Your Thoughts",
        "content":
        "Journaling helps organize emotions and reduce overthinking.",
        "category": "reflection",
        "emoji": "📓"
      },
      {
        "title": "Listen to Calm Music",
        "content":
        "Soft instrumental or nature sounds can calm your nervous system.",
        "category": "relaxation",
        "emoji": "🎵"
      },
      {
        "title": "Meditate 5 Minutes",
        "content":
        "Even 5 minutes of mindfulness meditation improves emotional balance.",
        "category": "mindfulness",
        "emoji": "🧘"
      },
      {
        "title": "Eat Balanced Meals",
        "content":
        "Nutritious food supports stable mood and sustained energy.",
        "category": "health",
        "emoji": "🥗"
      },
      {
        "title": "Set Daily Intentions",
        "content":
        "Start your day with one meaningful intention to guide your focus.",
        "category": "mindset",
        "emoji": "🎯"
      },
      {
        "title": "Challenge Negative Thoughts",
        "content":
        "Replace harsh self-talk with realistic and compassionate thinking.",
        "category": "self-esteem",
        "emoji": "💬"
      },
      {
        "title": "Clean Your Space",
        "content":
        "A tidy environment improves clarity and reduces mental clutter.",
        "category": "environment",
        "emoji": "🧹"
      },
      {
        "title": "Spend Time in Nature",
        "content":
        "Natural environments help lower cortisol (stress hormone) levels.",
        "category": "relaxation",
        "emoji": "🌿"
      },
      {
        "title": "Take Short Breaks",
        "content":
        "Work for 50 minutes, rest for 10 to prevent burnout.",
        "category": "productivity",
        "emoji": "⏳"
      },
      {
        "title": "Be Kind to Yourself",
        "content":
        "Treat yourself with the same compassion you offer others.",
        "category": "self-care",
        "emoji": "💛"
      },
    ];
    final existing = await _firestore
        .collection('wellness_tips')
        .limit(1)
        .get();

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
    if (userId.isEmpty || mood.isEmpty) {
      throw Exception("Invalid mood log data");
    }
    await _firestore.collection('mood_logs').add({
      'userId': userId,
      'mood': mood,
      'note': note ?? '',
      'tips': tips ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // GET mood logs (latest first)
  Stream<QuerySnapshot> getMoodLogs(String userId) {
    return _firestore
        .collection('mood_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // GET wellness tips
  Stream<QuerySnapshot> getWellnessTips() {
    return _firestore
        .collection('wellness_tips')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // DELETE latest mood log
  Future<void> deleteLatestMood(String userId) async {
    final snapshot = await _firestore
        .collection('mood_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

  // FETCH latest mood
  Future<String?> fetchLatestMood(String userId) async {
    final snapshot = await _firestore
        .collection('mood_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return snapshot.docs.first.data()['mood'];
  }

  // GET tips based on mood
  Future<List<dynamic>> getTipsForMood(String mood) async {

    final snapshot = await _firestore
        .collection('wellness_tips')
        .limit(5)
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    // Simple mapping based on mood keywords
    final moodMap = {
      "sad": ["support", "self-care", "mindset"],
      "anxious": ["anxiety", "mindfulness", "relaxation"],
      "stressed": ["stress", "relaxation", "physical"],
      "overwhelmed": ["productivity", "mindfulness", "support"],
      "angry": ["reflection", "relaxation"],
      "lonely": ["support", "self-care"],
      "tired": ["sleep", "health"],
    };

    final allowedCategories =
        moodMap[mood] ?? ["mindset"];

    final filteredTips = snapshot.docs.where((doc) {

      final data = doc.data();

      return allowedCategories.contains(
        data["category"],
      );
    }).toList();

    return filteredTips.map((doc) {

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

    return activities[mood] ??
        "Take a few mindful breaths.";
  }

}
