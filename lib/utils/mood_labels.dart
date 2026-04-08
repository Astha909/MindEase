class MoodLabels {
  static const List<String> moods = [
    'happy',
    'neutral',
    'sad',
    'anxious',
    'angry',
    'stressed',
    'lonely',
    'confused',
    'tired',
    'overwhelmed',
  ];

  static const List<String> riskLevels = [
    'low',
    'medium',
    'high',
    'emergency',
  ];
  static const Map<String, String> synonymMap = {
    // Hinglish / local
    'gussa': 'angry',
    'gussa aa raha': 'angry',
    'tension': 'anxious',
    'tension ho rahi': 'anxious',
    'dukhi': 'sad',
    'akela': 'lonely',
    'thik_thak': 'neutral',
    'thik thak': 'neutral',
    'thaka_hua': 'tired',
    'thaka hua': 'tired',

    // English variations
    'upset': 'sad',
    'worried': 'anxious',
    'frustrated': 'angry',
    'alone': 'lonely',
    'exhausted': 'tired',
    'burnt_out': 'overwhelmed',
    'burnout': 'overwhelmed',
  };
}