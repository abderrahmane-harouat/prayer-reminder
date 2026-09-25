import 'dart:convert';

import 'package:athan_app_v2/models/prayer_times.dart';
import 'package:athan_app_v2/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerService {
  static const String baseUrl = 'https://api.aladhan.com/v1/calendar';
  static const String _cachedLocationKey = 'cached_prayer_location';
  static const int yearsToCache = 7; // Cache 7 years of prayer times

  final ConnectivityService _connectivityService = ConnectivityService();

  Future<Position> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw Exception('Location permissions are denied');
    }

    // Use a timeout for location to avoid hanging indefinitely
    // Medium accuracy is usually enough and faster on mobile data
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Get cached location coordinates
  Future<Map<String, double>?> getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString(_cachedLocationKey);
    if (jsonData != null) {
      final data = json.decode(jsonData);
      return {
        'latitude': data['latitude'],
        'longitude': data['longitude'],
      };
    }
    return null;
  }

  /// Cache location coordinates
  Future<void> cacheLocation(double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _cachedLocationKey,
        json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }));
  }

  /// Fetch prayer times for a specific month, using cached location if offline
  Future<List<PrayerDay>> fetchPrayerTimes(int year, int month,
      {double? latitude, double? longitude}) async {
    try {
      double lat;
      double lng;

      if (latitude != null && longitude != null) {
        lat = latitude;
        lng = longitude;
      } else {
        final position = await getCurrentLocation();
        lat = position.latitude;
        lng = position.longitude;
        // Cache this location
        await cacheLocation(lat, lng);
      }

      final url = '$baseUrl/$year/$month?latitude=$lat&longitude=$lng';

      // Retry logic: try 3 times with exponential backoff
      int attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts) {
        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 15)); // Add timeout

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final List<dynamic> days = data['data'];
            return days.map((day) => PrayerDay.fromJson(day)).toList();
          } else {
            throw Exception(
                'Failed to load prayer times: ${response.statusCode}');
          }
        } catch (e) {
          attempts++;
          if (attempts == maxAttempts) rethrow;
          // Wait before retrying: 1s, 2s, etc.
          await Future.delayed(Duration(seconds: attempts));
        }
      }
      throw Exception('Failed to connect after $maxAttempts attempts');
    } catch (e) {
      throw Exception('Error fetching prayer times: $e');
    }
  }

  /// Fetch and cache 7 years of prayer times for offline use
  Future<void> fetchAndCacheAllYears(double latitude, double longitude,
      {Function(int current, int total)? onProgress}) async {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 1; // Include previous year
    final endYear = currentYear + yearsToCache - 1; // 7 years total

    int totalMonths = (endYear - startYear + 1) * 12;
    int currentMonth = 0;

    for (int year = startYear; year <= endYear; year++) {
      for (int month = 1; month <= 12; month++) {
        currentMonth++;
        onProgress?.call(currentMonth, totalMonths);

        final key = _getPrayerTimesKey(year, month, latitude, longitude);

        // Check if already cached
        final cached = await loadPrayerTimes(key);
        if (cached.isNotEmpty) {
          continue; // Skip if already cached
        }

        try {
          final prayerDays = await fetchPrayerTimes(year, month,
              latitude: latitude, longitude: longitude);
          await savePrayerTimes(prayerDays, key);

          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          // Continue with next month even if one fails
          debugPrint('Failed to fetch $year/$month: $e');
        }
      }
    }
  }

  /// Generate storage key based on year, month, and location
  String _getPrayerTimesKey(
      int year, int month, double latitude, double longitude) {
    // Round coordinates to 2 decimal places for reasonable caching area
    final latRounded = latitude.toStringAsFixed(2);
    final lngRounded = longitude.toStringAsFixed(2);
    return 'prayer_times_${year}_${month}_${latRounded}_$lngRounded';
  }

  /// Get prayer times for a month, trying cache first then online
  Future<List<PrayerDay>> getPrayerTimesForMonth(
      int year, int month, double latitude, double longitude) async {
    final key = _getPrayerTimesKey(year, month, latitude, longitude);

    // Try loading from cache first
    var prayerDays = await loadPrayerTimes(key);

    if (prayerDays.isEmpty) {
      // Check if online
      final isOnline = await _connectivityService.checkConnectivity();

      if (isOnline) {
        try {
          prayerDays = await fetchPrayerTimes(year, month,
              latitude: latitude, longitude: longitude);
          await savePrayerTimes(prayerDays, key);
        } catch (e) {
          throw Exception(
              'Failed to fetch prayer times and no cached data available');
        }
      } else {
        throw Exception(
            'No internet connection and no cached data for this month');
      }
    }

    return prayerDays;
  }

  Future<void> savePrayerTimes(List<PrayerDay> prayerDays, String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData =
        json.encode(prayerDays.map((day) => day.toJson()).toList());
    await prefs.setString(key, jsonData);
  }

  Future<List<PrayerDay>> loadPrayerTimes(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString(key);
    if (jsonData != null) {
      final List<dynamic> data = json.decode(jsonData);
      return data.map((json) => PrayerDay.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> clearPrayerTimes(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Clear all cached prayer times for a specific location
  Future<void> clearAllPrayerTimesForLocation(
      double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final latRounded = latitude.toStringAsFixed(2);
    final lngRounded = longitude.toStringAsFixed(2);

    for (final key in keys) {
      if (key.contains('prayer_times_') &&
          key.contains(latRounded) &&
          key.contains(lngRounded)) {
        await prefs.remove(key);
      }
    }
  }

  /// Check how much data is cached for a location
  /// Returns a map with 'cachedMonths', 'totalMonths', and 'isCached' (true if 100%)
  Future<Map<String, dynamic>> getCacheStatus(
      double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 1;
    final endYear = currentYear + yearsToCache - 1;
    final totalMonths = (endYear - startYear + 1) * 12;

    int cachedMonths = 0;

    for (int year = startYear; year <= endYear; year++) {
      for (int month = 1; month <= 12; month++) {
        final key = _getPrayerTimesKey(year, month, latitude, longitude);
        final data = prefs.getString(key);
        if (data != null && data.isNotEmpty) {
          cachedMonths++;
        }
      }
    }

    return {
      'cachedMonths': cachedMonths,
      'totalMonths': totalMonths,
      'isCached': cachedMonths == totalMonths,
      'yearsRange': '$startYear - $endYear',
    };
  }

  /// Check if any cached data exists for any location
  Future<bool> hasAnyCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    return keys.any((key) => key.startsWith('prayer_times_'));
  }
}
