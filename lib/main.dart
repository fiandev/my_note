import 'package:flutter/material.dart';
import 'pages/note_list_page.dart';

void main() {
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

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _changeColorScheme(AppColorScheme newScheme, [Color? customColor]) {
    setState(() {
      _colorScheme = newScheme;
      if (newScheme == AppColorScheme.custom) {
        _customColor = customColor;
      }
    });
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
      home: NoteListPage(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
        colorScheme: _colorScheme,
        onChangeColorScheme: _changeColorScheme,
        customColor: _customColor,
      ),
    );
  }
}