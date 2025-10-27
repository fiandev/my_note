 import 'dart:async';
 import 'package:flutter/material.dart';
 import 'package:shared_preferences/shared_preferences.dart';
 import 'package:intl/date_symbol_data_local.dart';
 import 'package:easy_localization/easy_localization.dart';
 import 'package:flutter_quill/flutter_quill.dart';
 import 'dart:ui' as ui;
 import 'pages/main_screen.dart'; // pastikan path ini sesuai
import 'widgets/splash_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('id'), Locale('ja'), Locale('ko'), Locale('zh')],
      path: 'lang',
      fallbackLocale: const Locale('id'),
      useOnlyLangCode: true,
      child: const MyApp(),
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
  Key _key = UniqueKey();
  // Settings default
  ThemeMode _themeMode = ThemeMode.light;
  AppColorScheme _colorScheme = AppColorScheme.blue;
  Color? _customColor;
  bool _autoSaveEnabled = true;
  bool _isChangingLanguage = false;

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

  void _changeLanguage() {
    setState(() {
      _key = UniqueKey();
      _isChangingLanguage = true;
    });
    // After a short delay, hide the indicator
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isChangingLanguage = false;
      });
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

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Stack(
        children: [
          MaterialApp(
            key: _key,
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
            localizationsDelegates: [...context.localizationDelegates, FlutterQuillLocalizations.delegate],
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
                onChangeLanguage: _changeLanguage,
              ),
            ),
          ),
          if (_isChangingLanguage)
            const Opacity(
              opacity: 0.5,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (_isChangingLanguage)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

