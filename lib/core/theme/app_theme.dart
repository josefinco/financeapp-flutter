import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ─── Brand colors ─────────────────────────────────────────────────────────
  static const Color _primaryColor   = Color(0xFF4CAF50);
  static const Color _primaryDark    = Color(0xFF388E3C);
  static const Color _accentBlue     = Color(0xFF29B6F6);
  static const Color _errorColor     = Color(0xFFFF4444);

  // ─── Light surfaces ───────────────────────────────────────────────────────
  static const Color _lightBg        = Color(0xFFF2F5F9);
  static const Color _lightSurface   = Colors.white;

  // ─── Dark surfaces ────────────────────────────────────────────────────────
  static const Color _darkBg         = Color(0xFF0D0D0F);
  static const Color _darkSurface    = Color(0xFF171720);
  static const Color _darkSurface2   = Color(0xFF1E1E2C);

  // ─── Light ────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          secondary: _accentBlue,
          error: _errorColor,
          surface: _lightSurface,
          onSurface: const Color(0xFF1A1A1A),
        ),
        textTheme: _textTheme(const Color(0xFF1A1A1A)),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: _lightSurface,
          shadowColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEDF0F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _errorColor),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          floatingLabelStyle: const TextStyle(color: _primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryColor,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: _primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
        // Material 3 NavigationBar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _lightSurface,
          elevation: 0,
          height: 70,
          indicatorColor: _primaryColor.withOpacity(0.12),
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: _primaryColor, fontSize: 11, fontWeight: FontWeight.w700);
            }
            return const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11, fontWeight: FontWeight.w500);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _primaryColor, size: 24);
            }
            return const IconThemeData(color: Color(0xFF9E9E9E), size: 24);
          }),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE5E9F0), thickness: 1),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide.none,
          backgroundColor: const Color(0xFFEDF0F5),
        ),
      );

  // ─── Dark ─────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
          secondary: _accentBlue,
          error: _errorColor,
          surface: _darkSurface,
          onSurface: const Color(0xFFF0F0F0),
        ),
        textTheme: _textTheme(const Color(0xFFF0F0F0)),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF0F0F0),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF0F0F0),
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: Color(0xFFF0F0F0)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: _darkSurface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkSurface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2A2A3A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _errorColor),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          floatingLabelStyle: const TextStyle(color: _primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryColor,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: _primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
        // Material 3 NavigationBar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _darkSurface,
          elevation: 0,
          height: 70,
          indicatorColor: _primaryColor.withOpacity(0.18),
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: _primaryColor, fontSize: 11, fontWeight: FontWeight.w700);
            }
            return const TextStyle(color: Color(0xFF6B6B7B), fontSize: 11, fontWeight: FontWeight.w500);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _primaryColor, size: 24);
            }
            return const IconThemeData(color: Color(0xFF6B6B7B), size: 24);
          }),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFF232333), thickness: 1),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        listTileTheme: const ListTileThemeData(iconColor: Color(0xFF9E9EA8)),
        iconTheme: const IconThemeData(color: Color(0xFF9E9EA8)),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide.none,
          backgroundColor: _darkSurface2,
        ),
      );

  // ─── Shared text theme ────────────────────────────────────────────────────
  static TextTheme _textTheme(Color base) => TextTheme(
        displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.5, color: base),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: -0.5, color: base),
        displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: base),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: base),
        headlineMedium:TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: base),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: base),
        titleLarge:    TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: base),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.0,  color: base),
        titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,  color: base),
        bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.2,  color: base),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.1,  color: base),
        bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.2,  color: base.withOpacity(0.65)),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,  color: base),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4,  color: base),
        labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,  color: base.withOpacity(0.65)),
      );

  // ─── Semantic colors ──────────────────────────────────────────────────────
  static const Color incomeColor  = Color(0xFF4CAF50);
  static const Color expenseColor = Color(0xFFFF4444);
  static const Color errorColor   = Color(0xFFFF4444);
  static const Color pendingColor = Color(0xFFFF9800);
  static const Color overdueColor = Color(0xFFFF4444);
  static const Color paidColor    = Color(0xFF4CAF50);

  // ─── Gradient helpers ─────────────────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF1565C0)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient cardGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
  );
}
