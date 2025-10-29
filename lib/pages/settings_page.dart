import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:my_note/main.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;
  final void Function(AppColorScheme, [Color? customColor]) onChangeColorScheme;
  final Color? customColor;
  final void Function(bool) onAutoSaveChanged;
  final VoidCallback onChangeLanguage;

  const SettingsPage({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.colorScheme,
    required this.onChangeColorScheme,
    this.customColor,
    required this.onAutoSaveChanged,
    required this.onChangeLanguage,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoSaveEnabled = true; // Default value
  SharedPreferences? _prefs;
  bool _hasChanges = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs != null) {
      setState(() {
        _autoSaveEnabled = _prefs!.getBool('autoSaveEnabled') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAutoSave() async {
    setState(() {
      _autoSaveEnabled = !_autoSaveEnabled;
      _hasChanges = true;
    });
    if (_prefs != null) {
      await _prefs!.setBool('autoSaveEnabled', _autoSaveEnabled);
    }
    widget.onAutoSaveChanged(_autoSaveEnabled);
  }

  void _markChanges() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageItems = [
      DropdownMenuItem(
        value: const Locale('en'),
        child: Text('english'.tr()),
      ),
      DropdownMenuItem(
        value: const Locale('id'),
        child: Text('indonesian'.tr()),
      ),
      DropdownMenuItem(
        value: const Locale('ja'),
        child: Text('japanese'.tr()),
      ),
      DropdownMenuItem(
        value: const Locale('ko'),
        child: Text('korean'.tr()),
      ),
      DropdownMenuItem(
        value: const Locale('zh'),
        child: Text('mandarin'.tr()),
      ),
    ];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_hasChanges) return;

        // Show notification that settings were changed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_updated'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('settings'.tr()),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  // Language Selection
                  ListTile(
                    title: Text('language'.tr()),
                    trailing: DropdownButton<Locale>(
                      value: context.locale,
                      onChanged: (Locale? newLocale) async {
                        if (newLocale != null) {
                          await context.setLocale(newLocale);
                          widget.onChangeLanguage();
                        }
                      },
                      items: languageItems,
                    ),
                  ),
                  const Divider(),

                  // Auto-Save Toggle
                  ListTile(
                    title: Text('auto_save_notes'.tr()),
                    subtitle: Text('auto_save_subtitle'.tr()),
                    trailing: Switch(
                      value: _autoSaveEnabled,
                      onChanged: (value) => _toggleAutoSave(),
                    ),
                  ),
                  const Divider(),

                  // Theme Toggle
                  ListTile(
                    title: Text('dark_mode'.tr()),
                    trailing: Switch(
                      value: widget.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        widget.onToggleTheme();
                        _markChanges();
                      },
                    ),
                  ),
                  const Divider(),

                  // Color Scheme Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'theme_color'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('pick_color'.tr()),
                                    content: SingleChildScrollView(
                                      child: ColorPicker(
                                        pickerColor: widget.customColor ??
                                            widget.colorScheme.color,
                                        onColorChanged: (color) {
                                          widget.onChangeColorScheme(
                                              AppColorScheme.custom, color);
                                          _markChanges();
                                        },
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('done'.tr()),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.green,
                                    Colors.blue
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ),
                        ...AppColorScheme.values
                            .where((s) => s != AppColorScheme.custom)
                            .map((scheme) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                widget.onChangeColorScheme(scheme);
                                _markChanges();
                              },
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                // decoration: BoxDecoration(
                                //   color: scheme.color,
                                //   shape: BoxShape.circle,
                                //   border: widget.colorScheme == scheme
                                //       ? Border.all(
                                //           color: Theme.of(context)
                                //               .colorScheme
                                //               .onSurface,
                                //           width: 2)
                                //       : null,
                                // ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const Divider(),
                ],
              ),
      ),
    );
  }
}
