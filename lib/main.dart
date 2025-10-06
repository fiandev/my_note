import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Model Note tetap sama
class Note {
  String id;
  String title;
  String content;
  String? group;
  bool isPinned;
  DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.group,
    this.isPinned = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'group': group,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      group: map['group'],
      isPinned: map['isPinned'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpleNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade100,
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: NoteListPage(onToggleTheme: _toggleTheme, themeMode: _themeMode),
    );
  }
}

class NoteListPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const NoteListPage({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  final List<Note> _notes = [];
  bool _isLoading = true;
  static const int maxPins = 5;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesData = prefs.getString('notes');
    if (notesData != null) {
      final List<dynamic> notesJson = json.decode(notesData);
      setState(() {
        _notes.clear();
        _notes.addAll(notesJson.map((json) => Note.fromMap(json)).toList());
        _sortNotes();
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> notesJson =
        _notes.map((note) => note.toMap()).toList();
    await prefs.setString('notes', json.encode(notesJson));
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Map<String, List<Note>> _getGroupedNotes() {
    final Map<String, List<Note>> groupedNotes = {};
    final List<Note> pinnedNotes = [];
    final List<Note> otherNotes = [];

    for (var note in _notes) {
      if (note.isPinned) {
        pinnedNotes.add(note);
      } else {
        otherNotes.add(note);
      }
    }

    if (pinnedNotes.isNotEmpty) {
      groupedNotes['Pinned'] = pinnedNotes;
    }

    for (var note in otherNotes) {
      final groupKey =
          note.group?.trim().isNotEmpty == true ? note.group! : 'Uncategorized';
      if (groupedNotes.containsKey(groupKey)) {
        groupedNotes[groupKey]!.add(note);
      } else {
        groupedNotes[groupKey] = [note];
      }
    }

    final sortedGroupedNotes =
        Map<String, List<Note>>.fromEntries(groupedNotes.entries.toList()
          ..sort((a, b) {
            if (a.key == 'Pinned') return -1;
            if (b.key == 'Pinned') return 1;
            if (a.key == 'Uncategorized') return 1;
            if (b.key == 'Uncategorized') return -1;
            return a.key.compareTo(b.key);
          }));

    return sortedGroupedNotes;
  }

  // *** PERUBAHAN 1: Mengganti showDialog dengan navigasi ke halaman baru ***
  void _navigateToEditPage({Note? note}) async {
    // Tunggu hasil dari NoteEditPage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditPage(note: note)),
    );

    // Jika ada hasil (note baru atau yang diedit), perbarui state
    if (result != null && result is Note) {
      setState(() {
        if (note == null) {
          // Tambahkan note baru
          _notes.add(result);
        } else {
          // Perbarui note yang ada
          final index = _notes.indexWhere((n) => n.id == result.id);
          if (index != -1) {
            _notes[index] = result;
          }
        }
        _sortNotes();
        _saveNotes();
      });
    }
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.remove(note);
      _saveNotes();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _notes.add(note);
              _sortNotes();
              _saveNotes();
            });
          },
        ),
      ),
    );
  }

  void _togglePin(Note note) {
    final pinnedCount = _notes.where((n) => n.isPinned).length;
    if (!note.isPinned && pinnedCount >= maxPins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only pin a maximum of $maxPins notes.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      note.isPinned = !note.isPinned;
      _sortNotes();
      _saveNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotes = _getGroupedNotes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpleNote'),
        actions: [
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.light
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(groupedNotes),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(), // Panggil method navigasi
        tooltip: 'New Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create a new note.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(Map<String, List<Note>> groupedNotes) {
    final flatList = [];
    groupedNotes.forEach((key, value) {
      flatList.add(key);
      flatList.addAll(value);
    });

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: flatList.length,
      itemBuilder: (context, index) {
        final item = flatList[index];
        if (item is String) {
          return _buildGroupHeader(item, Key('header_$item'));
        } else if (item is Note) {
          return _buildNoteCard(item, Key(item.id));
        }
        return const SizedBox.shrink();
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }

          final item = flatList.removeAt(oldIndex);
          if (item is String) {
            flatList.insert(oldIndex, item);
            return;
          }

          while (newIndex < flatList.length && flatList[newIndex] is String) {
            newIndex++;
          }

          flatList.insert(newIndex, item);

          _notes.clear();
          for (var element in flatList) {
            if (element is Note) {
              _notes.add(element);
            }
          }
          _sortNotes();
          _saveNotes();
        });
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 8.0,
          color: Colors.transparent,
          child: child,
        );
      },
      buildDefaultDragHandles: false,
    );
  }

  Widget _buildGroupHeader(String title, Key key) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, Key key) {
    return ReorderableDragStartListener(
      index: _getFlatListIndex(note),
      key: key,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        elevation: 2,
        child: InkWell(
          onTap: () =>
              _navigateToEditPage(note: note), // Panggil method navigasi
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        note.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        color: note.isPinned
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => _togglePin(note),
                      tooltip: note.isPinned ? 'Unpin Note' : 'Pin Note',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (note.group != null && note.group!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          note.group!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      DateFormat.yMMMd().format(note.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => _deleteNote(note),
                      tooltip: 'Delete Note',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getFlatListIndex(Note note) {
    final groupedNotes = _getGroupedNotes();
    int index = 0;
    for (var entry in groupedNotes.entries) {
      index++;
      for (var n in entry.value) {
        if (n.id == note.id) {
          return index;
        }
        index++;
      }
    }
    return -1;
  }
}

// *** PERUBAHAN 2: Widget Halaman Baru untuk Menambah/Mengedit Catatan ***
class NoteEditPage extends StatefulWidget {
  final Note? note;

  const NoteEditPage({super.key, this.note});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _groupController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title);
    _contentController = TextEditingController(text: widget.note?.content);
    _groupController = TextEditingController(text: widget.note?.group);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text;
    final content = _contentController.text;
    final group = _groupController.text;

    if (title.isNotEmpty && content.isNotEmpty) {
      final noteToSave = Note(
        id: widget.note?.id ?? DateTime.now().toIso8601String(),
        title: title,
        content: content,
        group: group,
        isPinned: widget.note?.isPinned ?? false,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
      );
      // Kirim note kembali ke halaman sebelumnya
      Navigator.pop(context, noteToSave);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and content cannot be empty.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.headlineSmall,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _groupController,
              decoration: const InputDecoration(
                labelText: 'Group (Optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: InputBorder.none,
                hintText: 'Write your note here...',
              ),
              maxLines: null, // Memungkinkan baris tidak terbatas
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
