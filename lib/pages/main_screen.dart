import 'package:flutter/material.dart';
import 'package:my_note/main.dart'; // For AppColorScheme enum
import 'package:my_note/models/note.dart';
import 'package:my_note/pages/note_edit_page.dart';
import 'package:my_note/pages/settings_page.dart';
import 'note_list_page.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;
  final void Function(AppColorScheme, [Color? customColor]) onChangeColorScheme;
  final Color? customColor;
  final bool autoSaveEnabled;
  final void Function(bool) onAutoSaveChanged;

  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.colorScheme,
    required this.onChangeColorScheme,
    this.customColor,
    required this.autoSaveEnabled,
    required this.onAutoSaveChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NoteListPageState> _noteListPageKey =
      GlobalKey<NoteListPageState>();

  void _navigateToEditPage({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NoteEditPage(
              note: note, autoSaveEnabled: widget.autoSaveEnabled)),
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
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        titleSpacing: 12, // biar kontrol jarak penuh di Row
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MyNote',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8), // jarak antara title dan tombol
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ],
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
                      '',
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
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      onToggleTheme: widget.onToggleTheme,
                      themeMode: widget.themeMode,
                      colorScheme: widget.colorScheme,
                      onChangeColorScheme: widget.onChangeColorScheme,
                      customColor: widget.customColor,
                      onAutoSaveChanged: widget.onAutoSaveChanged,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: NoteListPage(
          key: _noteListPageKey, onNavigateToEditPage: _navigateToEditPage),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(),
        tooltip: 'New Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
