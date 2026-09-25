import 'package:athan_app_v2/models/prayer_times.dart';
import 'package:athan_app_v2/theme.dart';
import 'package:flutter/cupertino.dart';

class PrayerCard extends StatefulWidget {
  final PrayerDay prayerDay;
  final String nextPrayerInfo;
  final bool isToday;

  const PrayerCard({
    super.key,
    required this.prayerDay,
    required this.nextPrayerInfo,
    required this.isToday,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecorations.liquidGlass(context),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isToday ? 'اليوم' : 'غداً',
                  style: AppTextStyles.titleLarge(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.prayerDay.hijri.day} ${widget.prayerDay.hijri.monthEn} ${widget.prayerDay.hijri.year}',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            if (widget.isToday) ...[
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: AppDecorations.cleanCard(
                  context,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.timer,
                      color: colors.primary,
                      size: AppIconSizes.md,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      widget.nextPrayerInfo,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppSpacing.md),
            _buildPrayerTimeRow(
              PrayerNames.arabic['Fajr']!,
              widget.prayerDay.timings.fajr,
            ),
            _buildPrayerTimeRow(
              PrayerNames.arabic['Dhuhr']!,
              widget.prayerDay.timings.dhuhr,
            ),
            _buildPrayerTimeRow(
              PrayerNames.arabic['Asr']!,
              widget.prayerDay.timings.asr,
            ),
            _buildPrayerTimeRow(
              PrayerNames.arabic['Maghrib']!,
              widget.prayerDay.timings.maghrib,
            ),
            _buildPrayerTimeRow(
              PrayerNames.arabic['Isha']!,
              widget.prayerDay.timings.isha,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeRow(String name, String time) {
    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: AppTextStyles.titleMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                time,
                style: AppTextStyles.titleMedium(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
