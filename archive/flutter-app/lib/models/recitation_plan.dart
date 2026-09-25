/// Represents the recitation plan for a single raka'a
class RakaPlan {
  final String surahName;
  final String notes;

  RakaPlan({
    required this.surahName,
    this.notes = '',
  });

  factory RakaPlan.empty() => RakaPlan(surahName: '', notes: '');

  bool get isEmpty => surahName.isEmpty && notes.isEmpty;
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() => {
        'surahName': surahName,
        'notes': notes,
      };

  factory RakaPlan.fromJson(Map<String, dynamic> json) {
    return RakaPlan(
      surahName: json['surahName'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  RakaPlan copyWith({
    String? surahName,
    String? notes,
  }) {
    return RakaPlan(
      surahName: surahName ?? this.surahName,
      notes: notes ?? this.notes,
    );
  }
}

/// Represents the recitation plan for a single prayer
class PrayerRecitationPlan {
  final String prayerName;
  final List<RakaPlan> rakas;

  PrayerRecitationPlan({
    required this.prayerName,
    required this.rakas,
  });

  /// Factory to create an empty plan for a prayer with specific number of rakas
  factory PrayerRecitationPlan.empty(String prayerName, int rakaCount) {
    return PrayerRecitationPlan(
      prayerName: prayerName,
      rakas: List.generate(rakaCount, (_) => RakaPlan.empty()),
    );
  }

  /// Returns the number of rakas for this prayer
  int get rakaCount => rakas.length;

  /// Check if all rakas are empty
  bool get isEmpty => rakas.every((r) => r.isEmpty);
  bool get isNotEmpty => !isEmpty;

  /// Check if any raka has content
  bool get hasAnyPlan => rakas.any((r) => r.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'prayerName': prayerName,
        'rakas': rakas.map((r) => r.toJson()).toList(),
      };

  factory PrayerRecitationPlan.fromJson(Map<String, dynamic> json) {
    return PrayerRecitationPlan(
      prayerName: json['prayerName'] as String,
      rakas: (json['rakas'] as List)
          .map((r) => RakaPlan.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  PrayerRecitationPlan copyWith({
    String? prayerName,
    List<RakaPlan>? rakas,
  }) {
    return PrayerRecitationPlan(
      prayerName: prayerName ?? this.prayerName,
      rakas: rakas ?? this.rakas,
    );
  }
}

/// Represents a daily recitation plan for all prayers
class DailyRecitationPlan {
  final DateTime date;
  final Map<String, PrayerRecitationPlan> prayers;

  DailyRecitationPlan({
    required this.date,
    required this.prayers,
  });

  /// Factory to create an empty daily plan
  factory DailyRecitationPlan.empty(DateTime date) {
    return DailyRecitationPlan(
      date: date,
      prayers: {
        'Fajr': PrayerRecitationPlan.empty('Fajr', 2),
        'Dhuhr': PrayerRecitationPlan.empty('Dhuhr', 4),
        'Asr': PrayerRecitationPlan.empty('Asr', 4),
        'Maghrib': PrayerRecitationPlan.empty('Maghrib', 3),
        'Isha': PrayerRecitationPlan.empty('Isha', 4),
      },
    );
  }

  /// Get prayer names in order
  static List<String> get prayerOrder =>
      ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  /// Arabic names for prayers
  static const Map<String, String> prayerArabicNames = {
    'Fajr': 'الفجر',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };

  /// Get raka count for each prayer
  static const Map<String, int> prayerRakaCounts = {
    'Fajr': 2,
    'Dhuhr': 4,
    'Asr': 4,
    'Maghrib': 3,
    'Isha': 4,
  };

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'prayers': prayers.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory DailyRecitationPlan.fromJson(Map<String, dynamic> json) {
    final Map<String, PrayerRecitationPlan> prayersMap = {};
    final prayersJson = json['prayers'] as Map<String, dynamic>;
    prayersJson.forEach((key, value) {
      prayersMap[key] =
          PrayerRecitationPlan.fromJson(value as Map<String, dynamic>);
    });

    return DailyRecitationPlan(
      date: DateTime.parse(json['date'] as String),
      prayers: prayersMap,
    );
  }

  DailyRecitationPlan copyWith({
    DateTime? date,
    Map<String, PrayerRecitationPlan>? prayers,
  }) {
    return DailyRecitationPlan(
      date: date ?? this.date,
      prayers: prayers ?? this.prayers,
    );
  }

  /// Check if any prayer has a plan
  bool get isNotEmpty => prayers.values.any((p) => p.isNotEmpty);
  bool get isEmpty => !isNotEmpty;
}

/// Represents a monthly recitation plan
class MonthlyRecitationPlan {
  final int year;
  final int month;
  final Map<String, DailyRecitationPlan>
      dailyPlans; // Key is date string 'YYYY-MM-DD'

  MonthlyRecitationPlan({
    required this.year,
    required this.month,
    required this.dailyPlans,
  });

  /// Factory to create an empty monthly plan
  factory MonthlyRecitationPlan.empty(int year, int month) {
    return MonthlyRecitationPlan(
      year: year,
      month: month,
      dailyPlans: {},
    );
  }

  /// Get or create a daily plan for a specific date
  DailyRecitationPlan getDailyPlan(DateTime date) {
    final key = _dateKey(date);
    if (!dailyPlans.containsKey(key)) {
      return DailyRecitationPlan.empty(date);
    }
    return dailyPlans[key]!;
  }

  /// Update a daily plan
  MonthlyRecitationPlan updateDailyPlan(
      DateTime date, DailyRecitationPlan plan) {
    final newPlans = Map<String, DailyRecitationPlan>.from(dailyPlans);
    newPlans[_dateKey(date)] = plan;
    return MonthlyRecitationPlan(
      year: year,
      month: month,
      dailyPlans: newPlans,
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'dailyPlans':
            dailyPlans.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory MonthlyRecitationPlan.fromJson(Map<String, dynamic> json) {
    final Map<String, DailyRecitationPlan> plansMap = {};
    final plansJson = json['dailyPlans'] as Map<String, dynamic>?;
    if (plansJson != null) {
      plansJson.forEach((key, value) {
        plansMap[key] =
            DailyRecitationPlan.fromJson(value as Map<String, dynamic>);
      });
    }

    return MonthlyRecitationPlan(
      year: json['year'] as int,
      month: json['month'] as int,
      dailyPlans: plansMap,
    );
  }
}
