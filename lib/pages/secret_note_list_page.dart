 import 'package:flutter/material.dart';
 import 'package:my_note/pages/note_edit_page.dart';
 import 'package:my_note/pages/pin_setup_page.dart';
 import 'package:my_note/widgets/category_list.dart';
 import '../models/note.dart';
 import '../services/note_service.dart';
 import '../services/pin_service.dart';
 import '../widgets/note_card.dart';
 import '../widgets/group_header.dart';
 import '../widgets/empty_state.dart';
 import 'package:easy_localization/easy_localization.dart';

class SecretNoteListPage extends StatefulWidget {
  final String pin;

  const SecretNoteListPage({
    super.key,
    required this.pin,
  });

  @override
  State<SecretNoteListPage> createState() => _SecretNoteListPageState();
}

class _SecretNoteListPageState extends State<SecretNoteListPage> {
  final List<Note> _notes = [];
  final NoteService _noteService = NoteService();
  final PinService _pinService = PinService();

  bool _isLoading = true;
  String? _selectedCategory;
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
           MaterialPageRoute(builder: (context) => PinSetupPage(isForReset: true)),
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
            title: Text(context.tr('secret_notes')),
            actions: [
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
                 onTap: () async {
                   final updated = await Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) =>
                           NoteEditPage(note: item, autoSaveEnabled: true),
                     ),
                   );

                   if (updated is Note) {
                     addOrUpdateNoteAndSave(updated);
                   }
                 },
                 onTogglePin: () => _togglePin(item),
                 onDelete: () => _deleteNote(item),
               ),
           );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
