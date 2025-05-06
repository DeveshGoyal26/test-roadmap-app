import 'package:universal_platform/universal_platform.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static SystemUiOverlayStyle get lightStatusBar => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    // For iOS
    statusBarBrightness:
        UniversalPlatform.isIOS ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static SystemUiOverlayStyle get darkStatusBar => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    // For iOS
    statusBarBrightness:
        UniversalPlatform.isIOS ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: const Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          // Set the predictive back transitions for Android.
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          // Set native iOS transitions
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.dark(
        outline: const Color.fromARGB(255, 84, 84, 84),
        primary: Color(0xFFF1ED50), // This will affect focus border and buttons
        secondary: Color(0xFFE2E2E2),
        surface: const Color(0xFF1E1E1E),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFECE713),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFECE713),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(color: Colors.black),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelStyle: const TextStyle(color: Color(0xFFE1E1E1)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF666666)),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF666666)),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
      ),
      textTheme: TextTheme(
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.16,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.16,
        ),
        displayLarge: GoogleFonts.poppins(
          fontSize: 72,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          letterSpacing: 1.5,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE1E1E1),
          height: 1.4,
          letterSpacing: 0,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFD4C9E6), // M3 on-surface-variant color
          height: 1.333, // 16px / 12px = 1.333
          letterSpacing: 0.4,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE1E1E1), // Light color for dark theme
          height: 18 / 16,
          letterSpacing: 0.16,
          fontFeatures: const [
            FontFeature.liningFigures(),
            FontFeature.proportionalFigures(),
            FontFeature.enable('dlig'),
          ],
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.3, // 130% line height
          letterSpacing: 0.01, // 1% letter spacing
          fontFeatures: const [
            FontFeature.liningFigures(),
            FontFeature.proportionalFigures(),
          ],
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 80,
          fontWeight: FontWeight.w700,
          height: 1.2, // 120% line-height
          letterSpacing: 0.01, // 1% letter spacing
          fontFeatures: const [
            FontFeature.liningFigures(),
            FontFeature.proportionalFigures(),
          ],
          foreground:
              Paint()
                ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFDA), // #FFFEDA
                    Color(0xFFFFFFDA), // #FFFEDA at 18.75%
                    Color(0xFFC5C006), // #C5C006
                  ],
                  stops: [0.0, 0.1875, 0.6923], // 0%, 18.75%, 69.23%
                ).createShader(
                  Rect.fromLTWH(0, 0, 0, 80),
                ), // height matches font size
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          // Set the predictive back transitions for Android.
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          // Set native iOS transitions
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        outline: const Color(0xFFE6E6E6),
        primary: Color(0xFFF1ED50), // This will affect focus border and buttons
        secondary: Color(0xFF222222),
        surface: const Color(0xFFF5F5F5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFECE713),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(color: Colors.black),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFECE713),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(color: Colors.black),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelStyle: const TextStyle(color: Color(0xFF666666)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF666666)),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF666666)),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      textTheme: TextTheme(
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          letterSpacing: 0.16,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          letterSpacing: 0.16,
        ),
        displayLarge: GoogleFonts.poppins(
          fontSize: 72,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: 1.5,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
          height: 1.4,
          letterSpacing: 0,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF49454F), // M3 on-surface-variant color
          height: 1.333, // 16px / 12px = 1.333
          letterSpacing: 0.4,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 18 / 16, // 112.5%
          letterSpacing: 0.16,
          fontFeatures: const [
            FontFeature.liningFigures(),
            FontFeature.proportionalFigures(),
            FontFeature.enable('dlig'),
          ],
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.black,
          height: 1.3, // 130% line height
          letterSpacing: 0.01, // 1% letter spacing
          fontFeatures: const [
            FontFeature.liningFigures(),
            FontFeature.proportionalFigures(),
          ],
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 80,
          fontWeight: FontWeight.w700,
          height: 1.2, // 120% line-height
          letterSpacing: 0.01, // 1% letter spacing
          fontFeatures: const [
            FontFeature.liningFigures(),
            FontFeature.proportionalFigures(),
          ],
          foreground:
              Paint()
                ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFDA), // #FFFEDA
                    Color(0xFFFFFFDA), // #FFFEDA at 18.75%
                    Color(0xFFC5C006), // #C5C006
                  ],
                  stops: [0.0, 0.1875, 0.6923], // 0%, 18.75%, 69.23%
                ).createShader(
                  Rect.fromLTWH(0, 0, 0, 80),
                ), // height matches font size
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
