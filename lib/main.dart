import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/main_screen.dart'; // Import the new MainScreen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
  ThemeMode _themeMode = ThemeMode.light;
  AppColorScheme _colorScheme = AppColorScheme.blue;
  Color? _customColor;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final themeModeIndex = _prefs.getInt('themeMode') ?? ThemeMode.light.index;
    final colorSchemeName = _prefs.getString('colorScheme') ?? AppColorScheme.blue.name;
    final customColorValue = _prefs.getInt('customColor');

    setState(() {
      _themeMode = ThemeMode.values[themeModeIndex];
      _colorScheme = AppColorScheme.values.firstWhere(
        (e) => e.name == colorSchemeName,
        orElse: () => AppColorScheme.blue,
      );
      if (_colorScheme == AppColorScheme.custom && customColorValue != null) {
        _customColor = Color(customColorValue);
      }
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    await _prefs.setInt('themeMode', _themeMode.index);
  }

  Future<void> _changeColorScheme(AppColorScheme newScheme, [Color? customColor]) async {
    setState(() {
      _colorScheme = newScheme;
      if (newScheme == AppColorScheme.custom) {
        _customColor = customColor;
      }
    });
    await _prefs.setString('colorScheme', _colorScheme.name);
    if (newScheme == AppColorScheme.custom && customColor != null) {
      await _prefs.setInt('customColor', customColor.value);
    } else {
      await _prefs.remove('customColor');
    }
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = _colorScheme == AppColorScheme.custom && _customColor != null
        ? _customColor!
        : _colorScheme.color;

    return MaterialApp(
      title: 'MyNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey.shade100,
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: MainScreen(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
        colorScheme: _colorScheme,
        onChangeColorScheme: _changeColorScheme,
        customColor: _customColor,
      ),
    );
  }
}