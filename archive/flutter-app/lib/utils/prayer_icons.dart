import 'package:flutter/cupertino.dart';

/// Prayer icons with colors representing each prayer time
class PrayerIcons {
  /// Get icon and color for a prayer
  static PrayerIconData getIconData(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
      case 'Fajr':
        return PrayerIconData(
          icon: CupertinoIcons.sunrise_fill,
          color: Color(0xFF9C27B0), // Purple - dawn/pre-sunrise
          gradient: LinearGradient(
            colors: [Color(0xFF5E35B1), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'الظهر':
      case 'Dhuhr':
        return PrayerIconData(
          icon: CupertinoIcons.sun_max_fill,
          color: Color(0xFFFFA726), // Orange - noon sun
          gradient: LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFFA726)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'العصر':
      case 'Asr':
        return PrayerIconData(
          icon: CupertinoIcons.sun_dust_fill,
          color: Color(0xFFFFB74D), // Light orange - afternoon
          gradient: LinearGradient(
            colors: [Color(0xFFFFB74D), Color(0xFFFFCC80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'المغرب':
      case 'Maghrib':
        return PrayerIconData(
          icon: CupertinoIcons.sunset_fill,
          color: Color(0xFFEF5350), // Red - sunset
          gradient: LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'العشاء':
      case 'Isha':
        return PrayerIconData(
          icon: CupertinoIcons.moon_stars_fill,
          color: Color(0xFF5C6BC0), // Indigo - night
          gradient: LinearGradient(
            colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      default:
        return PrayerIconData(
          icon: CupertinoIcons.clock_fill,
          color: CupertinoColors.systemGrey,
          gradient: LinearGradient(
            colors: [CupertinoColors.systemGrey, CupertinoColors.systemGrey2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }

  /// Create a gradient icon widget
  static Widget buildGradientIcon({
    required IconData icon,
    required Gradient gradient,
    required double size,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Icon(
        icon,
        size: size,
        color: CupertinoColors.white,
      ),
    );
  }

  /// Create a simple colored icon widget
  static Widget buildColoredIcon({
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}

/// Data class for prayer icon information
class PrayerIconData {
  final IconData icon;
  final Color color;
  final Gradient gradient;

  PrayerIconData({
    required this.icon,
    required this.color,
    required this.gradient,
  });
}
