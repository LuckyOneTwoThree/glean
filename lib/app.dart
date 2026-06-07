import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/app_state_provider.dart';
import 'services/schedule_service.dart';

/// 拾光 / Glean 应用入口
class GleanApp extends ConsumerStatefulWidget {
  const GleanApp({super.key});

  @override
  ConsumerState<GleanApp> createState() => _GleanAppState();
}

class _GleanAppState extends ConsumerState<GleanApp> {
  bool _scheduleInitialized = false;

  @override
  Widget build(BuildContext context) {
    final onboardingDone = ref.watch(onboardingDoneProvider);

    // 初始化定时任务（仅一次）
    if (!_scheduleInitialized) {
      _scheduleInitialized = true;
      _initSchedule();
    }

    return MaterialApp(
      title: '拾光 / Glean',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: onboardingDone
          ? const HomeScreen()
          : const WelcomeScreen(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Future<void> _initSchedule() async {
    if (kIsWeb) return;
    final configAsync = ref.read(userConfigProvider);
    configAsync.whenData((config) async {
      final interval = config.fetchInterval;
      await ScheduleService.scheduleFetch(intervalHours: interval);
    });
  }

  ThemeData _buildTheme() {
    const inkBlue = Color(0xFF1A2B3C);
    const goldenHour = Color(0xFFD4AF37);
    const surface = Color(0xFFF9F9F8);
    const onSurface = Color(0xFF1A1C1C);
    const onSurfaceVariant = Color(0xFF44474C);
    const outlineVariant = Color(0xFFC4C6CD);
    const surfaceContainerLow = Color(0xFFF3F4F3);
    const surfaceContainer = Color(0xFFEEEEED);
    const surfaceContainerHigh = Color(0xFFE8E8E7);
    const paperWhite = Color(0xFFFFFFFF);
    const unreadBlue = Color(0xFF2D5AF7);
    const error = Color(0xFFBA1A1A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: inkBlue,
        onPrimary: paperWhite,
        secondary: goldenHour,
        onSecondary: paperWhite,
        surface: surface,
        onSurface: onSurface,
        error: error,
        onError: paperWhite,
        outline: Color(0xFF74777D),
        surfaceContainerHighest: Color(0xFFE2E2E2),
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainer: surfaceContainer,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: paperWhite,
      ),
      // 字体系统
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.sourceSerif4(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: inkBlue,
        ),
        headlineMedium: GoogleFonts.sourceSerif4(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: inkBlue,
        ),
        headlineSmall: GoogleFonts.sourceSerif4(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.33,
          color: inkBlue,
        ),
        titleLarge: GoogleFonts.sourceSerif4(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: inkBlue,
        ),
        bodyLarge: GoogleFonts.hankenGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.56,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: onSurface,
        ),
        bodySmall: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.43,
          color: onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.14,
          letterSpacing: 0.02,
          color: onSurface,
        ),
        labelMedium: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.33,
          letterSpacing: 0.04,
          color: onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.hankenGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.45,
          letterSpacing: 0.04,
          color: onSurfaceVariant,
        ),
      ),
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 0,
        color: paperWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      // 底部导航主题
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface.withOpacity(0.95),
        indicatorColor: surfaceContainerHigh,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onSurfaceVariant,
          ),
        ),
      ),
      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: inkBlue,
        inactiveTrackColor: surfaceContainerHigh,
        thumbColor: inkBlue,
        overlayColor: inkBlue.withOpacity(0.1),
        trackHeight: 4,
      ),
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return inkBlue;
          }
          return paperWhite;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return inkBlue.withOpacity(0.5);
          }
          return surfaceContainerHigh;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      // 按钮主题
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: inkBlue,
          foregroundColor: paperWhite,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inkBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          color: onSurfaceVariant.withOpacity(0.6),
        ),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final routes = <String, WidgetBuilder>{
      '/welcome': (_) => const WelcomeScreen(),
      '/onboarding': (_) => const OnboardingScreen(),
      '/home': (_) => const HomeScreen(),
    };

    final builder = routes[settings.name];
    if (builder == null) return null;

    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }
}
