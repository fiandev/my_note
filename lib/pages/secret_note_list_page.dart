import 'package:flutter/material.dart';
import 'package:my_note/pages/note_edit_page.dart';
import 'package:my_note/pages/pin_setup_page.dart';
import 'package:my_note/pages/pin_input_page.dart';
import 'package:my_note/widgets/category_list.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../services/pin_service.dart';
import '../utils/crypto_helper.dart';
import '../widgets/note_card.dart';
import '../widgets/group_header.dart';
import '../widgets/empty_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:qr_flutter/qr_flutter.dart';

class SecretNoteListPage extends StatefulWidget {
  final String pin;
  final void Function(List<Note> notes)? onShareNote;

  const SecretNoteListPage({
    super.key,
    required this.pin,
    this.onShareNote,
  });

  @override
  State<SecretNoteListPage> createState() => _SecretNoteListPageState();
}

class _SecretNoteListPageState extends State<SecretNoteListPage> {
  final List<Note> _notes = [];
  final NoteService _noteService = NoteService();
  final PinService _pinService = PinService();
  final CryptoHelper _crypto = CryptoHelper();

  bool _isLoading = true;
  String? _selectedCategory;
  bool _isSelectionMode = false;
  final List<Note> _selectedNotes = [];
  static const int maxPins = 5;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final loadedNotes = await _noteService.getSecretNotes(widget.pin);

