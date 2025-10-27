// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'pages/main_screen.dart'; // pastikan path ini sesuai

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('id_ID', null);



  runApp(
    Phoenix(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('id')],
        path: 'lang',
        fallbackLocale: const Locale('id'),
        useOnlyLangCode: true,
        child: const MyApp(),
      ),
    ),
  );
}

enum AppColorScheme {
  custom('Custom', Colors.grey),
  blue('Blue', Colors.blue),
  green('Green', Colors.green),
  red('Red', Colors.red),
  orange('Orange', Colors.orange),
  purple('Purple', Colors.purple),
  teal('Teal', Colors.teal);

  const AppColorScheme(this.label, this.color);
  final String label;
  final Color color;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Settings default
  ThemeMode _themeMode = ThemeMode.light;
  AppColorScheme _colorScheme = AppColorScheme.blue;
  Color? _customColor;
  bool _autoSaveEnabled = true;

  // Shared prefs instance
  SharedPreferences? _prefs;

  // Loading flag used by splash
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initAndLoadSettings();
  }

  Future<void> _initAndLoadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    final themeModeIndex = _prefs!.getInt('themeMode') ?? ThemeMode.light.index;
    final colorSchemeName =
        _prefs!.getString('colorScheme') ?? AppColorScheme.blue.name;
    final customColorValue = _prefs!.getInt('customColor');
    final autoSaveEnabled = _prefs!.getBool('autoSaveEnabled') ?? true;

    setState(() {
      _themeMode = ThemeMode.values[themeModeIndex];
      _colorScheme = AppColorScheme.values.firstWhere(
        (e) => e.name == colorSchemeName,
        orElse: () => AppColorScheme.blue,
      );
      if (_colorScheme == AppColorScheme.custom && customColorValue != null) {
        _customColor = Color(customColorValue);
      }
      _autoSaveEnabled = autoSaveEnabled;
      _initialized = true; // siap untuk lanjut dari splash
    });
  }



  void _onAutoSaveChanged(bool enabled) {
    setState(() {
      _autoSaveEnabled = enabled;
    });
    _prefs?.setBool('autoSaveEnabled', enabled);
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    await _prefs?.setInt('themeMode', _themeMode.index);
  }

  Future<void> _changeColorScheme(AppColorScheme newScheme,
      [Color? customColor]) async {
    setState(() {
      _colorScheme = newScheme;
      if (newScheme == AppColorScheme.custom) _customColor = customColor;
    });
    await _prefs?.setString('colorScheme', _colorScheme.name);
    if (newScheme == AppColorScheme.custom && customColor != null) {
      await _prefs?.setInt('customColor', customColor.toARGB32());
    } else {
      await _prefs?.remove('customColor');
    }
  }

  @override
  Widget build(BuildContext context) {

    final seedColor =
        _colorScheme == AppColorScheme.custom && _customColor != null
            ? _customColor!
            : _colorScheme.color;

    return MaterialApp(
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey.shade100,
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,

      // Home: tampilkan SplashPage sampai _initialized == true, lalu MainScreen
      home: SplashPage(
        initialized: _initialized,
        onFinishInitialization: () {
          // nothing needed here, widget will rebuild and replace itself
        },
        // Kirimkan builder MainScreen ketika sudah siap
         mainScreenBuilder: () => MainScreen(
          onToggleTheme: _toggleTheme,
          themeMode: _themeMode,
          colorScheme: _colorScheme,
          onChangeColorScheme: _changeColorScheme,
          customColor: _customColor,
          autoSaveEnabled: _autoSaveEnabled,
          onAutoSaveChanged: _onAutoSaveChanged,
        ),
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  final bool initialized;
  final VoidCallback onFinishInitialization;
  final Widget Function() mainScreenBuilder;

  const SplashPage({
    super.key,
    required this.initialized,
    required this.onFinishInitialization,
    required this.mainScreenBuilder,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacityAnim;

  // Minimal splash duration agar tidak langsung lompat
  final Duration _minSplashDuration = const Duration(milliseconds: 1000);
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _animController.forward();

    // Periksa periodik apakah inisialisasi sudah selesai dan minimal duration terpenuhi
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final elapsed = DateTime.now().difference(_startTime);
      if (widget.initialized && elapsed >= _minSplashDuration) {
        timer.cancel();
        _goToMain();
      }
    });
  }

  void _goToMain() {
    // lakukan transisi pushReplacement ke MainScreen (dengan fade)
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => widget.mainScreenBuilder(),
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  @override
  void didUpdateWidget(covariant SplashPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // jika sebelumnya belum inisialisasi dan sekarang sudah, cek langsung
    if (!oldWidget.initialized && widget.initialized) {
      final elapsed = DateTime.now().difference(_startTime);
      if (elapsed >= _minSplashDuration) {
        _goToMain();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan logo (pakai Image.asset atau FlutterLogo jika asset bermasalah)
    Widget logo;
    try {
      logo = Image.asset(
        'assets/logo-splash.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const FlutterLogo(size: 120),
      );
    } catch (_) {
      logo = const FlutterLogo(size: 120);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              logo,
              const SizedBox(height: 12),
              Text(
                'app_name'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
