class PrayerTimings {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTimings({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTimings.fromJson(Map<String, dynamic> json) {
    return PrayerTimings(
      fajr: json['Fajr'].toString().split(' ')[0],
      dhuhr: json['Dhuhr'].toString().split(' ')[0],
      asr: json['Asr'].toString().split(' ')[0],
      maghrib: json['Maghrib'].toString().split(' ')[0],
      isha: json['Isha'].toString().split(' ')[0],
    );
  }
}

class HijriDate {
  final String date;
  final String day; // Changed from int to String
  final String monthEn;
  final String year; // Changed from int to String

  HijriDate({
    required this.date,
    required this.day,
    required this.monthEn,
    required this.year,
  });

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      date: json['date'],
      day: json['day'].toString(), // Convert to String
      monthEn: json['month']['en'],
      year: json['year'].toString(), // Convert to String
    );
  }
}

class PrayerDay {
  final PrayerTimings timings;
  final HijriDate hijri;
  final String readableDate;

  PrayerDay({
    required this.timings,
    required this.hijri,
    required this.readableDate,
  });

  factory PrayerDay.fromJson(Map<String, dynamic> json) {
    return PrayerDay(
      timings: PrayerTimings.fromJson(json['timings']),
      hijri: HijriDate.fromJson(json['date']['hijri']),
      readableDate: json['date']['readable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timings': {
        'Fajr': timings.fajr,
        'Dhuhr': timings.dhuhr,
        'Asr': timings.asr,
        'Maghrib': timings.maghrib,
        'Isha': timings.isha,
      },
      'date': {
        'readable': readableDate,
        'hijri': {
          'date': hijri.date,
          'day': hijri.day,
          'month': {'en': hijri.monthEn},
          'year': hijri.year,
        },
      },
    };
  }
}

class PrayerNames {
  static const Map<String, String> arabic = {
    'Fajr': 'الفجر',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };
}
