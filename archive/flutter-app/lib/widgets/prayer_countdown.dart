import 'package:athan_app_v2/models/prayer_times.dart';
import 'package:athan_app_v2/services/settings_notifier.dart';
import 'package:athan_app_v2/theme.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

class PrayerCountdown extends StatefulWidget {
  final PrayerTimings timings;
  final Function(String)? onNextPrayerChanged;

  const PrayerCountdown({
    super.key,
    required this.timings,
    this.onNextPrayerChanged,
  });

  @override
  State<PrayerCountdown> createState() => _PrayerCountdownState();
}

class _PrayerCountdownState extends State<PrayerCountdown> {
  late Timer _timer;
  String _nextPrayer = '';
  String _remainingTime = '';
  String _previousNextPrayer = '';

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
    settingsNotifier.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _timer.cancel();
    settingsNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _updateCountdown();
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

  void _updateCountdown() {
    final now = DateTime.now();
    final adjustments = settingsNotifier.settings.timeAdjustments;

    final prayers = {
      'الفجر': _parseTime(
          _adjustTime(widget.timings.fajr, adjustments.fajrAdjustment)),
      'الظهر': _parseTime(
          _adjustTime(widget.timings.dhuhr, adjustments.dhuhrAdjustment)),
      'العصر': _parseTime(
          _adjustTime(widget.timings.asr, adjustments.asrAdjustment)),
      'المغرب': _parseTime(
          _adjustTime(widget.timings.maghrib, adjustments.maghribAdjustment)),
      'العشاء': _parseTime(
          _adjustTime(widget.timings.isha, adjustments.ishaAdjustment)),
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

    if (nextTime != null) {
      final difference = nextTime.difference(now);
      final hours = difference.inHours;
      final minutes = (difference.inMinutes % 60);
      final seconds = (difference.inSeconds % 60);

      if (mounted) {
        setState(() {
          if (_nextPrayer != nextPrayer && _previousNextPrayer.isNotEmpty) {
            // Next prayer changed, notify parent
            widget.onNextPrayerChanged?.call(nextPrayer);
          }
          _previousNextPrayer = _nextPrayer;
          _nextPrayer = nextPrayer;
          _remainingTime =
              '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        });
      }
    } else {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final tomorrowFajr = _parseTime(
          _adjustTime(widget.timings.fajr, adjustments.fajrAdjustment),
          tomorrow);
      final difference = tomorrowFajr.difference(now);

      if (mounted) {
        setState(() {
          if (_nextPrayer != 'الفجر' && _previousNextPrayer.isNotEmpty) {
            // Next prayer changed, notify parent
            widget.onNextPrayerChanged?.call('الفجر');
          }
          _previousNextPrayer = _nextPrayer;
          _nextPrayer = 'الفجر';
          _remainingTime =
              '${difference.inHours}:${(difference.inMinutes % 60).toString().padLeft(2, '0')}:${(difference.inSeconds % 60).toString().padLeft(2, '0')}';
        });
      }
    }
  }

  DateTime _parseTime(String time, [DateTime? date]) {
    final now = date ?? DateTime.now();
    final parts = time.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.liquidGlass(
        context,
        backgroundColor: colors.primary.withValues(alpha: 0.1),
      ),
      child: Column(
        children: [
          Text(
            'الوقت المتبقي حتى $_nextPrayer',
            style: AppTextStyles.titleMedium(context).copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            _remainingTime,
            style: AppTextStyles.code(context).copyWith(
              color: colors.primary,
              fontFamily: 'Qahiri',
              fontSize: 45.0,
            ),
          ),
        ],
      ),
    );
  }
}