    if (mounted) {
      setState(() {
        _notes
          ..clear()
          ..addAll(loadedNotes);
        _sortNotes();
        _isLoading = false;
      });
    }
  }

  void addOrUpdateNoteAndSave(Note note) {
    final secretNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      group: note.group,
      isPinned: note.isPinned,
      isSecret: true,
      createdAt: note.createdAt,
    );

    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = secretNote;
      } else {
        _notes.add(secretNote);
      }
      _sortNotes();
    });

    _saveNotes();
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void _deleteNote(Note note) async {
    final noteIndex = _notes.indexOf(note);
    setState(() {
      _notes.remove(note);
    });
    await _saveNotes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('note_deleted')),
          action: SnackBarAction(
            label: context.tr('undo'),
            onPressed: () async {
              setState(() {
                _notes.insert(noteIndex, note);
                _sortNotes();
              });
              await _saveNotes();
            },
          ),
        ),
      );
    }
  }

  Future<void> _saveNotes() async {
    await _noteService.saveNotes(_notes, pin: widget.pin);
    await loadNotes(); // Reload to sync with storage
  }

  void _togglePin(Note note) {
    final pinnedCount = _notes.where((n) => n.isPinned).length;
    if (!note.isPinned && pinnedCount >= maxPins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('pin_limit')} 5 ${context.tr('notes')}.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      note.isPinned = !note.isPinned;
      _sortNotes();
    });
    _saveNotes();
  }

  Map<String, List<Note>> _getGroupedNotes(List<Note> notes) {
    final Map<String, List<Note>> groupedNotes = {};
    final List<Note> pinnedNotes = [];
    final List<Note> otherNotes = [];

    for (var note in notes) {
      if (note.isPinned) {
        pinnedNotes.add(note);
      } else {
        otherNotes.add(note);
      }
    }

    if (pinnedNotes.isNotEmpty) groupedNotes['Pinned'] = pinnedNotes;

    for (var note in otherNotes) {
      final key = (note.group?.trim().isNotEmpty ?? false)
          ? note.group!
          : 'Uncategorized';
      groupedNotes.putIfAbsent(key, () => []).add(note);
    }

    final sortedEntries = groupedNotes.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Pinned') return -1;
        if (b.key == 'Pinned') return 1;
        if (a.key == 'Uncategorized') return 1;
        if (b.key == 'Uncategorized') return -1;
        return a.key.compareTo(b.key);
      });

    return Map.fromEntries(sortedEntries);
  }

  List<String> _getUniqueCategories() {
    final categories = <String>{};
    for (var note in _notes) {
      if (note.group != null && note.group!.trim().isNotEmpty) {
        categories.add(note.group!);
      }
    }
    return ['All', ...categories.toList()..sort()];
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category == 'All' ? null : category;
    });
  }

  void _toggleSelection(Note note) {
    setState(() {
      if (_selectedNotes.contains(note)) {
        _selectedNotes.remove(note);
      } else {
        _selectedNotes.add(note);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotes.clear();
    });
  }

  void _shareSelectedNotes() async {
    if (_selectedNotes.isEmpty && _isSelectionMode) return;

    final isBulk = _selectedNotes.length > 1;
    final title = isBulk
        ? 'Share ${_selectedNotes.length} Secret Notes'
        : 'Share Secret Note: ${_selectedNotes.first.title}';

    // Encrypt secret notes before sharing
    final encryptedNotes = _selectedNotes.map((note) {
      final map = note.toMap();
      if (note.isSecret) {
        final encryptedContent =
            _crypto.encrypt(note.content, widget.pin, note.id);
        print(
            'Encrypted content for note ${note.id}: ${encryptedContent.substring(0, 20)}...'); // Debug
        map['content'] = encryptedContent;
      }
      return map;
    }).toList();

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
        print('Sharing ${encryptedNotes.length} notes');
        final notesData = jsonEncode(encryptedNotes);
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

    _clearSelection();
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
        // title: ,
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

  Future<void> _resetPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('reset_pin')),
        content: Text(context.tr('reset_pin_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('reset')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      String? newPin;
      if (mounted) {
        newPin = await Navigator.push<String>(
          context,
          MaterialPageRoute(
              builder: (context) => PinSetupPage(isForReset: true)),
        );
      }

      if (newPin != null) {
        await _pinService.resetPin(newPin, widget.pin);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to main screen
        }
      }
    }
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
      // Try to parse as network data first
      final Map<String, dynamic> networkData = jsonDecode(data);
      final ip = networkData['ip'];
      final port = networkData['port'];
      if (ip != null && port != null) {
        // Connect via HTTP with timeout
        try {
          final response = await http
              .get(Uri.parse('http://$ip:$port/notes'))
              .timeout(const Duration(seconds: 10));
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
        // Try to parse as direct notes data
        try {
          final List<dynamic> notesJson = jsonDecode(data);
          final notes = notesJson.map((json) => Note.fromMap(json)).toList();
          _handleReceivedNotes(notes);
        } catch (e) {
          // Fallback to single note
          final Map<String, dynamic> noteMap = jsonDecode(data);
          final note = Note.fromMap(noteMap);
          _handleReceivedNotes([note]);
        }
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
      bool pinCorrect = false;
      while (!pinCorrect && mounted) {
        final pin = await _promptPin();
        if (pin == null || pin.isEmpty) {
          // Cancel
          return;
        }
        bool allDecrypted = true;
        for (var note in notes) {
          if (note.isSecret) {
            try {
              final decryptedContent =
                  _crypto.decrypt(note.content, pin, note.id);
              print(
                  'Decrypted content for note ${note.id}: ${decryptedContent.substring(0, 20)}...'); // Debug
              note.content = decryptedContent;
            } catch (e) {
              print('Decrypt failed for note ${note.id}: $e'); // Debug
              note.content = '[Encrypted] Wrong PIN or Corrupted data';
              allDecrypted = false;
            }
          }
        }
        if (allDecrypted) {
          pinCorrect = true;
          for (var note in notes) {
            addOrUpdateNoteAndSave(note);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${notes.length} notes imported successfully')),
            );
          }
        } else {
          // PIN salah, loop lagi
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Wrong PIN, try again')),
            );
          }
        }
      }
    } else {
      for (var note in notes) {
        addOrUpdateNoteAndSave(note);
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
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PinInputPage(
          title: 'Enter PIN for Secret Notes',
          hint: 'Enter PIN to decrypt secret notes',
          onSubmit: (pin) => Navigator.of(context).pop(pin),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getUniqueCategories();
    final filteredNotes = _selectedCategory == null
        ? _notes
        : _notes.where((note) => note.group == _selectedCategory).toList();
    final groupedNotes = _getGroupedNotes(filteredNotes);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isSelectionMode
              ? '${_selectedNotes.length} selected'
              : context.tr('secret_notes')),
          actions: [
            if (Platform.isAndroid ||
                Platform.isIOS ||
                Platform.isMacOS ||
                Platform.isWindows)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _scanQRCode,
                tooltip: 'scan_qr'.tr(),
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
                onPressed: _shareSelectedNotes,
                tooltip: 'Share Selected',
              ),
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
                tooltip: 'Cancel Selection',
              ),
            IconButton(
              icon: const Icon(Icons.lock_reset),
              onPressed: _resetPin,
              tooltip: context.tr('reset_pin_tooltip'),
            ),
          ],
        ),
        body: Column(
          children: [
            CategoryList(
              categories: categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                      ? const EmptyState()
                      : _buildNotesList(groupedNotes),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final newNote = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteEditPage(autoSaveEnabled: true),
              ),
            );
            if (newNote is Note) addOrUpdateNoteAndSave(newNote);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildNotesList(Map<String, List<Note>> groupedNotes) {
    final flatList = [];
    groupedNotes.forEach((key, value) {
      flatList.add(key);
      flatList.addAll(value);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: flatList.length,
      itemBuilder: (context, index) {
        final item = flatList[index];
        if (item is String) {
          return GroupHeader(title: item, key: Key('header_$item'));
        }
        if (item is Note) {
          return Dismissible(
            key: Key(item.id),
            direction: DismissDirection.horizontal,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteNote(item),
            child: NoteCard(
              note: item,
              index: index,
              onTap: _isSelectionMode
                  ? () => _toggleSelection(item)
                  : () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NoteEditPage(note: item, autoSaveEnabled: true),
                        ),
                      );
                      if (updated != null) {
                        _saveNotes();
                      }
                    },
              onTogglePin: () => _togglePin(item),
              onDelete: () => _deleteNote(item),
              onShare: () => _shareNote([item]),
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedNotes.contains(item),
              onToggleSelection: () => _toggleSelection(item),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
