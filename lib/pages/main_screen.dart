import 'package:flutter/material.dart';
import 'package:my_note/main.dart'; // For AppColorScheme enum
import 'package:my_note/models/note.dart';
import 'package:my_note/pages/note_edit_page.dart';
import 'package:my_note/pages/settings_page.dart';
import 'package:my_note/pages/pin_login.dart';
import 'package:my_note/pages/pin_setup_page.dart';
import 'package:my_note/pages/secret_note_list_page.dart';
import 'package:my_note/services/pin_service.dart';
import 'package:my_note/services/note_service.dart';
import 'package:my_note/utils/crypto_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;
import 'note_list_page.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;
  final void Function(AppColorScheme, [Color? customColor]) onChangeColorScheme;
  final Color? customColor;
  final bool autoSaveEnabled;
  final void Function(bool) onAutoSaveChanged;
  final VoidCallback onChangeLanguage;

  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.colorScheme,
    required this.onChangeColorScheme,
    this.customColor,
    required this.autoSaveEnabled,
    required this.onAutoSaveChanged,
    required this.onChangeLanguage,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NoteListPageState> _noteListPageKey =
      GlobalKey<NoteListPageState>();
  final PinService _pinService = PinService();
  final NoteService _noteService = NoteService();
  final CryptoHelper _crypto = CryptoHelper();
  bool _isSelectionMode = false;
  final List<Note> _selectedNotes = [];

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

  void _shareNote(List<Note> notes) async {
    if (notes.isEmpty) return;

    // Ambil snapshot agar tidak hilang saat async
    final selectedNotes = List<Note>.from(notes);

    final isBulk = selectedNotes.length > 1;
    final title = isBulk
        ? 'Share ${selectedNotes.length} Notes'
        : 'Share Note: ${selectedNotes.first.title}';

    // Load all notes including secret
    final allNotes = await _noteService.loadAllNotes();

    // Map untuk lookup
    final allMap = {for (var n in allNotes) n.id: n};
    final shareNotes = selectedNotes.map((n) => allMap[n.id] ?? n).toList();

    print(
        'All notes: ${allNotes.length}, Selected: ${selectedNotes.length}, Share: ${shareNotes.length}');

    // Get local IP
    final interfaces = await NetworkInterface.list();
    String ip;
    try {
      ip = interfaces
          .firstWhere(
            (iface) =>
                iface.name.contains('wlan') ||
                iface.name.contains('eth') ||
                iface.name.contains('Wi-Fi') ||
                iface.name.contains('Ethernet'),
            orElse: () =>
                interfaces.firstWhere((iface) => iface.addresses.isNotEmpty),
          )
          .addresses
          .first
          .address;
    } catch (e) {
      ip = '127.0.0.1'; // Fallback to localhost
    }

    // Start HTTP server
    final handler = shelf.Pipeline().addHandler((shelf.Request request) {
      print('Request path: ${request.url.path}');
      if (request.url.path == '/notes' || request.url.path == 'notes') {
        print('Sharing ${shareNotes.length} notes');
        final notesData = jsonEncode(shareNotes.map((n) => n.toMap()).toList());
        return shelf.Response.ok(notesData,
            headers: {'Content-Type': 'application/json'});
      }
      return shelf.Response.notFound('Not found');
    });

    HttpServer server;
    try {
      server = await io.serve(handler, ip, 8080);
    } catch (e) {
      server = await io.serve(handler, ip, 0);
    }
    print('Server running on http://${server.address.host}:${server.port}');

    final networkData =
        jsonEncode({'ip': server.address.host, 'port': server.port});
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 200,
          height: 250,
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 15), textAlign: TextAlign.center),
              QrImageView(
                data: networkData,
                version: QrVersions.auto,
                size: 200.0,
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              server.close();
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _scanQRCode() async {
    // Check if platform supports QR scanning
    if (!(Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('QR scanning is not supported on this platform')),
      );
      return;
    }

    // Check if platform supports camera permission
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Camera permission is required to scan QR codes')),
        );
        return;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('scan_qr'.tr())),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null && result is String) {
      _processScannedData(result);
    }
  }

  void _processScannedData(String data) async {
    if (!mounted) return;
    try {
      final Map<String, dynamic> networkData = jsonDecode(data);
      final ip = networkData['ip'];
      final port = networkData['port'];
      if (ip != null && port != null) {
        // Connect via HTTP with timeout
        try {
          final response = await http
              .get(Uri.parse('http://$ip:$port/notes'))
              .timeout(const Duration(seconds: 10));
          print('Response status: ${response.statusCode}');
          print('Response body length: ${response.body.length}');
          if (response.statusCode == 200) {
            try {
              final List<dynamic> notesJson = jsonDecode(response.body);
              final notes =
                  notesJson.map((json) => Note.fromMap(json)).toList();
              _handleReceivedNotes(notes);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to parse notes: $e')),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Server responded with error: ${response.statusCode}')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to connect to server: $e')),
            );
          }
        }
      } else {
        // Fallback to old QR
        final Map<String, dynamic> noteMap = jsonDecode(data);
        final note = Note.fromMap(noteMap);
        _handleReceivedNotes([note]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import notes: Invalid data')),
        );
      }
    }
  }

  void _handleReceivedNotes(List<Note> notes) async {
    if (!mounted) return;
    final hasSecret = notes.any((n) => n.isSecret);
    if (hasSecret) {
      final pin = await _promptPin();
      if (pin != null && pin.isNotEmpty) {
        for (var note in notes) {
          if (note.isSecret) {
            try {
              note.content = _crypto.decrypt(note.content, pin, note.id);
            } catch (e) {
              note.content = '[Encrypted] Wrong PIN or Corrupted data';
            }
          }
          _noteListPageKey.currentState?.addOrUpdateNoteAndSave(note);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${notes.length} notes imported successfully')),
          );
        }
      }
    } else {
      for (var note in notes) {
        _noteListPageKey.currentState?.addOrUpdateNoteAndSave(note);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${notes.length} notes imported successfully')),
        );
      }
    }
  }

  Future<String?> _promptPin() async {
    if (!mounted) return null;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter PIN for Secret Notes'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(hintText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToSecretNotes() async {
    final hasPin = await _pinService.hasPin();
    if (!mounted) return;

    final nextPage = hasPin ? PinLoginPage() : PinSetupPage();

    final pinResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );

    if (pinResult is String && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SecretNoteListPage(pin: pinResult, onShareNote: _shareNote),
        ),
      );
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
            Text(
              'app_name'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8), // jarak antara title dan tombol
            Row(
              children: [
                if (Platform.isAndroid ||
                    Platform.isIOS ||
                    Platform.isMacOS ||
                    Platform.isWindows)
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanQRCode,
                    tooltip: 'scan_qr'.tr(),
                  ),
                IconButton(
                  icon: const Icon(Icons.lock_outline),
                  onPressed: _navigateToSecretNotes,
                  tooltip: 'secret_notes'.tr(),
                ),
                if (!_isSelectionMode)
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = true;
                      });
                    },
                    tooltip: 'Select Notes',
                  ),
                if (_isSelectionMode)
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      print(
                          'Share button pressed, selected: ${_selectedNotes.length}');
                      if (_selectedNotes.isNotEmpty) {
                        _shareNote(_selectedNotes);
                      }
                      setState(() {
                        _isSelectionMode = false;
                        _selectedNotes.clear();
                      });
                    },
                    tooltip: 'Share Selected',
                  ),
                if (_isSelectionMode)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedNotes.clear();
                      });
                    },
                    tooltip: 'Cancel Selection',
                  ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ],
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
              title: Text('settings'.tr()),
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
                      onChangeLanguage: widget.onChangeLanguage,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: NoteListPage(
        key: _noteListPageKey,
        onNavigateToEditPage: _navigateToEditPage,
        onShareNote: _shareNote,
        isSelectionMode: _isSelectionMode,
        selectedNotes: _selectedNotes,
        onToggleSelection: (note) {
          print('Toggle selection: ${note?.title}');
          setState(() {
            if (note == null) {
              _isSelectionMode = false;
              _selectedNotes.clear();
            } else {
              if (_selectedNotes.contains(note)) {
                _selectedNotes.remove(note);
              } else {
                _selectedNotes.add(note);
              }
            }
          });
          print('Selected notes: ${_selectedNotes.length}');
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(),
        tooltip: 'new_note'.tr(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
