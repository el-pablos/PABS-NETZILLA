import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://evfyxtitophrnmptdzsl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2Znl4dGl0b3Bocm5tcHRkenNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc5NzI5NzQsImV4cCI6MjA1MzU0ODk3NH0.Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8',
  );

  runApp(const PABSNetzillaApp());
}

/// Aplikasi utama PABS-NETZILLA
class PABSNetzillaApp extends StatelessWidget {
  const PABSNetzillaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PABS-NETZILLA',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const SplashScreen(),
    );
  }

  /// Build tema aplikasi dengan color palette baru
  ThemeData _buildTheme() {
    const Color primaryPurple = Color(0xFF9929EA);
    const Color backgroundBlack = Color(0xFF000000);
    const Color textWhite = Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryPurple,
        surface: backgroundBlack,
        background: backgroundBlack,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textWhite,
        onBackground: textWhite,
      ),
      scaffoldBackgroundColor: backgroundBlack,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundBlack,
        foregroundColor: textWhite,
        titleTextStyle: const TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: backgroundBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryPurple.withOpacity(0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: textWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryPurple.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryPurple.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        filled: true,
        fillColor: backgroundBlack,
        labelStyle: const TextStyle(color: textWhite),
        hintStyle: TextStyle(color: textWhite.withOpacity(0.6)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textWhite),
        displayMedium: TextStyle(color: textWhite),
        displaySmall: TextStyle(color: textWhite),
        headlineLarge: TextStyle(color: textWhite),
        headlineMedium: TextStyle(color: textWhite),
        headlineSmall: TextStyle(color: textWhite),
        titleLarge: TextStyle(color: textWhite),
        titleMedium: TextStyle(color: textWhite),
        titleSmall: TextStyle(color: textWhite),
        bodyLarge: TextStyle(color: textWhite),
        bodyMedium: TextStyle(color: textWhite),
        bodySmall: TextStyle(color: textWhite),
        labelLarge: TextStyle(color: textWhite),
        labelMedium: TextStyle(color: textWhite),
        labelSmall: TextStyle(color: textWhite),
      ),
    );
  }
}
