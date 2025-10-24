import 'package:flutter/material.dart';
import 'package:my_note/pages/pin_login.dart';
import 'package:my_note/pages/pin_setup_page.dart';
import 'package:my_note/widgets/category_list.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_card.dart';
import '../widgets/group_header.dart';
import '../widgets/empty_state.dart';
import '../services/pin_service.dart';

class NoteListPage extends StatefulWidget {
  final void Function({Note? note}) onNavigateToEditPage;

  const NoteListPage({
    super.key,
    required this.onNavigateToEditPage,
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
  double _dragHeight = 20; // track tinggi drag

  @override
  void initState() {
    super.initState();
    _dragHeight = 20;
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
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'Undo',
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
                        'No notes in this category.',
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

    double maxHeight = MediaQuery.of(context).size.height * 0.8; // 80% layar

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _dragHeight += details.delta.dy;
                  if (_dragHeight < 0) _dragHeight = 1;
                  if (_dragHeight > maxHeight) _dragHeight = maxHeight;
                });
              },
              onVerticalDragEnd: (details) async {
                if (_dragHeight > maxHeight * 0.5) {
                  // drag lebih dari 50% → pindah halaman
                  final hasPin = await pinService.hasPin();

                  // Store context in a local variable before async gap
                  final currentContext = context;

                  if (!mounted) return;

                  // Use the stored context
                  if (currentContext.mounted) {
                    Navigator.of(currentContext).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              hasPin ? PinLoginPage() : PinSetupPage()),
                    );
                  }
                }

                if (mounted) {
                  setState(() {
                    _dragHeight = 10;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: MediaQuery.of(context).size.width,
                height: _dragHeight,
                color: _dragHeight > 10
                    ? Theme.of(context).focusColor
                    : Theme.of(context).hintColor,
                alignment: Alignment.center,
                child: _dragHeight / maxHeight > 0.1
                    ? Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _dragHeight / maxHeight > 0.5
                                ? Icons.lock_open
                                : Icons.lock,
                            size: 24,
                          ),
                          Text(_dragHeight / maxHeight > 0.5
                              ? "Open Secret Note"
                              : "Secret Note"), // ini masih boleh const karena string tetap
                        ],
                      )
                    : const SizedBox(),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
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
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _deleteNote(item),
                      child: ReorderableDragStartListener(
                        index: _getFlatListIndex(item, flatList),
                        key: Key(item.id),
                        child: NoteCard(
                          key: Key(item.id),
                          note: item,
                          onTap: () => widget.onNavigateToEditPage(note: item),
                          onTogglePin: () => _togglePin(item),
                          index: index,
                          getFlatListIndex: (note) =>
                              _getFlatListIndex(note, flatList),
                        ),
                      ),
                    );
                  }
                  return SizedBox(key: ValueKey('empty_$index'));
                },
                onReorder: (oldIndex, newIndex) {
                  // kode onReorder tetap sama
                },
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 8.0,
                    color: Colors.transparent,
                    child: child,
                  );
                },
                buildDefaultDragHandles: false,
              ),
            ),
          ],
        );
      },
    );
  }

  int _getFlatListIndex(Note note, List<dynamic> flatList) {
    return flatList.indexOf(note);
  }
}
