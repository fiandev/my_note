import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:my_note/main.dart'; // For AppColorScheme enum
import 'package:my_note/models/note.dart';
import 'package:my_note/pages/note_edit_page.dart';
import 'note_list_page.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;
  final void Function(AppColorScheme, [Color? customColor]) onChangeColorScheme;
  final Color? customColor;

  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.colorScheme,
    required this.onChangeColorScheme,
    this.customColor,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NoteListPageState> _noteListPageKey = GlobalKey<NoteListPageState>();

  void _navigateToEditPage({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditPage(note: note)),
    );

    if (result != null && result is Note) {
      _noteListPageKey.currentState?.addOrUpdateNoteAndSave(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('MyNote'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue, // Keep the color as a fallback
                image: DecorationImage(
                  image: AssetImage(widget.themeMode == ThemeMode.light
                      ? 'assets/sidebar_bg_light.jpg'
                      : 'assets/sidebar_bg_dark.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Settings',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      icon: Icon(
                        widget.themeMode == ThemeMode.light
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: Colors
                            .white, // Ensure icon is visible on background
                      ),
                      onPressed: widget.onToggleTheme,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Theme Color',
                style: Theme.of(context).textTheme.titleSmall,
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
                              title: const Text('Pick a color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: widget.customColor ??
                                      widget.colorScheme.color,
                                  onColorChanged: (color) {
                                    widget.onChangeColorScheme(
                                        AppColorScheme.custom, color);
                                  },
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Done'),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.green, Colors.blue],
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
                        onTap: () => widget.onChangeColorScheme(scheme),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.color,
                            shape: BoxShape.circle,
                            border: widget.colorScheme == scheme
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    width: 2)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: NoteListPage(key: _noteListPageKey, onNavigateToEditPage: _navigateToEditPage), 
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(),
        tooltip: 'New Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
