import 'dart:ui' as ui;
import 'package:athan_app_v2/models/prayer_times.dart';
import 'package:athan_app_v2/models/recitation_plan.dart';
import 'package:athan_app_v2/services/location_service.dart';
import 'package:athan_app_v2/services/prayer_service.dart';
import 'package:athan_app_v2/services/settings_notifier.dart';
import 'package:athan_app_v2/services/storage_service.dart';
import 'package:athan_app_v2/theme.dart';
import 'package:athan_app_v2/utils/month_translations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;

class RecitationPlanScreen extends StatefulWidget {
  const RecitationPlanScreen({super.key});

  @override
  State<RecitationPlanScreen> createState() => _RecitationPlanScreenState();
}

class _RecitationPlanScreenState extends State<RecitationPlanScreen> {
  final StorageService _storageService = StorageService();
  final PrayerService _prayerService = PrayerService();
  final LocationService _locationService = LocationService();
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  MonthlyRecitationPlan? _monthlyPlan;
  List<PrayerDay> _prayerDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    settingsNotifier.addListener(_onSettingsChanged);
    _loadData();
  }

  @override
  void dispose() {
    settingsNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadMonthlyPlan(),
      _loadPrayerDays(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadMonthlyPlan() async {
    final plan = await _storageService.getMonthlyPlan(
        _currentMonth.year, _currentMonth.month);
    setState(() {
      _monthlyPlan = plan;
    });
  }

  Future<void> _loadPrayerDays() async {
    try {
      // Use LocationService like the home screen does
      final cachedLocation = await _locationService.getCurrentSavedLocation();
      if (cachedLocation != null) {
        final days = await _prayerService.getPrayerTimesForMonth(
          _currentMonth.year,
          _currentMonth.month,
          cachedLocation['latitude']!,
          cachedLocation['longitude']!,
        );
        if (mounted) {
          setState(() {
            _prayerDays = days;
          });
        }
      }
    } catch (e) {
      // Silently fail - hijri date will not be shown
    }
  }

  Future<void> _saveDailyPlan(DailyRecitationPlan dailyPlan) async {
    await _storageService.saveDailyPlan(_selectedDate, dailyPlan);
    await _loadMonthlyPlan();
    setState(() {});
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
    _loadData();
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        body: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    _buildMonthHeader(context),
                    _buildCalendarGrid(context),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildDailyPlanList(context),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final colors = AppColors.of(context);
    final monthName = MonthTranslations.getMonthName(_currentMonth.month);
    final year = _currentMonth.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _previousMonth,
            child: Icon(
              CupertinoIcons.chevron_right,
              color: colors.primary,
              size: 28,
            ),
          ),
          Text(
            '$monthName $year',
            style: AppTextStyles.headlineMedium(context),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _nextMonth,
            child: Icon(
              CupertinoIcons.chevron_left,
              color: colors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final colors = AppColors.of(context);
    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    // 0 = Saturday, 1 = Sunday, ..., 6 = Friday (for Arabic calendar)
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cleanCard(context),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth + firstWeekday,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return const SizedBox();
              }
              final day = index - firstWeekday + 1;
              final date =
                  DateTime(_currentMonth.year, _currentMonth.month, day);
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;

              // Check if this day has a recitation plan
              final dailyPlan = _monthlyPlan?.getDailyPlan(date);
              final hasPlan = dailyPlan?.isNotEmpty ?? false;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                child: CustomPaint(
                  painter: isToday && !isSelected
                      ? DashedBorderPainter(
                          color: colors.primary,
                          strokeWidth: 1.5,
                          dashWidth: 4.0,
                          dashGap: 3.0,
                          radius: 8.0,
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.15)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: colors.primary.withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$day',
                            style: AppTextStyles.labelMedium(context).copyWith(
                              color: isSelected
                                  ? colors.primary
                                  : colors.textPrimary,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ),
                        ),
                        // Mark for days with recitation plans
                        if (hasPlan)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary
                                    : colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPlanList(BuildContext context) {
    final colors = AppColors.of(context);
    final dailyPlan = _monthlyPlan?.getDailyPlan(_selectedDate) ??
        DailyRecitationPlan.empty(_selectedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppDecorations.cleanCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: AppTextStyles.titleMedium(context),
                    ),
                    if (_getHijriDate(_selectedDate).isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${_getHijriDate(_selectedDate)})',
                        style: AppTextStyles.labelMedium(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (dailyPlan.isNotEmpty)
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    onPressed: () => _showClearConfirmation(context, dailyPlan),
                    child: Text(
                      'مسح الكل',
                      style: AppTextStyles.labelMedium(context).copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: DailyRecitationPlan.prayerOrder.length,
              itemBuilder: (context, index) {
                final prayerName = DailyRecitationPlan.prayerOrder[index];
                final prayerPlan = dailyPlan.prayers[prayerName]!;
                return _buildPrayerCard(context, prayerPlan, dailyPlan);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final monthName = MonthTranslations.getMonthName(date.month);
    final year = date.year;
    return '$day $monthName $year';
  }

  String _getHijriDate(DateTime date) {
    final dayIndex = date.day - 1;
    if (dayIndex >= 0 && dayIndex < _prayerDays.length) {
      final prayerDay = _prayerDays[dayIndex];
      final hijriMonth =
          MonthTranslations.getHijriMonth(prayerDay.hijri.monthEn);
      // Apply hijri date adjustment
      final adjustedDay = int.parse(prayerDay.hijri.day) +
          settingsNotifier.settings.hijriDateAdjustment;
      return '$adjustedDay $hijriMonth ${prayerDay.hijri.year}';
    }
    return '';
  }

  Widget _buildPrayerCard(BuildContext context, PrayerRecitationPlan prayerPlan,
      DailyRecitationPlan dailyPlan) {
    final colors = AppColors.of(context);
    final arabicName =
        DailyRecitationPlan.prayerArabicNames[prayerPlan.prayerName] ??
            prayerPlan.prayerName;
    final hasPlan = prayerPlan.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasPlan
            ? colors.primary.withValues(alpha: 0.1)
            : colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPlan
              ? colors.primary.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: 0.3),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showPrayerPlanEditor(context, prayerPlan, dailyPlan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPrayerIcon(prayerPlan.prayerName),
                        color: hasPlan ? colors.primary : colors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        arabicName,
                        style: AppTextStyles.titleSmall(context).copyWith(
                          color: hasPlan ? colors.primary : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasPlan
                              ? colors.primary.withValues(alpha: 0.2)
                              : colors.textTertiary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${prayerPlan.rakaCount} ركعات',
                          style: AppTextStyles.labelSmall(context).copyWith(
                            color:
                                hasPlan ? colors.primary : colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.chevron_left,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
              if (hasPlan) ...[
                const SizedBox(height: 12),
                ...prayerPlan.rakas
                    .asMap()
                    .entries
                    .where((e) => e.value.isNotEmpty)
                    .map((entry) {
                  final rakaIndex = entry.key;
                  final raka = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          'الركعة ${rakaIndex + 1}:',
                          style: AppTextStyles.labelSmall(context).copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            raka.surahName,
                            style: AppTextStyles.labelMedium(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'اضغط لإضافة خطة التلاوة',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return CupertinoIcons.sunrise;
      case 'Dhuhr':
        return CupertinoIcons.sun_max;
      case 'Asr':
        return CupertinoIcons.sunset;
      case 'Maghrib':
        return CupertinoIcons.moon;
      case 'Isha':
        return CupertinoIcons.moon_stars;
      default:
        return CupertinoIcons.circle;
    }
  }

  void _showPrayerPlanEditor(BuildContext context,
      PrayerRecitationPlan prayerPlan, DailyRecitationPlan dailyPlan) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => PrayerPlanEditorSheet(
        prayerPlan: prayerPlan,
        onSave: (updatedPlan) {
          final newPrayers =
              Map<String, PrayerRecitationPlan>.from(dailyPlan.prayers);
          newPrayers[prayerPlan.prayerName] = updatedPlan;
          final newDailyPlan = dailyPlan.copyWith(prayers: newPrayers);
          _saveDailyPlan(newDailyPlan);
        },
      ),
    );
  }

  void _showClearConfirmation(
      BuildContext context, DailyRecitationPlan dailyPlan) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('مسح خطة اليوم'),
        content: const Text('هل أنت متأكد من مسح جميع خطط التلاوة لهذا اليوم؟'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _saveDailyPlan(DailyRecitationPlan.empty(_selectedDate));
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }
}

class PrayerPlanEditorSheet extends StatefulWidget {
  final PrayerRecitationPlan prayerPlan;
  final Function(PrayerRecitationPlan) onSave;

  const PrayerPlanEditorSheet({
    super.key,
    required this.prayerPlan,
    required this.onSave,
  });

  @override
  State<PrayerPlanEditorSheet> createState() => _PrayerPlanEditorSheetState();
}

class _PrayerPlanEditorSheetState extends State<PrayerPlanEditorSheet> {
  late List<TextEditingController> _surahControllers;
  late List<TextEditingController> _notesControllers;

  @override
  void initState() {
    super.initState();
    _surahControllers = widget.prayerPlan.rakas
        .map((r) => TextEditingController(text: r.surahName))
        .toList();
    _notesControllers = widget.prayerPlan.rakas
        .map((r) => TextEditingController(text: r.notes))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _surahControllers) {
      controller.dispose();
    }
    for (var controller in _notesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final arabicName =
        DailyRecitationPlan.prayerArabicNames[widget.prayerPlan.prayerName] ??
            widget.prayerPlan.prayerName;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.divider),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'إلغاء',
                      style: AppTextStyles.labelMedium(context).copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                  Text(
                    'خطة $arabicName',
                    style: AppTextStyles.titleMedium(context),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _savePlan,
                    child: Text(
                      'حفظ',
                      style: AppTextStyles.labelMedium(context).copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Raka editors
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.prayerPlan.rakaCount,
                itemBuilder: (context, index) {
                  return _buildRakaEditor(context, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRakaEditor(BuildContext context, int index) {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cleanCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.labelMedium(context).copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الركعة ${index + 1}',
                style: AppTextStyles.titleSmall(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Surah name field
          Text(
            'اسم السورة',
            style: AppTextStyles.labelSmall(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _surahControllers[index],
            placeholder: 'مثال: سورة البقرة',
            style: AppTextStyles.bodyMedium(context),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 12),
          // Notes field
          Text(
            'ملاحظات (اختياري)',
            style: AppTextStyles.labelSmall(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _notesControllers[index],
            placeholder: 'مثال: من الآية 1 إلى 10',
            style: AppTextStyles.bodyMedium(context),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(12),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  void _savePlan() {
    final rakas = List.generate(
      widget.prayerPlan.rakaCount,
      (index) => RakaPlan(
        surahName: _surahControllers[index].text.trim(),
        notes: _notesControllers[index].text.trim(),
      ),
    );

    final updatedPlan = widget.prayerPlan.copyWith(rakas: rakas);
    widget.onSave(updatedPlan);
    Navigator.pop(context);
  }
}

/// Custom painter for drawing dashed borders
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashGap = 3.0,
    this.radius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final dashPattern = [dashWidth, dashGap];
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;

      while (distance < metric.length) {
        final length = dashPattern[draw ? 0 : 1];
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.radius != radius;
  }
}
