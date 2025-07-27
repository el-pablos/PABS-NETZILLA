import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
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

  /// Build tema aplikasi
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
    );
  }
}
