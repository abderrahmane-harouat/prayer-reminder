class PrayerNotificationSettings {
  final bool enabled;
  final int prePrayerReminderMinutes;
  final int departureReminderMinutes;

  PrayerNotificationSettings({
    this.enabled = true,
    this.prePrayerReminderMinutes = 5,
    this.departureReminderMinutes = 5,
  });

  PrayerNotificationSettings copyWith({
    bool? enabled,
    int? prePrayerReminderMinutes,
    int? departureReminderMinutes,
  }) {
    return PrayerNotificationSettings(
      enabled: enabled ?? this.enabled,
      prePrayerReminderMinutes:
          prePrayerReminderMinutes ?? this.prePrayerReminderMinutes,
      departureReminderMinutes:
          departureReminderMinutes ?? this.departureReminderMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'prePrayerReminderMinutes': prePrayerReminderMinutes,
      'departureReminderMinutes': departureReminderMinutes,
    };
  }

  factory PrayerNotificationSettings.fromJson(Map<String, dynamic> json) {
    return PrayerNotificationSettings(
      enabled: json['enabled'] ?? true,
      prePrayerReminderMinutes: json['prePrayerReminderMinutes'] ?? 5,
      departureReminderMinutes: json['departureReminderMinutes'] ?? 5,
    );
  }
}

class TravelTimeSettings {
  final int fajrTravelMinutes;
  final int dhuhrTravelMinutes;
  final int asrTravelMinutes;
  final int maghribTravelMinutes;
  final int ishaTravelMinutes;

  TravelTimeSettings({
    this.fajrTravelMinutes = 10,
    this.dhuhrTravelMinutes = 10,
    this.asrTravelMinutes = 10,
    this.maghribTravelMinutes = 10,
    this.ishaTravelMinutes = 10,
  });

  int getTravelTimeForPrayer(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return fajrTravelMinutes;
      case 'Dhuhr':
        return dhuhrTravelMinutes;
      case 'Asr':
        return asrTravelMinutes;
      case 'Maghrib':
        return maghribTravelMinutes;
      case 'Isha':
        return ishaTravelMinutes;
      default:
        return 10;
    }
  }

  TravelTimeSettings copyWith({
    int? fajrTravelMinutes,
    int? dhuhrTravelMinutes,
    int? asrTravelMinutes,
    int? maghribTravelMinutes,
    int? ishaTravelMinutes,
  }) {
    return TravelTimeSettings(
      fajrTravelMinutes: fajrTravelMinutes ?? this.fajrTravelMinutes,
      dhuhrTravelMinutes: dhuhrTravelMinutes ?? this.dhuhrTravelMinutes,
      asrTravelMinutes: asrTravelMinutes ?? this.asrTravelMinutes,
      maghribTravelMinutes: maghribTravelMinutes ?? this.maghribTravelMinutes,
      ishaTravelMinutes: ishaTravelMinutes ?? this.ishaTravelMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fajrTravelMinutes': fajrTravelMinutes,
      'dhuhrTravelMinutes': dhuhrTravelMinutes,
      'asrTravelMinutes': asrTravelMinutes,
      'maghribTravelMinutes': maghribTravelMinutes,
      'ishaTravelMinutes': ishaTravelMinutes,
    };
  }

  factory TravelTimeSettings.fromJson(Map<String, dynamic> json) {
    return TravelTimeSettings(
      fajrTravelMinutes: json['fajrTravelMinutes'] ?? 10,
      dhuhrTravelMinutes: json['dhuhrTravelMinutes'] ?? 10,
      asrTravelMinutes: json['asrTravelMinutes'] ?? 10,
      maghribTravelMinutes: json['maghribTravelMinutes'] ?? 10,
      ishaTravelMinutes: json['ishaTravelMinutes'] ?? 10,
    );
  }
}

/// Settings for adjusting prayer times manually
class PrayerTimeAdjustments {
  final int fajrAdjustment; // Minutes to add (positive) or subtract (negative)
  final int dhuhrAdjustment;
  final int asrAdjustment;
  final int maghribAdjustment;
  final int ishaAdjustment;

  PrayerTimeAdjustments({
    this.fajrAdjustment = 0,
    this.dhuhrAdjustment = 0,
    this.asrAdjustment = 0,
    this.maghribAdjustment = 0,
    this.ishaAdjustment = 0,
  });

  int getAdjustmentForPrayer(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return fajrAdjustment;
      case 'Dhuhr':
        return dhuhrAdjustment;
      case 'Asr':
        return asrAdjustment;
      case 'Maghrib':
        return maghribAdjustment;
      case 'Isha':
        return ishaAdjustment;
      default:
        return 0;
    }
  }

  PrayerTimeAdjustments copyWith({
    int? fajrAdjustment,
    int? dhuhrAdjustment,
    int? asrAdjustment,
    int? maghribAdjustment,
    int? ishaAdjustment,
  }) {
    return PrayerTimeAdjustments(
      fajrAdjustment: fajrAdjustment ?? this.fajrAdjustment,
      dhuhrAdjustment: dhuhrAdjustment ?? this.dhuhrAdjustment,
      asrAdjustment: asrAdjustment ?? this.asrAdjustment,
      maghribAdjustment: maghribAdjustment ?? this.maghribAdjustment,
      ishaAdjustment: ishaAdjustment ?? this.ishaAdjustment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fajrAdjustment': fajrAdjustment,
      'dhuhrAdjustment': dhuhrAdjustment,
      'asrAdjustment': asrAdjustment,
      'maghribAdjustment': maghribAdjustment,
      'ishaAdjustment': ishaAdjustment,
    };
  }

  factory PrayerTimeAdjustments.fromJson(Map<String, dynamic> json) {
    return PrayerTimeAdjustments(
      fajrAdjustment: json['fajrAdjustment'] ?? 0,
      dhuhrAdjustment: json['dhuhrAdjustment'] ?? 0,
      asrAdjustment: json['asrAdjustment'] ?? 0,
      maghribAdjustment: json['maghribAdjustment'] ?? 0,
      ishaAdjustment: json['ishaAdjustment'] ?? 0,
    );
  }
}

