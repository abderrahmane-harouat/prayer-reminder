# Theme Usage Guide

Quick reference for using the new context-aware design system.

## Colors

```dart
// Get colors for current theme
final colors = AppColors.of(context);

// Use colors
Container(
  color: colors.background,
  child: Text(
    'Hello',
    style: TextStyle(color: colors.textPrimary),
  ),
)
```

### Available Colors

**Primary Colors:**
- `colors.primary` - Main brand color (blue)
- `colors.primaryLight` - Lighter variant
- `colors.primaryDark` - Darker variant
- `colors.secondary` - Secondary color (green)
- `colors.accent` - Accent color (orange)

**Backgrounds:**
- `colors.background` - Main background
- `colors.surface` - Card/surface background
- `colors.cardBackground` - Card background

**Glass Effects:**
- `colors.glassBackground` - Translucent background
- `colors.glassBorder` - Glass border color
- `colors.glassHighlight` - Glass highlight

**Text Colors:**
- `colors.textPrimary` - Main text (adapts to theme)
- `colors.textSecondary` - Secondary text
- `colors.textTertiary` - Tertiary text
- `colors.textDisabled` - Disabled text

**Status Colors:**
- `colors.success` - Success state (green)
- `colors.warning` - Warning state (yellow)
- `colors.error` - Error state (red)
- `colors.info` - Info state (blue)

**Interactive:**
- `colors.divider` - Divider lines
- `colors.border` - Border color

## Typography

```dart
// All text styles require context
Text('Display', style: AppTextStyles.displayLarge(context))
Text('Headline', style: AppTextStyles.headlineLarge(context))
Text('Title', style: AppTextStyles.titleLarge(context))
Text('Body', style: AppTextStyles.bodyLarge(context))
Text('Label', style: AppTextStyles.labelLarge(context))
Text('Code', style: AppTextStyles.code(context))
Text('Button', style: AppTextStyles.button(context))
Text('Caption', style: AppTextStyles.caption(context))
```

### Text Style Sizes

**Display:** `displayLarge` (40px), `displayMedium` (32px)
**Headline:** `headlineLarge` (24px), `headlineMedium` (20px), `headlineSmall` (19px)
**Title:** `titleLarge` (18px), `titleMedium` (17px), `titleSmall` (16px)
**Body:** `bodyLarge` (16px), `bodyMedium` (15px), `bodySmall` (14px)
**Label:** `labelLarge` (14px), `labelMedium` (13px), `labelSmall` (12px)

### Customizing Text Styles

```dart
Text(
  'Custom',
  style: AppTextStyles.titleLarge(context).copyWith(
    fontWeight: FontWeight.bold,
    color: AppColors.of(context).primary,
  ),
)
```

## Spacing

```dart
// Use spacing constants
Padding(padding: EdgeInsets.all(AppSpacing.md))
SizedBox(height: AppSpacing.lg)
```

### Spacing Values

- `AppSpacing.xs` = 4px (tiny)
- `AppSpacing.sm` = 8px (small)
- `AppSpacing.md` = 16px (medium)
- `AppSpacing.lg` = 24px (large)
- `AppSpacing.xl` = 32px (extraLarge)
- `AppSpacing.xxl` = 48px (huge)

## Border Radius

```dart
BorderRadius.circular(AppRadius.card)
```

### Radius Values

- `AppRadius.xs` = 4px (small)
- `AppRadius.sm` = 6px (input)
- `AppRadius.md` = 12px (card, button, medium)
- `AppRadius.lg` = 16px (large)
- `AppRadius.xl` = 24px

## Icon Sizes

```dart
Icon(CupertinoIcons.heart, size: AppIconSizes.lg)
```

### Icon Size Values

- `AppIconSizes.xs` = 12px
- `AppIconSizes.sm` = 16px (small)
- `AppIconSizes.md` = 20px (medium)
- `AppIconSizes.lg` = 24px (large)
- `AppIconSizes.xl` = 32px
- `AppIconSizes.xxl` = 48px

## Decorations

### Liquid Glass Effect

```dart
Container(
  decoration: AppDecorations.liquidGlass(context),
  child: YourWidget(),
)

// With custom background
Container(
  decoration: AppDecorations.liquidGlass(
    context,
    backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.1),
  ),
)
```

### Clean Card

```dart
Container(
  decoration: AppDecorations.cleanCard(context),
  child: YourWidget(),
)

// With custom radius
Container(
  decoration: AppDecorations.cleanCard(
    context,
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
)
```

### Expanded Section

```dart
Container(
  decoration: AppDecorations.expandedSection(context),
  child: YourWidget(),
)
```

## Complete Example

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.liquidGlass(context),
      child: Column(
        children: [
          Text(
            'Title',
            style: AppTextStyles.titleLarge(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Description',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          CupertinoButton(
            color: colors.primary,
            child: Text(
              'Action',
              style: AppTextStyles.button(context),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
```

## Important Notes

⚠️ **Always pass context** to:
- `AppColors.of(context)`
- `AppTextStyles.*(context)`
- `AppDecorations.*(context)`

✅ **This ensures:**
- Proper dark mode support
- Correct text colors
- Theme-appropriate styling
- Smooth transitions

🎨 **The system automatically handles:**
- Light/dark mode switching
- Text color contrast
- Background colors
- Glass effect opacity
