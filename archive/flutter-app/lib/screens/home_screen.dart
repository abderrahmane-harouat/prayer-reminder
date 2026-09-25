import 'dart:async';
import 'dart:ui' as ui;
import 'package:athan_app_v2/models/prayer_times.dart';
import 'package:athan_app_v2/services/connectivity_service.dart';
import 'package:athan_app_v2/services/location_service.dart';
import 'package:athan_app_v2/services/prayer_notitfication_service.dart';
import 'package:athan_app_v2/services/prayer_service.dart';
import 'package:athan_app_v2/services/settings_notifier.dart';
import 'package:athan_app_v2/theme.dart';
import 'package:athan_app_v2/utils/month_translations.dart';
import 'package:athan_app_v2/utils/prayer_icons.dart';
import 'package:athan_app_v2/widgets/prayer_countdown.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerService _prayerService = PrayerService();
  final LocationService _locationService = LocationService();
  final ConnectivityService _connectivityService = ConnectivityService();

  List<PrayerDay> _prayerDays = [];
  bool _isLoading = true;
  bool _isDownloading = false;
  int _downloadProgress = 0;
  int _downloadTotal = 0;
  DateTime _selectedDate = DateTime.now();
  String _currentNextPrayer = '';
  String _locationName = 'الموقع الحالي';
  bool _isOnline = true;
  double? _currentLatitude;
  double? _currentLongitude;

  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _initializeApp();
    settingsNotifier.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    settingsNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (kDebugMode) {
      debugPrint(
          '🔄 Settings changed in HomeScreen - Fajr adjustment: ${settingsNotifier.settings.timeAdjustments.fajrAdjustment}');
    }
    setState(() {});
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    _isOnline = _connectivityService.isOnline;

    _connectivitySubscription =
        _connectivityService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);

    // Initialize notifications first
    await PrayerNotificationService.initialize();

    // Try to load cached location first for instant offline startup
    final cachedLocation = await _locationService.getCurrentSavedLocation();

    if (cachedLocation != null) {
      // We have cached data - use it directly without fetching GPS
      _currentLatitude = cachedLocation['latitude'];
      _currentLongitude = cachedLocation['longitude'];
      if (mounted) {
        setState(() {
          _locationName = cachedLocation['name'] ?? 'الموقع الحالي';
        });
      }
      // Load prayer times from cache
      await _loadPrayerTimes();
    } else {
      // No cached data - need to fetch location (first time use)
      try {
        final position = await _locationService.determinePosition();
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;

        // Get and cache the location name
        final name = await _locationService.getPlaceName(
          position.latitude,
          position.longitude,
        );
        if (name != null) {
          await _locationService.saveCurrentLocation(
              position.latitude, position.longitude, name);
          await _locationService.cacheLocationName(name);
          if (mounted) {
            setState(() {
              _locationName = name;
            });
          }
        }

        // Load prayer times (will fetch from API since no cache)
        await _loadPrayerTimes();
      } catch (e) {
        // Location failed and no cache - show error
        setState(() => _isLoading = false);
        _showLocationRequiredDialog();
      }
    }
  }

  Future<void> _loadPrayerTimes() async {
    setState(() => _isLoading = true);
    try {
      final year = _selectedDate.year;
      final month = _selectedDate.month;

      // Get coordinates for loading prayer times
      double? lat = _currentLatitude;
      double? lng = _currentLongitude;

      // If no coordinates, try to get from cached location
      if (lat == null || lng == null) {
        final cachedLocation = await _locationService.getCurrentSavedLocation();
        if (cachedLocation != null) {
          lat = cachedLocation['latitude'];
          lng = cachedLocation['longitude'];
          _currentLatitude = lat;
          _currentLongitude = lng;
        }
      }

      List<PrayerDay> prayerDays = [];

      if (lat != null && lng != null) {
        // Use location-based caching
        try {
          prayerDays = await _prayerService.getPrayerTimesForMonth(
              year, month, lat, lng);
        } catch (e) {
          // If fetch fails, show error
          if (mounted) {
            setState(() => _isLoading = false);
            if (!_isOnline) {
              _showOfflineNoDataDialog();
            } else {
              _showLocationRequiredDialog();
            }
            return;
          }
        }
      } else {
        // No location available at all
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationRequiredDialog();
          return;
        }
      }

      await PrayerNotificationService.cancelAllNotifications();

      final now = DateTime.now();
      final todayPrayers = prayerDays.firstWhere(
        (day) => day.readableDate == intl.DateFormat('dd MMM yyyy').format(now),
        orElse: () => prayerDays.first,
      );

      if (_selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day) {
        await _scheduleTodaysPrayers(todayPrayers);
      }

      setState(() {
        _prayerDays = prayerDays;
        _isLoading = false;
        // Initialize current next prayer
        if (_selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day &&
            prayerDays.isNotEmpty) {
          _currentNextPrayer = _getNextPrayerName(todayPrayers.timings);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('خطأ'),
            content: Text('فشل تحميل مواقيت الصلاة: $e'),
            actions: [
              CupertinoDialogAction(
                child: Text('حسناً'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showLocationRequiredDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('الموقع مطلوب'),
        content:
            const Text('يرجى السماح بالوصول إلى الموقع لتحميل مواقيت الصلاة'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('تحديث الموقع'),
            onPressed: () {
              Navigator.pop(context);
              _updateLocation();
            },
          ),
        ],
      ),
    );
  }

  void _showOfflineNoDataDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('لا توجد بيانات'),
        content: const Text(
            'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة لهذا الشهر. يرجى الاتصال بالإنترنت لتحميل البيانات.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('حسناً'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleTodaysPrayers(PrayerDay prayerDay) async {
    final adjustments = settingsNotifier.settings.timeAdjustments;

    // Apply adjustments to prayer times
    final prayers = {
      'Fajr': (
        PrayerNames.arabic['Fajr']!,
        _adjustTime(prayerDay.timings.fajr, adjustments.fajrAdjustment)
      ),
      'Dhuhr': (
        PrayerNames.arabic['Dhuhr']!,
        _adjustTime(prayerDay.timings.dhuhr, adjustments.dhuhrAdjustment)
      ),
      'Asr': (
        PrayerNames.arabic['Asr']!,
        _adjustTime(prayerDay.timings.asr, adjustments.asrAdjustment)
      ),
      'Maghrib': (
        PrayerNames.arabic['Maghrib']!,
        _adjustTime(prayerDay.timings.maghrib, adjustments.maghribAdjustment)
      ),
      'Isha': (
        PrayerNames.arabic['Isha']!,
        _adjustTime(prayerDay.timings.isha, adjustments.ishaAdjustment)
      ),
    };

    // Cancel all existing notifications first
    await PrayerNotificationService.cancelAllNotifications();

    // Schedule notifications for each prayer
    for (var entry in prayers.entries) {
      final prayerName = entry.key;
      final arabicName = entry.value.$1;
      final timeString = entry.value.$2;

      final timeParts = timeString.split(':');
      final now = DateTime.now();
      final prayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Schedule notification 5 minutes before prayer time
      final notificationTime = prayerTime.subtract(Duration(minutes: 5));

      await PrayerNotificationService.schedulePrayerNotification(
        prayerName: prayerName,
        arabicName: arabicName,
        timeString: timeString,
        scheduledTime: notificationTime,
      );
    }

    // Log scheduled notifications count (no dialog to avoid annoyance)
    if (kDebugMode) {
      final scheduledNotifs =
          await PrayerNotificationService.getScheduledNotifications();
      debugPrint('✅ Scheduled ${scheduledNotifs.length} prayer notifications');
    }
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _loadPrayerTimes();
    });
  }

  String _getNextPrayerName(PrayerTimings timings) {
    final now = DateTime.now();
    final adjustments = settingsNotifier.settings.timeAdjustments;

    final prayers = {
      'الفجر':
          _parseTime(_adjustTime(timings.fajr, adjustments.fajrAdjustment)),
      'الظهر':
          _parseTime(_adjustTime(timings.dhuhr, adjustments.dhuhrAdjustment)),
      'العصر': _parseTime(_adjustTime(timings.asr, adjustments.asrAdjustment)),
      'المغرب': _parseTime(
          _adjustTime(timings.maghrib, adjustments.maghribAdjustment)),
      'العشاء':
          _parseTime(_adjustTime(timings.isha, adjustments.ishaAdjustment)),
    };

    String nextPrayer = '';
    DateTime? nextTime;

    for (var entry in prayers.entries) {
      if (entry.value.isAfter(now)) {
        if (nextTime == null || entry.value.isBefore(nextTime)) {
          nextPrayer = entry.key;
          nextTime = entry.value;
        }
      }
    }

    return nextPrayer;
  }

  DateTime _parseTime(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Adjusts a prayer time string by adding/subtracting minutes
  String _adjustTime(String time, int adjustmentMinutes) {
    if (adjustmentMinutes == 0) return time;

    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    final totalMinutes = hours * 60 + minutes + adjustmentMinutes;
    final adjustedHours = (totalMinutes ~/ 60) % 24;
    final adjustedMinutes = totalMinutes % 60;

    // Handle negative adjustments that go past midnight
    final actualHours = totalMinutes < 0 ? 24 + adjustedHours : adjustedHours;

    return '${actualHours.toString().padLeft(2, '0')}:${adjustedMinutes.abs().toString().padLeft(2, '0')}';
  }

  Widget _buildPrayerTimeRow(String name, String time, bool isNext) {
    return Builder(
      builder: (context) {
        final colors = AppColors.of(context);
        final iconData = PrayerIcons.getIconData(name);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: isNext
                ? BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                      width: 2.0,
                    ),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 28.0,
                      width: 28.0,
                      child: PrayerIcons.buildGradientIcon(
                        icon: iconData.icon,
                        gradient: iconData.gradient,
                        size: 28.0,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Text(
                      name,
                      style: AppTextStyles.headlineMedium(context).copyWith(
                        color: isNext ? colors.primary : colors.textPrimary,
                        fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: AppTextStyles.headlineMedium(context).copyWith(
                    fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    color: isNext ? colors.primary : colors.textPrimary,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 50,
              color: CupertinoColors.systemGrey6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('إلغاء'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text('تم'),
                    onPressed: () {
                      Navigator.pop(context);
                      _loadPrayerTimes();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime(2020, 1, 1),
                maximumDate: DateTime(2030, 12, 31),
                onDateTimeChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoading = true);
    try {
      // Get current position and name
      final position = await _locationService.determinePosition();
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      final name = await _locationService.getPlaceName(
          position.latitude, position.longitude);

      if (name != null) {
        await _locationService.saveCurrentLocation(
            position.latitude, position.longitude, name);
        await _locationService.cacheLocationName(name);
        if (mounted) {
          setState(() {
            _locationName = name;
          });
        }
      }

      if (mounted) {
        setState(() {
          _selectedDate = DateTime.now();
        });
      }

      await _loadPrayerTimes();

      if (mounted) {
        // Ask if user wants to download 7 years of data
        _showDownloadDataDialog(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('خطأ'),
            content: Text('فشل تحديث الموقع: $e'),
            actions: [
              CupertinoDialogAction(
                child: Text('حسناً'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showDownloadDataDialog(double latitude, double longitude) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تحميل البيانات للعمل بدون إنترنت'),
        content: const Text(
            'هل تريد تحميل مواقيت الصلاة لـ 7 سنوات للعمل بدون اتصال؟\n\nهذا قد يستغرق بضع دقائق.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('لاحقاً'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('تحميل الآن'),
            onPressed: () {
              Navigator.pop(context);
              _downloadAllYearsData(latitude, longitude);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAllYearsData(double latitude, double longitude) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadTotal = 0;
    });

    try {
      await _prayerService.fetchAndCacheAllYears(
        latitude,
        longitude,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = current;
              _downloadTotal = total;
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isDownloading = false);
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('تم التحميل'),
            content: const Text(
                'تم تحميل مواقيت الصلاة لـ 7 سنوات بنجاح. يمكنك الآن استخدام التطبيق بدون إنترنت.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('حسناً'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('خطأ'),
            content: Text('فشل تحميل البيانات: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('حسناً'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSavedLocationsDialog() async {
    final locations = await _locationService.getSavedLocations();

    if (!mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        color: AppColors.of(context).background,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.of(context).divider),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                    Text(
                      'المواقع المحفوظة',
                      style: AppTextStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 70), // Balance the layout
                  ],
                ),
              ),
              Expanded(
                child: locations.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد مواقع محفوظة',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final location = locations[index];
                          return CupertinoButton(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            onPressed: () {
                              Navigator.pop(context);
                              _selectSavedLocation(location);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.location_fill,
                                  color: AppColors.of(context).primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    location.name,
                                    style: AppTextStyles.bodyLarge(context),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_left,
                                  size: 16,
                                  color: AppColors.of(context).textTertiary,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectSavedLocation(SavedLocation location) async {
    setState(() => _isLoading = true);

    _currentLatitude = location.latitude;
    _currentLongitude = location.longitude;
    _locationName = location.name;

    await _locationService.saveCurrentLocation(
        location.latitude, location.longitude, location.name);
    await _locationService.cacheLocationName(location.name);

    setState(() {
      _selectedDate = DateTime.now();
    });

    await _loadPrayerTimes();
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'مواقيت الصلاة',
                    style: AppTextStyles.headlineLarge(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  // Online/Offline indicator dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isOnline
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.systemRed)
                              .withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: _showSavedLocationsDialog,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_fill,
                      size: 14,
                      color: AppColors.of(context).textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _locationName,
                      style: AppTextStyles.titleSmall(context).copyWith(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 12,
                      color: AppColors.of(context).textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildActionButton(
                icon: CupertinoIcons.location,
                onPressed: _updateLocation,
              ),
              SizedBox(width: AppSpacing.sm),
              _buildActionButton(
                icon: CupertinoIcons.calendar,
                onPressed: _showDatePicker,
              ),
              SizedBox(width: AppSpacing.sm),
              _buildActionButton(
                icon: CupertinoIcons.today,
                onPressed: _goToToday,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.all(10),
        onPressed: onPressed,
        minimumSize: Size(0, 0),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.of(context).textPrimary,
        ),
      ),
    );
  }

  Widget _buildDownloadingState() {
    final progress =
        _downloadTotal > 0 ? _downloadProgress / _downloadTotal : 0.0;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.cloud_download,
                size: 64,
                color: AppColors.of(context).primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'جاري تحميل البيانات...',
                style: AppTextStyles.headlineSmall(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'تحميل مواقيت الصلاة لـ 7 سنوات للعمل بدون إنترنت',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.of(context).cardBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.of(context).primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '$_downloadProgress / $_downloadTotal شهر',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: CupertinoPageScaffold(
        backgroundColor: colors.background,
        child: _isLoading
            ? Center(child: CupertinoActivityIndicator(radius: 20))
            : _isDownloading
                ? _buildDownloadingState()
                : SafeArea(
                    child: Column(
                      children: [
                        _buildCustomHeader(),
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              if (_prayerDays.isNotEmpty) ...[
                                if (_selectedDate.year == DateTime.now().year &&
                                    _selectedDate.month ==
                                        DateTime.now().month &&
                                    _selectedDate.day == DateTime.now().day)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      child: PrayerCountdown(
                                        timings:
                                            _prayerDays[_selectedDate.day - 1]
                                                .timings,
                                        onNextPrayerChanged: (nextPrayer) {
                                          setState(() {
                                            _currentNextPrayer = nextPrayer;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    child: Container(
                                      decoration:
                                          AppDecorations.liquidGlass(context),
                                      child: Padding(
                                        padding: EdgeInsets.all(AppSpacing.md),
                                        child: Column(
                                          children: [
                                            Builder(builder: (context) {
                                              // Apply hijri date adjustment
                                              final hijri = _prayerDays[
                                                      _selectedDate.day - 1]
                                                  .hijri;
                                              final adjustedDay =
                                                  int.parse(hijri.day) +
                                                      settingsNotifier.settings
                                                          .hijriDateAdjustment;
                                              return Text(
                                                '$adjustedDay ${MonthTranslations.getHijriMonth(hijri.monthEn)} ${hijri.year}',
                                                style: AppTextStyles.titleLarge(
                                                        context)
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textDirection:
                                                    ui.TextDirection.rtl,
                                              );
                                            }),
                                            SizedBox(height: AppSpacing.sm),
                                            Container(
                                              width: 100,
                                              height: 1,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.of(context)
                                                        .divider
                                                        .withValues(alpha: 0.0),
                                                    AppColors.of(context)
                                                        .divider,
                                                    AppColors.of(context)
                                                        .divider
                                                        .withValues(alpha: 0.0),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: AppSpacing.sm),
                                            Text(
                                              '${_selectedDate.day} ${MonthTranslations.getGregorianMonth(intl.DateFormat('MMMM').format(_selectedDate))} ${_selectedDate.year}',
                                              style: AppTextStyles.titleMedium(
                                                      context)
                                                  .copyWith(
                                                color: AppColors.of(context)
                                                    .textSecondary,
                                              ),
                                              textAlign: TextAlign.center,
                                              textDirection:
                                                  ui.TextDirection.rtl,
                                            ),
                                            SizedBox(height: AppSpacing.md),
                                            Builder(builder: (context) {
                                              final isToday = _selectedDate
                                                          .year ==
                                                      DateTime.now().year &&
                                                  _selectedDate.month ==
                                                      DateTime.now().month &&
                                                  _selectedDate.day ==
                                                      DateTime.now().day;
                                              final nextPrayer = isToday
                                                  ? _currentNextPrayer
                                                  : '';

                                              // Get time adjustments
                                              final adjustments =
                                                  settingsNotifier
                                                      .settings.timeAdjustments;

                                              if (kDebugMode) {
                                                debugPrint(
                                                    '🕐 Building prayer times with adjustments:');
                                                debugPrint(
                                                    '   Fajr: ${adjustments.fajrAdjustment} min');
                                                debugPrint(
                                                    '   Dhuhr: ${adjustments.dhuhrAdjustment} min');
                                                debugPrint(
                                                    '   Asr: ${adjustments.asrAdjustment} min');
                                                debugPrint(
                                                    '   Maghrib: ${adjustments.maghribAdjustment} min');
                                                debugPrint(
                                                    '   Isha: ${adjustments.ishaAdjustment} min');
                                              }

                                              // Get adjusted times
                                              final fajrTime = _adjustTime(
                                                _prayerDays[
                                                        _selectedDate.day - 1]
                                                    .timings
                                                    .fajr,
                                                adjustments.fajrAdjustment,
                                              );
                                              final dhuhrTime = _adjustTime(
                                                _prayerDays[
                                                        _selectedDate.day - 1]
                                                    .timings
                                                    .dhuhr,
                                                adjustments.dhuhrAdjustment,
                                              );
                                              final asrTime = _adjustTime(
                                                _prayerDays[
                                                        _selectedDate.day - 1]
                                                    .timings
                                                    .asr,
                                                adjustments.asrAdjustment,
                                              );
                                              final maghribTime = _adjustTime(
                                                _prayerDays[
                                                        _selectedDate.day - 1]
                                                    .timings
                                                    .maghrib,
                                                adjustments.maghribAdjustment,
                                              );
                                              final ishaTime = _adjustTime(
                                                _prayerDays[
                                                        _selectedDate.day - 1]
                                                    .timings
                                                    .isha,
                                                adjustments.ishaAdjustment,
                                              );

                                              return Column(
                                                children: [
                                                  _buildPrayerTimeRow(
                                                    'الفجر',
                                                    fajrTime,
                                                    isToday &&
                                                        nextPrayer == 'الفجر',
                                                  ),
                                                  _buildPrayerTimeRow(
                                                    'الظهر',
                                                    dhuhrTime,
                                                    isToday &&
                                                        nextPrayer == 'الظهر',
                                                  ),
                                                  _buildPrayerTimeRow(
                                                    'العصر',
                                                    asrTime,
                                                    isToday &&
                                                        nextPrayer == 'العصر',
                                                  ),
                                                  _buildPrayerTimeRow(
                                                    'المغرب',
                                                    maghribTime,
                                                    isToday &&
                                                        nextPrayer == 'المغرب',
                                                  ),
                                                  _buildPrayerTimeRow(
                                                    'العشاء',
                                                    ishaTime,
                                                    isToday &&
                                                        nextPrayer == 'العشاء',
                                                  ),
                                                ],
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
