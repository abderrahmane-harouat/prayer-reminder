import 'dart:ui' as ui;
import 'package:athan_app_v2/models/prayer_times.dart';
import 'package:athan_app_v2/models/settings.dart';
import 'package:athan_app_v2/services/location_service.dart';
import 'package:athan_app_v2/services/prayer_notitfication_service.dart';
import 'package:athan_app_v2/services/prayer_service.dart';
import 'package:athan_app_v2/services/settings_notifier.dart';
import 'package:athan_app_v2/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Divider, LinearProgressIndicator;
import 'package:intl/intl.dart' as intl;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PrayerService _prayerService = PrayerService();
  final LocationService _locationService = LocationService();
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  Map<String, dynamic>? _cacheStatus;
  String? _currentLocationName;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheStatus();
  }

  Future<void> _loadCacheStatus() async {
    final location = await _locationService.getCurrentSavedLocation();
    if (location != null) {
      final lat = location['latitude'] as double;
      final lng = location['longitude'] as double;
      final name = location['name'] as String?;
      final status = await _prayerService.getCacheStatus(lat, lng);
      if (mounted) {
        setState(() {
          _cacheStatus = status;
          _currentLocationName = name;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    await settingsNotifier.loadSettings();
    setState(() {
      _settings = settingsNotifier.settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (kDebugMode) {
      debugPrint('💾 Saving settings from SettingsScreen:');
      debugPrint(
          '   Fajr adjustment: ${_settings.timeAdjustments.fajrAdjustment}');
      debugPrint(
          '   Dhuhr adjustment: ${_settings.timeAdjustments.dhuhrAdjustment}');
      debugPrint(
          '   Asr adjustment: ${_settings.timeAdjustments.asrAdjustment}');
      debugPrint(
          '   Maghrib adjustment: ${_settings.timeAdjustments.maghribAdjustment}');
      debugPrint(
          '   Isha adjustment: ${_settings.timeAdjustments.ishaAdjustment}');
    }
    await settingsNotifier.saveSettings(_settings);
    await _updateNotifications();
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

  Future<void> _updateNotifications() async {
    // Cancel all existing notifications
    await PrayerNotificationService.cancelAllNotifications();

    // Re-schedule notifications with new settings
    final location = await _locationService.getCurrentSavedLocation();
    if (location == null) {
      if (kDebugMode) {
        debugPrint('⚠️ No saved location, cannot re-schedule notifications');
      }
      return;
    }

    final lat = location['latitude'] as double;
    final lng = location['longitude'] as double;

    // Get today's prayer times
    final now = DateTime.now();
    try {
      final prayerDays = await _prayerService.getPrayerTimesForMonth(
        now.year,
        now.month,
        lat,
        lng,
      );

      final todayPrayers = prayerDays.firstWhere(
        (day) => day.readableDate == intl.DateFormat('dd MMM yyyy').format(now),
        orElse: () => prayerDays.first,
      );

      // Apply time adjustments
      final adjustments = _settings.timeAdjustments;

      // Schedule notifications with updated settings and adjusted times
      final prayers = {
        'Fajr': (
          PrayerNames.arabic['Fajr']!,
          _adjustTime(todayPrayers.timings.fajr, adjustments.fajrAdjustment),
          _settings.fajrSettings
        ),
        'Dhuhr': (
          PrayerNames.arabic['Dhuhr']!,
          _adjustTime(todayPrayers.timings.dhuhr, adjustments.dhuhrAdjustment),
          _settings.dhuhrSettings
        ),
        'Asr': (
          PrayerNames.arabic['Asr']!,
          _adjustTime(todayPrayers.timings.asr, adjustments.asrAdjustment),
          _settings.asrSettings
        ),
        'Maghrib': (
          PrayerNames.arabic['Maghrib']!,
          _adjustTime(
              todayPrayers.timings.maghrib, adjustments.maghribAdjustment),
          _settings.maghribSettings
        ),
        'Isha': (
          PrayerNames.arabic['Isha']!,
          _adjustTime(todayPrayers.timings.isha, adjustments.ishaAdjustment),
          _settings.ishaSettings
        ),
      };

      for (var entry in prayers.entries) {
        final prayerName = entry.key;
        final arabicName = entry.value.$1;
        final timeString = entry.value.$2;
        final prayerSettings = entry.value.$3;

        // Skip if notifications are disabled for this prayer
        if (!prayerSettings.enabled) {
          if (kDebugMode) {
            debugPrint('⏭️ Skipping $prayerName - notifications disabled');
          }
          continue;
        }

        final timeParts = timeString.split(':');
        final prayerTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        final notificationTime = prayerTime.subtract(
          Duration(minutes: prayerSettings.prePrayerReminderMinutes),
        );

        await PrayerNotificationService.schedulePrayerNotification(
          prayerName: prayerName,
          arabicName: arabicName,
          timeString: timeString,
          scheduledTime: notificationTime,
        );
      }

      if (kDebugMode) {
        final scheduledNotifs =
            await PrayerNotificationService.getScheduledNotifications();
        debugPrint(
            '✅ Re-scheduled ${scheduledNotifs.length} prayer notifications with updated settings');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error re-scheduling notifications: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (_isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: CupertinoPageScaffold(
        backgroundColor: colors.background,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildHijriAdjustmentSection()),
              SliverToBoxAdapter(child: _buildPrayerTimeAdjustmentSection()),
              SliverToBoxAdapter(child: _buildOfflineDataSection()),
              SliverToBoxAdapter(child: _buildNotificationSettingsSection()),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: AppTextStyles.headlineLarge(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'تخصيص إشعارات الصلاة',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.of(context).textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHijriAdjustmentSection() {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.moon,
                  color: colors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'تعديل التاريخ الهجري',
                  style: AppTextStyles.titleMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            decoration: AppDecorations.liquidGlass(context),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بعض الدول قد تختلف في بداية الشهر الهجري. يمكنك تعديل التاريخ الهجري بإضافة أو طرح أيام.',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Decrease button
                    CupertinoButton(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      onPressed: _settings.hijriDateAdjustment > -2
                          ? () {
                              setState(() {
                                _settings = _settings.copyWith(
                                  hijriDateAdjustment:
                                      _settings.hijriDateAdjustment - 1,
                                );
                              });
                              _saveSettings();
                            }
                          : null,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Icon(
                          CupertinoIcons.minus,
                          color: _settings.hijriDateAdjustment > -2
                              ? colors.primary
                              : colors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Current adjustment value
                    Container(
                      constraints: const BoxConstraints(minWidth: 80),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _settings.hijriDateAdjustment == 0
                            ? 'بدون تعديل'
                            : '${_settings.hijriDateAdjustment > 0 ? '+' : ''}${_settings.hijriDateAdjustment} يوم',
                        style: AppTextStyles.titleSmall(context).copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Increase button
                    CupertinoButton(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      onPressed: _settings.hijriDateAdjustment < 2
                          ? () {
                              setState(() {
                                _settings = _settings.copyWith(
                                  hijriDateAdjustment:
                                      _settings.hijriDateAdjustment + 1,
                                );
                              });
                              _saveSettings();
                            }
                          : null,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Icon(
                          CupertinoIcons.add,
                          color: _settings.hijriDateAdjustment < 2
                              ? colors.primary
                              : colors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeAdjustmentSection() {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  color: colors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'تعديل أوقات الصلاة',
                  style: AppTextStyles.titleMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            decoration: AppDecorations.liquidGlass(context),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إذا كانت أوقات الصلاة غير دقيقة، يمكنك تعديلها يدوياً بإضافة أو طرح دقائق.',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Prayer time adjustment rows
                _buildPrayerTimeAdjustmentRow(
                  prayerName: 'Fajr',
                  title: 'الفجر',
                  adjustment: _settings.timeAdjustments.fajrAdjustment,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        timeAdjustments: _settings.timeAdjustments.copyWith(
                          fajrAdjustment: value,
                        ),
                      );
                    });
                    _saveSettings();
                  },
                ),
                Divider(height: 1, color: colors.divider),
                _buildPrayerTimeAdjustmentRow(
                  prayerName: 'Dhuhr',
                  title: 'الظهر',
                  adjustment: _settings.timeAdjustments.dhuhrAdjustment,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        timeAdjustments: _settings.timeAdjustments.copyWith(
                          dhuhrAdjustment: value,
                        ),
                      );
                    });
                    _saveSettings();
                  },
                ),
                Divider(height: 1, color: colors.divider),
                _buildPrayerTimeAdjustmentRow(
                  prayerName: 'Asr',
                  title: 'العصر',
                  adjustment: _settings.timeAdjustments.asrAdjustment,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        timeAdjustments: _settings.timeAdjustments.copyWith(
                          asrAdjustment: value,
                        ),
                      );
                    });
                    _saveSettings();
                  },
                ),
                Divider(height: 1, color: colors.divider),
                _buildPrayerTimeAdjustmentRow(
                  prayerName: 'Maghrib',
                  title: 'المغرب',
                  adjustment: _settings.timeAdjustments.maghribAdjustment,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        timeAdjustments: _settings.timeAdjustments.copyWith(
                          maghribAdjustment: value,
                        ),
                      );
                    });
                    _saveSettings();
                  },
                ),
                Divider(height: 1, color: colors.divider),
                _buildPrayerTimeAdjustmentRow(
                  prayerName: 'Isha',
                  title: 'العشاء',
                  adjustment: _settings.timeAdjustments.ishaAdjustment,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        timeAdjustments: _settings.timeAdjustments.copyWith(
                          ishaAdjustment: value,
                        ),
                      );
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeAdjustmentRow({
    required String prayerName,
    required String title,
    required int adjustment,
    required Function(int) onChanged,
  }) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Prayer name
          SizedBox(
            width: 60,
            child: Text(
              title,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Decrease button
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            minimumSize: Size.zero,
            onPressed:
                adjustment > -30 ? () => onChanged(adjustment - 1) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider),
              ),
              child: Icon(
                CupertinoIcons.minus,
                size: 16,
                color: adjustment > -30 ? colors.primary : colors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Current adjustment value
          Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: adjustment == 0
                  ? colors.surface
                  : colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: adjustment == 0
                    ? colors.divider
                    : colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              adjustment == 0 ? '0' : '${adjustment > 0 ? '+' : ''}$adjustment',
              style: AppTextStyles.labelMedium(context).copyWith(
                color: adjustment == 0 ? colors.textSecondary : colors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Increase button
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            minimumSize: Size.zero,
            onPressed: adjustment < 30 ? () => onChanged(adjustment + 1) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider),
              ),
              child: Icon(
                CupertinoIcons.add,
                size: 16,
                color: adjustment < 30 ? colors.primary : colors.textTertiary,
              ),
            ),
          ),
          const Spacer(),
          // Minutes label
          Text(
            'دقيقة',
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineDataSection() {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.cloud_download,
                  color: colors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'بيانات أوقات الصلاة المحفوظة',
                  style: AppTextStyles.titleMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            decoration: AppDecorations.liquidGlass(context),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_cacheStatus == null) ...[
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle,
                        color: colors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'لم يتم حفظ بيانات أوقات الصلاة بعد',
                          style: AppTextStyles.bodyMedium(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'اضغط على أيقونة الموقع في الشاشة الرئيسية ثم اختر "تحميل بيانات 7 سنوات" للعمل بدون إنترنت',
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: colors.textSecondary),
                  ),
                ] else ...[
                  // Location name
                  if (_currentLocationName != null) ...[
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          color: colors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _currentLocationName!,
                          style: AppTextStyles.bodyLarge(
                            context,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Cache status
                  Row(
                    children: [
                      Icon(
                        _cacheStatus!['isCached'] == true
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.clock,
                        color: _cacheStatus!['isCached'] == true
                            ? colors.success
                            : colors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _cacheStatus!['isCached'] == true
                              ? 'تم حفظ بيانات 7 سنوات كاملة ✓'
                              : 'تم حفظ ${_cacheStatus!['cachedMonths']} من ${_cacheStatus!['totalMonths']} شهر',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: _cacheStatus!['isCached'] == true
                                ? colors.success
                                : colors.textPrimary,
                            fontWeight: _cacheStatus!['isCached'] == true
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Years range
                  Text(
                    'الفترة: ${_cacheStatus!['yearsRange']}',
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: colors.textSecondary),
                  ),

                  // Progress bar if not complete
                  if (_cacheStatus!['isCached'] != true) ...[
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_cacheStatus!['cachedMonths'] as int) /
                            (_cacheStatus!['totalMonths'] as int),
                        backgroundColor: colors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsSection() {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(CupertinoIcons.bell, color: colors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'إعدادات الإشعارات',
                  style: AppTextStyles.titleMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            decoration: AppDecorations.liquidGlass(context),
            child: Column(
              children: [
                _buildPrayerNotificationTile(
                  prayerName: 'Fajr',
                  title: 'صلاة الفجر',
                  settings: _settings.fajrSettings,
                  onChanged: (newSettings) {
                    setState(() {
                      _settings = _settings.copyWith(fajrSettings: newSettings);
                    });
                    _saveSettings();
                  },
                ),
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  color: colors.divider,
                ),
                _buildPrayerNotificationTile(
                  prayerName: 'Dhuhr',
                  title: 'صلاة الظهر',
                  settings: _settings.dhuhrSettings,
                  onChanged: (newSettings) {
                    setState(() {
                      _settings = _settings.copyWith(
                        dhuhrSettings: newSettings,
                      );
                    });
                    _saveSettings();
                  },
                ),
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  color: colors.divider,
                ),
                _buildPrayerNotificationTile(
                  prayerName: 'Asr',
                  title: 'صلاة العصر',
                  settings: _settings.asrSettings,
                  onChanged: (newSettings) {
                    setState(() {
                      _settings = _settings.copyWith(asrSettings: newSettings);
                    });
                    _saveSettings();
                  },
                ),
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  color: colors.divider,
                ),
                _buildPrayerNotificationTile(
                  prayerName: 'Maghrib',
                  title: 'صلاة المغرب',
                  settings: _settings.maghribSettings,
                  onChanged: (newSettings) {
                    setState(() {
                      _settings = _settings.copyWith(
                        maghribSettings: newSettings,
                      );
                    });
                    _saveSettings();
                  },
                ),
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  color: colors.divider,
                ),
                _buildPrayerNotificationTile(
                  prayerName: 'Isha',
                  title: 'صلاة العشاء',
                  settings: _settings.ishaSettings,
                  onChanged: (newSettings) {
                    setState(() {
                      _settings = _settings.copyWith(ishaSettings: newSettings);
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerNotificationTile({
    required String prayerName,
    required String title,
    required PrayerNotificationSettings settings,
    required Function(PrayerNotificationSettings) onChanged,
  }) {
    final colors = AppColors.of(context);

    return CupertinoButton(
      padding: const EdgeInsets.all(AppSpacing.md),
      onPressed: () => _showNotificationSettingsDialog(
        prayerName,
        title,
        settings,
        onChanged,
      ),
      child: Row(
        children: [
          CupertinoSwitch(
            value: settings.enabled,
            onChanged: (value) {
              onChanged(settings.copyWith(enabled: value));
            },
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge(context)),
                if (settings.enabled)
                  Text(
                    'تنبيه قبل ${settings.prePrayerReminderMinutes} دقيقة',
                    style: AppTextStyles.caption(context),
                  ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_left,
            size: 16,
            color: colors.textTertiary,
          ),
        ],
      ),
    );
  }

  void _showNotificationSettingsDialog(
    String prayerName,
    String title,
    PrayerNotificationSettings settings,
    Function(PrayerNotificationSettings) onChanged,
  ) {
    int prePrayerReminder = settings.prePrayerReminderMinutes;
    bool enabled = settings.enabled;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 350,
          color: AppColors.of(context).background,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
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
                        child: const Text('إلغاء'),
                      ),
                      Text(
                        title,
                        style: AppTextStyles.titleMedium(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      CupertinoButton(
                        onPressed: () {
                          onChanged(
                            PrayerNotificationSettings(
                              enabled: enabled,
                              prePrayerReminderMinutes: prePrayerReminder,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        child: Text(
                          'حفظ',
                          style: TextStyle(
                            color: AppColors.of(context).primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: AppDecorations.cleanCard(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تفعيل الإشعارات',
                              style: AppTextStyles.bodyLarge(context),
                            ),
                            CupertinoSwitch(
                              value: enabled,
                              onChanged: (value) {
                                setModalState(() => enabled = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (enabled) ...[
                        Text(
                          'وقت التنبيه قبل الصلاة',
                          style: AppTextStyles.titleSmall(
                            context,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: AppDecorations.cleanCard(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سيتم إرسال إشعار قبل $prePrayerReminder دقيقة من وقت الصلاة',
                                style: AppTextStyles.bodyMedium(context),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              CupertinoSlider(
                                value: prePrayerReminder.toDouble(),
                                min: 0,
                                max: 60,
                                divisions: 12,
                                onChanged: (value) {
                                  setModalState(() {
                                    prePrayerReminder = value.round();
                                  });
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '0 د',
                                    style: AppTextStyles.caption(context),
                                  ),
                                  Text(
                                    '$prePrayerReminder دقيقة',
                                    style: AppTextStyles.bodyMedium(context)
                                        .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.of(context).primary,
                                    ),
                                  ),
                                  Text(
                                    '60 د',
                                    style: AppTextStyles.caption(context),
                                  ),
                                ],
                              ),
                            ],
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
      ),
    );
  }
}
