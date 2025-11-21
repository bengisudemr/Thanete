import 'package:flutter/material.dart';

/// Extension to get theme-aware colors from BuildContext
extension AppThemeExtension on BuildContext {
  Color get appBackgroundPrimary => Theme.of(this).colorScheme.surface;
  Color get appBackgroundSecondary => Theme.of(this).scaffoldBackgroundColor;
  Color get appBackgroundTertiary => Theme.of(this).colorScheme.surfaceVariant;
  Color get appTextPrimary => Theme.of(this).colorScheme.onSurface;
  Color get appTextSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get appTextTertiary => Theme.of(this).brightness == Brightness.dark
      ? const Color(0xFF808080)
      : const Color(0xFF9AA4B2);
  Color get appBorderLight => Theme.of(this).colorScheme.outline;
  Color get appBorderMedium => Theme.of(this).colorScheme.outlineVariant;
  Color get appBorderStrong => Theme.of(this).brightness == Brightness.dark
      ? const Color(0xFF5A5A5A)
      : const Color(0xFF94A3B8);
  Color get appSurfaceMuted => Theme.of(this).brightness == Brightness.dark
      ? const Color(0xFF242424)
      : const Color(0xFFF9FAFC);
}

class AppTheme {
  // Primary theme colors (mutable to allow palette switching)
  static Color primaryPink = const Color.fromARGB(
    255,
    173,
    42,
    158,
  ); // Soft indigo
  static Color secondaryPurple = const Color.fromARGB(
    255,
    255,
    175,
    243,
  ); // Muted lavender
  static Color lightPink = const Color(0xFFEEF1FF); // Whispered periwinkle

  // Accent colors for highlights and charts
  static const Color accentBlue = Color(0xFF8CD3DD); // Mist teal
  static const Color accentGreen = Color(0xFFB8E5C1); // Sage mint
  static const Color accentOrange = Color(0xFFFBD6A0); // Soft apricot
  static const Color accentRed = Color(0xFFF6B8B8); // Calm coral

  // Typography colors
  static const Color textPrimary = Color(0xFF1F2933); // Charcoal
  static const Color textSecondary = Color(0xFF4B5563); // Steel
  static const Color textTertiary = Color(0xFF9AA4B2); // Cool grey

  // Background and surface colors
  static const Color backgroundPrimary = Color(0xFFFFFFFF); // Pure surface
  static const Color backgroundSecondary = Color(0xFFF6F7FB); // Porcelain
  static const Color backgroundTertiary = Color(0xFFEDF0F7); // Mist
  static const Color surfaceMuted = Color(0xFFF9FAFC); // Subtle overlay

  // Outline colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFC8D1DD);
  static const Color borderStrong = Color(0xFF94A3B8);

  // Feedback colors
  static const Color success = Color(0xFF3FB67C);
  static const Color warning = Color(0xFFF2A93B);
  static const Color error = Color(0xFFDE5B63);
  static const Color info = Color(0xFF3E7DD1);

  // Spacing scale
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // Rounded corners
  static const double radiusMicro = 4.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 28.0;

  // Font sizing scale
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeXXXLarge = 32.0;

