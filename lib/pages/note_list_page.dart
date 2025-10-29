import 'package:flutter/material.dart';
import 'package:my_note/widgets/category_list.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_card.dart';
import '../widgets/group_header.dart';
import '../widgets/empty_state.dart';
import '../services/pin_service.dart';
import 'package:easy_localization/easy_localization.dart';

class NoteListPage extends StatefulWidget {
  final void Function({Note? note}) onNavigateToEditPage;
  final void Function(List<Note> notes) onShareNote;
  final bool isSelectionMode;
  final List<Note> selectedNotes;
  final void Function(Note? note)? onToggleSelection;

  const NoteListPage({
    super.key,
    required this.onNavigateToEditPage,
    required this.onShareNote,
    this.isSelectionMode = false,
    this.selectedNotes = const [],
    this.onToggleSelection,
  });

  @override
  State<NoteListPage> createState() => NoteListPageState();
}

class NoteListPageState extends State<NoteListPage> {
  final List<Note> _notes = [];
  static const int maxPins = 5;
  final NoteService _noteService = NoteService();
  final PinService pinService = PinService();

  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final loadedNotes = await _noteService.loadNotes();
    if (mounted) {
      setState(() {
        _notes.clear();
        _notes.addAll(loadedNotes);
        _sortNotes();
        _isLoading = false;
      });
    }
  }

  void addOrUpdateNoteAndSave(Note note) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      } else {
        _notes.add(note);
      }
      _sortNotes();
      _saveNotes();
    });
  }

  Future<void> _saveNotes() async {
    await _noteService.saveNotes(_notes);
    await loadNotes(); // Reload to sync with storage
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
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

  void _deleteNote(Note note) {
    final noteIndex = _notes.indexOf(note);
    setState(() {
      _notes.remove(note);
      _saveNotes();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('note_deleted'.tr()),
        action: SnackBarAction(
          label: 'undo'.tr(),
          onPressed: () {
            setState(() {
              _notes.insert(noteIndex, note);
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
        SnackBar(
          content: Text('${'pin_limit'.tr()} $maxPins ${'notes'.tr()}.'),
          duration: const Duration(seconds: 2),
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



  @override
  Widget build(BuildContext context) {
    final categories = _getUniqueCategories();
    final filteredNotes = _selectedCategory == null
        ? _notes
        : _notes.where((note) => note.group == _selectedCategory).toList();
    final groupedNotes = _getGroupedNotes(filteredNotes);

    return Column(
      children: [
        CategoryList(
          categories: categories,
          selectedCategory: _selectedCategory,
          onCategorySelected: _onCategorySelected,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredNotes.isEmpty && _notes.isNotEmpty
                  ? Center(
                      child: Text(
                        'no_notes_category'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : _notes.isEmpty
                      ? const EmptyState()
                      : _buildNotesList(groupedNotes),
        ),
      ],
    );
  }

  Widget _buildNotesList(Map<String, List<Note>> groupedNotes) {
    final flatList = [];
    groupedNotes.forEach((key, value) {
      flatList.add(key);
      flatList.addAll(value);
    });

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: flatList.length,
                itemBuilder: (context, index) {
                  final item = flatList[index];
                  if (item is String) {
                    return GroupHeader(
                      title: item,
                      key: Key('header_$item'),
                    );
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
                      onDismissed: (direction) => _deleteNote(item),
                      child: NoteCard(
                        key: Key(item.id),
                        note: item,
                        onTap: () => widget.onNavigateToEditPage(note: item),
                        onTogglePin: () => _togglePin(item),
                        onDelete: () => _deleteNote(item),
                        onShare: () => widget.onShareNote([item]),
                        index: index,
                        isSelectionMode: widget.isSelectionMode,
                        isSelected: widget.selectedNotes.contains(item),
                        onToggleSelection: () =>
                            widget.onToggleSelection?.call(item),
                      ),
                    );
                  }
                  return SizedBox(key: ValueKey('empty_$index'));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