class AppSettings {
  final PrayerNotificationSettings fajrSettings;
  final PrayerNotificationSettings dhuhrSettings;
  final PrayerNotificationSettings asrSettings;
  final PrayerNotificationSettings maghribSettings;
  final PrayerNotificationSettings ishaSettings;
  final TravelTimeSettings travelTimeSettings;
  final PrayerTimeAdjustments timeAdjustments;
  final bool darkMode;
  final int hijriDateAdjustment; // Days to add/subtract from Hijri date

  AppSettings({
    PrayerNotificationSettings? fajrSettings,
    PrayerNotificationSettings? dhuhrSettings,
    PrayerNotificationSettings? asrSettings,
    PrayerNotificationSettings? maghribSettings,
    PrayerNotificationSettings? ishaSettings,
    TravelTimeSettings? travelTimeSettings,
    PrayerTimeAdjustments? timeAdjustments,
    this.darkMode = false,
    this.hijriDateAdjustment = 0,
  })  : fajrSettings = fajrSettings ??
            PrayerNotificationSettings(prePrayerReminderMinutes: 5),
        dhuhrSettings = dhuhrSettings ??
            PrayerNotificationSettings(prePrayerReminderMinutes: 5),
        asrSettings = asrSettings ??
            PrayerNotificationSettings(prePrayerReminderMinutes: 5),
        maghribSettings = maghribSettings ??
            PrayerNotificationSettings(prePrayerReminderMinutes: 10),
        ishaSettings = ishaSettings ??
            PrayerNotificationSettings(prePrayerReminderMinutes: 5),
        travelTimeSettings = travelTimeSettings ?? TravelTimeSettings(),
        timeAdjustments = timeAdjustments ?? PrayerTimeAdjustments();

  PrayerNotificationSettings getSettingsForPrayer(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return fajrSettings;
      case 'Dhuhr':
        return dhuhrSettings;
      case 'Asr':
        return asrSettings;
      case 'Maghrib':
        return maghribSettings;
      case 'Isha':
        return ishaSettings;
      default:
        return PrayerNotificationSettings();
    }
  }

  AppSettings copyWith({
    PrayerNotificationSettings? fajrSettings,
    PrayerNotificationSettings? dhuhrSettings,
    PrayerNotificationSettings? asrSettings,
    PrayerNotificationSettings? maghribSettings,
    PrayerNotificationSettings? ishaSettings,
    TravelTimeSettings? travelTimeSettings,
    PrayerTimeAdjustments? timeAdjustments,
    bool? darkMode,
    int? hijriDateAdjustment,
  }) {
    return AppSettings(
      fajrSettings: fajrSettings ?? this.fajrSettings,
      dhuhrSettings: dhuhrSettings ?? this.dhuhrSettings,
      asrSettings: asrSettings ?? this.asrSettings,
      maghribSettings: maghribSettings ?? this.maghribSettings,
      ishaSettings: ishaSettings ?? this.ishaSettings,
      travelTimeSettings: travelTimeSettings ?? this.travelTimeSettings,
      timeAdjustments: timeAdjustments ?? this.timeAdjustments,
      darkMode: darkMode ?? this.darkMode,
      hijriDateAdjustment: hijriDateAdjustment ?? this.hijriDateAdjustment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fajrSettings': fajrSettings.toJson(),
      'dhuhrSettings': dhuhrSettings.toJson(),
      'asrSettings': asrSettings.toJson(),
      'maghribSettings': maghribSettings.toJson(),
      'ishaSettings': ishaSettings.toJson(),
      'travelTimeSettings': travelTimeSettings.toJson(),
      'timeAdjustments': timeAdjustments.toJson(),
      'darkMode': darkMode,
      'hijriDateAdjustment': hijriDateAdjustment,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      fajrSettings: json['fajrSettings'] != null
          ? PrayerNotificationSettings.fromJson(json['fajrSettings'])
          : null,
      dhuhrSettings: json['dhuhrSettings'] != null
          ? PrayerNotificationSettings.fromJson(json['dhuhrSettings'])
          : null,
      asrSettings: json['asrSettings'] != null
          ? PrayerNotificationSettings.fromJson(json['asrSettings'])
          : null,
      maghribSettings: json['maghribSettings'] != null
          ? PrayerNotificationSettings.fromJson(json['maghribSettings'])
          : null,
      ishaSettings: json['ishaSettings'] != null
          ? PrayerNotificationSettings.fromJson(json['ishaSettings'])
          : null,
      travelTimeSettings: json['travelTimeSettings'] != null
          ? TravelTimeSettings.fromJson(json['travelTimeSettings'])
          : null,
      timeAdjustments: json['timeAdjustments'] != null
          ? PrayerTimeAdjustments.fromJson(json['timeAdjustments'])
          : null,
      darkMode: json['darkMode'] ?? false,
      hijriDateAdjustment: json['hijriDateAdjustment'] ?? 0,
    );
  }
}
