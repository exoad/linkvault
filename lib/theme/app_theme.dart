import 'package:flutter/material.dart';

import 'linkvault_accent.dart';
import 'linkvault_design.dart';
import 'linkvault_typography.dart';

/// Monochrome Material theme; chroma comes from [LinkvaultAccent] on edges only.
ThemeData buildAppTheme({
  required ColorScheme scheme,
  required LinkvaultAccent accent,
}) {
  final textTheme = LinkvaultTypography.textTheme(scheme);
  final rounded = RoundedRectangleBorder(borderRadius: LinkvaultDesign.radiusCard);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: [accent],
    fontFamily: LinkvaultDesign.fontFamily,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    shadowColor: Colors.transparent,
    splashColor: scheme.onSurface.withValues(alpha: 0.06),
    highlightColor: scheme.onSurface.withValues(alpha: 0.04),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: rounded,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.none,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: LinkvaultDesign.radiusControl,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        visualDensity: VisualDensity.standard,
        shape: WidgetStateProperty.all(LinkvaultDesign.buttonShape),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: scheme.onSurface,
        foregroundColor: scheme.surface,
        shape: LinkvaultDesign.buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHigh,
        shape: LinkvaultDesign.buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        shape: LinkvaultDesign.buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      highlightElevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      backgroundColor: scheme.onSurface,
      foregroundColor: scheme.surface,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      extendedSizeConstraints: const BoxConstraints(minHeight: 52),
      shape: LinkvaultDesign.buttonShape,
    ),
    snackBarTheme: SnackBarThemeData(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.surfaceContainerHigh,
      contentTextStyle: textTheme.bodyMedium,
      shape: LinkvaultDesign.buttonShape,
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: LinkvaultDesign.radiusSheet,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LinkvaultDesign.radiusXl),
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
