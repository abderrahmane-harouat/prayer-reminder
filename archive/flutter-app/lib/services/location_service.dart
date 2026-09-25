import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedLocation {
  final String name;
  final double latitude;
  final double longitude;
  final DateTime savedAt;

  SavedLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        name: json['name'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        savedAt: DateTime.parse(json['savedAt']),
      );
}

class LocationService {
  static const String _locationNameKey = 'cached_location_name';
  static const String _savedLocationsKey = 'saved_locations';
  static const String _currentLocationKey = 'current_location';

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  /// Get the placemark (address) from coordinates.
  Future<String?> getPlaceName(double latitude, double longitude) async {
    try {
      try {
        await setLocaleIdentifier('ar');
      } catch (e) {
        debugPrint('Error setting locale identifier: $e');
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct a meaningful location name, e.g., "City, Country"
        // or just "City" or "Sublocality, Locality"
        String? locality = place.locality; // City
        String? administrativeArea = place.administrativeArea; // State/Province
        String? country = place.country;

        // Fallback logic to get the most relevant name
        if (locality != null && locality.isNotEmpty) {
          return locality;
        } else if (administrativeArea != null &&
            administrativeArea.isNotEmpty) {
          return administrativeArea;
        } else if (country != null && country.isNotEmpty) {
          return country;
        }
        return place.name;
      }
    } catch (e) {
      debugPrint('Error getting placemark: $e');
    }
    return null;
  }

  /// Cache the location name.
  Future<void> cacheLocationName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationNameKey, name);
  }

  /// Get the cached location name.
  Future<String?> getCachedLocationName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locationNameKey);
  }

  /// Save a location to the saved locations list
  Future<void> saveLocation(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getSavedLocations();

    // Check if location already exists (by coordinates, rounded to 2 decimals)
    final existingIndex = locations.indexWhere((loc) =>
        loc.latitude.toStringAsFixed(2) ==
            location.latitude.toStringAsFixed(2) &&
        loc.longitude.toStringAsFixed(2) ==
            location.longitude.toStringAsFixed(2));

    if (existingIndex >= 0) {
      // Update existing location
      locations[existingIndex] = location;
    } else {
      // Add new location
      locations.add(location);
    }

    final jsonData = json.encode(locations.map((l) => l.toJson()).toList());
    await prefs.setString(_savedLocationsKey, jsonData);
  }

  /// Get all saved locations
  Future<List<SavedLocation>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_savedLocationsKey);

    if (jsonData == null || jsonData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> data = json.decode(jsonData);
      return data.map((json) => SavedLocation.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a saved location
  Future<void> deleteLocation(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getSavedLocations();

    locations.removeWhere((loc) =>
        loc.latitude.toStringAsFixed(2) ==
            location.latitude.toStringAsFixed(2) &&
        loc.longitude.toStringAsFixed(2) ==
            location.longitude.toStringAsFixed(2));

    final jsonData = json.encode(locations.map((l) => l.toJson()).toList());
    await prefs.setString(_savedLocationsKey, jsonData);
  }

  /// Save current location (coordinates + name) for offline use
  Future<void> saveCurrentLocation(
      double latitude, double longitude, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _currentLocationKey,
        json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'name': name,
        }));

    // Also save to saved locations list
    await saveLocation(SavedLocation(
      name: name,
      latitude: latitude,
      longitude: longitude,
      savedAt: DateTime.now(),
    ));
  }

  /// Get current saved location for offline use
  Future<Map<String, dynamic>?> getCurrentSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_currentLocationKey);

    if (jsonData != null) {
      return json.decode(jsonData);
    }
    return null;
  }
}
