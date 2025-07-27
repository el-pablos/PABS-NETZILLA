import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/vps_management_screen.dart';
import 'screens/ip_check_screen.dart';
// import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance optimizations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Optimize memory usage
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Supabase.initialize(
    url: 'https://evfyxtitophrnmptdzsl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2Znl4dGl0b3Bocm5tcHRkenNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc5NzI5NzQsImV4cCI6MjA1MzU0ODk3NH0.Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8Zt8',
  );

  // Initialize SupabaseService for real-time functionality
  // TODO: Re-enable after fixing SupabaseService
  // final supabaseService = SupabaseService();
  // await supabaseService.initializeRealtimeSubscriptions();

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
      routes: {
        '/vps-management': (context) => const VpsManagementScreen(),
        '/ip-check': (context) => const IpCheckScreen(),
      },
      // Performance optimizations
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      // Reduce memory usage
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
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
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textWhite,
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
          side: BorderSide(color: primaryPurple.withValues(alpha: 0.3)),
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
          borderSide: BorderSide(color: primaryPurple.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryPurple.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        filled: true,
        fillColor: backgroundBlack,
        labelStyle: const TextStyle(color: textWhite),
        hintStyle: TextStyle(color: textWhite.withValues(alpha: 0.6)),
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