  // Font weights
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // Animation cadence
  static const Duration animationUltraFast = Duration(milliseconds: 120);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 280);
  static const Duration animationSlow = Duration(milliseconds: 420);

  // Animation curves
  static const Curve animationCurve = Curves.easeOutCubic;
  static const Curve animationEntrance = Curves.easeOutQuart;
  static const Curve animationExit = Curves.easeInCubic;

  // Color harmonies
  static List<Color> get primaryGradient => [primaryPink, secondaryPurple];

  static List<List<Color>> get noteGradients => [
    [primaryPink, secondaryPurple],
    const [Color(0xFF4BC0C8), Color(0xFFC779D0)],
    const [Color(0xFF74EBD5), Color(0xFFACB6E5)],
    const [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
    const [Color(0xFF5EE7DF), Color(0xFFB490CA)],
    const [Color(0xFFB2FEFA), Color(0xFF0ED2F7)],
  ];

  // Depth and elevation
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: const Color(0xFF1E293B).withOpacity(0.12),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get glassmorphismShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.03),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: primaryPink.withOpacity(0.06),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // Gradients
  static LinearGradient get primaryGradientLinear => LinearGradient(
    colors: primaryGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get subtleGradient => LinearGradient(
    colors: [surfaceMuted, backgroundPrimary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get horizontalGradient => LinearGradient(
    colors: primaryGradient,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Shader mask for brand typography
  static ShaderMask createGradientText(
    String text, {
    required TextStyle style,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => horizontalGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }

  // Container decoration helpers
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
    gradient: primaryGradientLinear,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: buttonShadow,
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: backgroundPrimary,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: cardShadow,
  );

  static BoxDecoration get logoContainerDecoration => BoxDecoration(
    color: backgroundPrimary,
    borderRadius: BorderRadius.circular(radiusXXLarge),
    border: Border.all(color: primaryPink.withOpacity(0.6), width: 2),
    boxShadow: [
      BoxShadow(
        color: primaryPink.withOpacity(0.18),
        blurRadius: 26,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.08),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get logoInnerDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(radiusLarge),
    gradient: LinearGradient(
      colors: [
        primaryPink.withOpacity(0.18),
        secondaryPurple.withOpacity(0.12),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Text system
  static TextTheme get textTheme {
    const base = TextTheme(
      displayLarge: TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: -0.8,
      ),
      displayMedium: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.6,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.4,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.1,
        letterSpacing: 0.6,
      ),
    );

    return base.apply(bodyColor: textPrimary, displayColor: textPrimary);
  }

  // Modern, minimal Material 3 theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryPink,
      onPrimary: Colors.white,
      primaryContainer: lightPink,
      onPrimaryContainer: const Color(0xFF1C2267),
      secondary: secondaryPurple,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE4E9FF),
      onSecondaryContainer: const Color(0xFF1B2358),
      tertiary: accentBlue,
      onTertiary: const Color(0xFF0F2A30),
      tertiaryContainer: const Color(0xFFD1F0F3),
      onTertiaryContainer: const Color(0xFF102B31),
      error: error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFDE7E9),
      onErrorContainer: const Color(0xFF601410),
      background: backgroundSecondary,
      onBackground: textPrimary,
      surface: backgroundPrimary,
      onSurface: textPrimary,
      surfaceVariant: backgroundTertiary,
      onSurfaceVariant: textSecondary,
      outline: borderLight,
      outlineVariant: borderMedium,
      shadow: const Color(0x330F172A),
      scrim: const Color(0x660F172A),
      inverseSurface: const Color(0xFF1F2933),
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFFBBC5FF),
      surfaceTint: primaryPink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundSecondary,
      textTheme: textTheme,
      fontFamily: null, // inherit platform font for minimal feel
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        toolbarTextStyle: textTheme.titleMedium,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary),
      primaryIconTheme: IconThemeData(color: colorScheme.primary),
      cardTheme: CardThemeData(
        color: backgroundPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: spacingXXL,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        iconColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingXXL,
          vertical: spacingM,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXXL,
            vertical: spacingM,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXXL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: spacingM,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingS,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withOpacity(0.2),
        circularTrackColor: backgroundTertiary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(colorScheme.primary),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.24);
          }
          return borderLight;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStatePropertyAll(colorScheme.primary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStatePropertyAll(colorScheme.primary),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
        trackHeight: 4,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundPrimary,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingXL,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: error, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.08),
        selectedColor: colorScheme.primary.withOpacity(0.16),
        secondarySelectedColor: colorScheme.primary.withOpacity(0.16),
        side: BorderSide(color: borderLight),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingS,
        ),
        labelStyle: textTheme.labelLarge!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: backgroundPrimary,
        modalBackgroundColor: backgroundPrimary,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXLarge),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: textTertiary,
        dragHandleSize: const Size(double.infinity, 24),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundPrimary,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          color: textTertiary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundPrimary,
        indicatorColor: colorScheme.primary.withOpacity(0.12),
        elevation: 0,
        height: 72,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.labelLarge?.copyWith(color: colorScheme.primary)
              : textTheme.labelMedium?.copyWith(color: textTertiary),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        actionTextColor: Colors.white,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: backgroundPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withOpacity(0.18),
        selectionHandleColor: colorScheme.primary,
      ),
    );
  }

  // Dark theme colors
  static const Color darkBackgroundPrimary = Color(0xFF1A1A1A);
  static const Color darkBackgroundSecondary = Color(0xFF121212);
  static const Color darkBackgroundTertiary = Color(0xFF2A2A2A);
  static const Color darkSurfaceMuted = Color(0xFF242424);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkBorderLight = Color(0xFF3A3A3A);
  static const Color darkBorderMedium = Color(0xFF4A4A4A);
  static const Color darkBorderStrong = Color(0xFF5A5A5A);

  // Modern, minimal Material 3 dark theme
  static ThemeData get darkTheme {
    // Material 3 dark color scheme
    final colorScheme = ColorScheme.dark(
      primary: primaryPink,
      onPrimary: Colors.white,
      primaryContainer: primaryPink.withOpacity(0.2),
      onPrimaryContainer: Colors.white,
      secondary: secondaryPurple,
      onSecondary: Colors.white,
      secondaryContainer: secondaryPurple.withOpacity(0.2),
      onSecondaryContainer: Colors.white,
      tertiary: accentBlue,
      onTertiary: Colors.white,
      tertiaryContainer: accentBlue.withOpacity(0.2),
      onTertiaryContainer: Colors.white,
      error: error,
      onError: Colors.white,
      errorContainer: error.withOpacity(0.2),
      onErrorContainer: Colors.white,
      background: darkBackgroundSecondary,
      onBackground: darkTextPrimary,
      surface: darkBackgroundPrimary,
      onSurface: darkTextPrimary,
      surfaceVariant: darkBackgroundTertiary,
      onSurfaceVariant: darkTextSecondary,
      outline: darkBorderLight,
      outlineVariant: darkBorderMedium,
      shadow: const Color(0x66000000),
      scrim: const Color(0x99000000),
      inverseSurface: darkTextPrimary,
      onInverseSurface: darkBackgroundPrimary,
      inversePrimary: primaryPink.withOpacity(0.3),
      surfaceTint: primaryPink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackgroundSecondary,
      textTheme: textTheme.apply(bodyColor: darkTextPrimary, displayColor: darkTextPrimary),
      fontFamily: null,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkTextPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: darkTextPrimary),
        toolbarTextStyle: textTheme.titleMedium?.copyWith(color: darkTextPrimary),
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary),
      primaryIconTheme: IconThemeData(color: colorScheme.primary),
      cardTheme: CardThemeData(
        color: darkBackgroundPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: darkBorderLight,
        thickness: 1,
        space: spacingXXL,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: darkBackgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        iconColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingXXL,
          vertical: spacingM,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXXL,
            vertical: spacingM,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXXL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: darkBorderLight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: spacingM,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingS,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withOpacity(0.2),
        circularTrackColor: darkBackgroundTertiary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(colorScheme.primary),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return darkBorderLight;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStatePropertyAll(colorScheme.primary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStatePropertyAll(colorScheme.primary),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
        trackHeight: 4,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackgroundPrimary,
        hintStyle: textTheme.bodyMedium?.copyWith(color: darkTextTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: darkTextPrimary),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingXL,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: darkBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: darkBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: error, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.15),
        selectedColor: colorScheme.primary.withOpacity(0.3),
        secondarySelectedColor: colorScheme.primary.withOpacity(0.3),
        side: BorderSide(color: darkBorderLight),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingS,
        ),
        labelStyle: textTheme.labelLarge!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkBackgroundPrimary,
        modalBackgroundColor: darkBackgroundPrimary,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXLarge),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: darkTextTertiary,
        dragHandleSize: const Size(double.infinity, 24),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkBackgroundPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: darkTextPrimary),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: darkTextPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBackgroundPrimary,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          color: darkTextTertiary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkBackgroundPrimary,
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        elevation: 0,
        height: 72,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.labelLarge?.copyWith(color: colorScheme.primary)
              : textTheme.labelMedium?.copyWith(color: darkTextTertiary),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkTextPrimary,
        actionTextColor: darkBackgroundPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: darkBackgroundPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkTextPrimary,
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: darkBackgroundPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkBackgroundPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: darkTextPrimary),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withOpacity(0.3),
        selectionHandleColor: colorScheme.primary,
      ),
    );
  }
}
