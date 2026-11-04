// lib/app_theme.dart
// ============================================================
// AppTheme — ثيم GRAND ONE (Material 3)
// ============================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'design/tokens.dart';
import 'design/typography.dart';

class AppTheme {
  AppTheme._();

  /// الاسم الجديد.
  static ThemeData get grandOneTheme => _build();


  static ThemeData _build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppPalette.navy,
      onPrimary: AppPalette.onPrimary,
      primaryContainer: AppPalette.navySoft,
      onPrimaryContainer: AppPalette.navyDark,
      secondary: AppPalette.gold,
      onSecondary: AppPalette.onGold,
      secondaryContainer: AppPalette.goldSoft,
      onSecondaryContainer: AppPalette.goldDeep,
      tertiary: AppPalette.info,
      onTertiary: AppPalette.onPrimary,
      surface: AppPalette.surface,
      onSurface: AppPalette.textPrimary,
      onSurfaceVariant: AppPalette.textSecondary,
      surfaceContainerLowest: AppPalette.surface,
      surfaceContainerLow: AppPalette.background,
      surfaceContainer: AppPalette.backgroundAlt,
      surfaceContainerHigh: AppPalette.surfaceTint,
      surfaceContainerHighest: AppPalette.surfaceTint,
      outline: AppPalette.border,
      outlineVariant: AppPalette.borderLight,
      error: AppPalette.error,
      onError: Colors.white,
      errorContainer: AppPalette.errorLight,
      onErrorContainer: AppPalette.errorDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: AppPalette.navy,
      scaffoldBackgroundColor: AppPalette.background,
      fontFamily: kFontFamily,
      visualDensity: VisualDensity.standard,
      splashColor: AppPalette.navy.withValues(alpha: 0.08),
      highlightColor: AppPalette.navy.withValues(alpha: 0.04),
      canvasColor: AppPalette.background,
      dividerColor: AppPalette.divider,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GrandOnePageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: GrandOnePageTransitionsBuilder(),
          TargetPlatform.windows: GrandOnePageTransitionsBuilder(),
          TargetPlatform.fuchsia: GrandOnePageTransitionsBuilder(),
        },
      ),
      textTheme: AppTextTheme.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.navy,
        foregroundColor: AppPalette.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleSpacing: Space.md,
        toolbarHeight: 60,
        titleTextStyle: AppText.title.copyWith(
          color: AppPalette.onPrimary,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(
          color: AppPalette.onPrimary,
          size: Sizes.iconLg,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppPalette.onPrimary,
          size: Sizes.iconLg,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.navy,
          foregroundColor: AppPalette.onPrimary,
          disabledBackgroundColor: AppPalette.borderLight,
          disabledForegroundColor: AppPalette.textMuted,
          elevation: 0,
          minimumSize: const Size(double.infinity, Sizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xl,
            vertical: Space.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
          textStyle: AppText.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.navy,
          disabledForegroundColor: AppPalette.textMuted,
          side: const BorderSide(color: AppPalette.navy, width: 1.2),
          minimumSize: const Size(double.infinity, Sizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xl,
            vertical: Space.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
          textStyle: AppText.button,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.navy,
          foregroundColor: AppPalette.onPrimary,
          disabledBackgroundColor: AppPalette.borderLight,
          disabledForegroundColor: AppPalette.textMuted,
          elevation: 0,
          minimumSize: const Size(double.infinity, Sizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xl,
            vertical: Space.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
          textStyle: AppText.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.navy,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xs + 2),
          ),
          textStyle: AppText.buttonSmall,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppPalette.navy,
          minimumSize: const Size(Sizes.touchTarget, Sizes.touchTarget),
          highlightColor: AppPalette.navySoft,
          shape: const RoundedRectangleBorder(borderRadius: Radii.brSm),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.navy,
        foregroundColor: AppPalette.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: Sizes.navBarHeight,
        indicatorColor: AppPalette.goldSoft,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: Radii.brSm,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppText.micro.copyWith(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppPalette.goldDeep : AppPalette.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? AppPalette.goldDeep : AppPalette.textTertiary,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppPalette.surface,
        indicatorColor: AppPalette.goldSoft,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: Radii.brSm,
        ),
        selectedIconTheme: const IconThemeData(
          color: AppPalette.goldDeep,
          size: Sizes.iconLg,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppPalette.textTertiary,
          size: Sizes.iconLg,
        ),
        selectedLabelTextStyle: AppText.micro.copyWith(
          color: AppPalette.goldDeep,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: AppText.micro.copyWith(
          color: AppPalette.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppPalette.navy;
            return AppPalette.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppPalette.onPrimary;
            }
            return AppPalette.textSecondary;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppPalette.border),
          ),
          textStyle: const WidgetStatePropertyAll(AppText.buttonSmall),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.brSm),
          ),
        ),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: Sizes.navBarHeight,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brLg,
          side: const BorderSide(color: AppPalette.borderLight, width: 0.8),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppPalette.navy,
        textColor: AppPalette.textPrimary,
        minVerticalPadding: Space.md,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: Radii.brSm),
        titleTextStyle: AppText.title.copyWith(fontSize: 15),
        subtitleTextStyle: AppText.bodySecondary,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: AppPalette.navy,
        collapsedIconColor: AppPalette.textTertiary,
        textColor: AppPalette.textPrimary,
        collapsedTextColor: AppPalette.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
        collapsedShape: RoundedRectangleBorder(borderRadius: Radii.brMd),
        tilePadding: const EdgeInsets.symmetric(horizontal: Space.lg),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppPalette.gold,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppPalette.navy,
        unselectedLabelColor: AppPalette.textSecondary,
        dividerColor: AppPalette.borderLight,
        labelStyle: AppText.buttonSmall,
        unselectedLabelStyle: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: const BorderSide(color: AppPalette.navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: const BorderSide(color: AppPalette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: const BorderSide(color: AppPalette.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: const BorderSide(color: AppPalette.borderLight),
        ),
        labelStyle: AppText.subtitle.copyWith(color: AppPalette.textSecondary),
        floatingLabelStyle: AppText.subtitle.copyWith(
          color: AppPalette.navy,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: AppText.subtitle.copyWith(color: AppPalette.textMuted),
        helperStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: AppPalette.textSecondary,
        ),
        errorStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: AppPalette.error,
        ),
        prefixIconColor: AppPalette.navy,
        suffixIconColor: AppPalette.navy,
      ),
      iconTheme: const IconThemeData(
        color: AppPalette.navy,
        size: Sizes.iconLg,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.divider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: Radii.brXl),
        titleTextStyle: AppText.section.copyWith(
          fontSize: 19,
          color: AppPalette.textPrimary,
        ),
        contentTextStyle: AppText.body.copyWith(
          color: AppPalette.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.navyDark,
        elevation: 4,
        insetPadding: const EdgeInsets.all(Space.lg),
        contentTextStyle: AppText.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
      ),
      bannerTheme: const MaterialBannerThemeData(
        backgroundColor: AppPalette.goldSoft,
        surfaceTintColor: Colors.transparent,
        contentTextStyle: AppText.subtitle,
        elevation: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: AppPalette.border, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppPalette.navy;
          return AppPalette.surface;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppPalette.navy;
          return AppPalette.border;
        }),
      ),
      switchTheme: SwitchThemeData(
        // مفعّل: مسار كحلي ومقبض ذهبي واضح؛ معطّل: رمادي فاتح
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppPalette.gold;
          return AppPalette.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.navy;
          }
          return AppPalette.borderStrong;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppPalette.navy;
          return AppPalette.borderStrong;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.surfaceTint,
        selectedColor: AppPalette.navySoft,
        disabledColor: AppPalette.borderLight,
        side: const BorderSide(color: AppPalette.borderLight),
        shape: RoundedRectangleBorder(borderRadius: Radii.brSm),
        labelStyle: AppText.bodySecondary.copyWith(
          color: AppPalette.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: AppText.bodySecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm + 2,
          vertical: Space.xs + 2,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brMd,
          side: const BorderSide(color: AppPalette.borderLight),
        ),
        textStyle: AppText.bodySecondary.copyWith(
          color: AppPalette.textPrimary,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.navy,
        circularTrackColor: AppPalette.navySoft,
        linearTrackColor: AppPalette.navySoft,
        linearMinHeight: 5,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppPalette.navyDark,
          borderRadius: BorderRadius.circular(Radii.xs),
        ),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppPalette.surface,
        elevation: 8,
        modalElevation: 12,
        clipBehavior: Clip.antiAlias,
        showDragHandle: false,
        shape: RoundedRectangleBorder(borderRadius: Radii.sheet),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: Radii.brXl),
        headerBackgroundColor: AppPalette.navy,
        headerForegroundColor: AppPalette.onPrimary,
        dayOverlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppPalette.navy;
          return AppPalette.navySoft;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppPalette.textPrimary;
        }),
        todayBorder: const BorderSide(color: AppPalette.gold, width: 1.4),
        todayForegroundColor: const WidgetStatePropertyAll(
          AppPalette.goldDark,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppPalette.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: Radii.brXl),
        hourMinuteColor: AppPalette.surfaceTint,
        hourMinuteTextColor: AppPalette.navy,
        dayPeriodColor: AppPalette.surfaceTint,
        dayPeriodTextColor: AppPalette.navy,
        dialHandColor: AppPalette.navy,
        dialBackgroundColor: AppPalette.surfaceTint,
        dialTextColor: AppPalette.textPrimary,
        entryModeIconColor: AppPalette.navy,
        hourMinuteTextStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 46,
          fontWeight: FontWeight.w500,
          color: AppPalette.navy,
        ),
        dayPeriodTextStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppPalette.textPrimary,
        ),
        helpTextStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppPalette.textSecondary,
        ),
      ),
    );
  }
}

class GrandOnePageTransitionsBuilder extends PageTransitionsBuilder {
  const GrandOnePageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.normal;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// توافق مع الاسم القديم.

class GrandOneScrollBehavior extends MaterialScrollBehavior {
  const GrandOneScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}


