import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:my_note/widgets/category_list.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'note_edit_page.dart';
import '../widgets/note_card.dart';
import '../widgets/group_header.dart';
import '../widgets/empty_state.dart';

import 'package:my_note/main.dart';

class NoteListPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;
  final void Function(AppColorScheme, [Color? customColor]) onChangeColorScheme;
  final Color? customColor;

  const NoteListPage({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.colorScheme,
    required this.onChangeColorScheme,
    this.customColor,
  });

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  final List<Note> _notes = [];
  bool _isLoading = true;
  static const int maxPins = 5;
  final NoteService _noteService = NoteService();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
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

  void _navigateToEditPage({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditPage(note: note)),
    );

    if (result != null && result is Note) {
      setState(() {
        if (note == null) {
          _notes.add(result);
        } else {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyNote'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                  pickerColor: widget.customColor ?? widget.colorScheme.color,
                                  onColorChanged: (color) {
                                    widget.onChangeColorScheme(AppColorScheme.custom, color);
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
                  ...AppColorScheme.values.where((s) => s != AppColorScheme.custom).map((scheme) {
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
                                ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined),
              title: const Text('Toggle Theme'),
              onTap: widget.onToggleTheme,
            ),
          ],
        ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(),
        tooltip: 'New Note',
        child: const Icon(Icons.add),
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
          return GroupHeader(title: item, key: Key('header_$item'));
        } else if (item is Note) {
          return NoteCard(
            key: Key(item.id),
            note: item,
            onTap: () => _navigateToEditPage(note: item),
            onTogglePin: () => _togglePin(item),
            onDelete: () => _deleteNote(item),
            index: index,
            getFlatListIndex: (note) => _getFlatListIndex(note, flatList),
          );
        }
        return const SizedBox.shrink();
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          // Find the item being moved
          final item = flatList[oldIndex];

          // If it's a header, do nothing
          if (item is String) {
            return;
          }

          // Adjust newIndex based on headers
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }

          // Find the new group for the moved item
          String? newGroup;
          int headerIndex = newIndex - 1;
          while (headerIndex >= 0) {
            if (flatList[headerIndex] is String) {
              newGroup = flatList[headerIndex] as String;
              break;
            }
            headerIndex--;
          }

          // Update the note's properties
          if (item is Note) {
            final originalNote = _notes.firstWhere((n) => n.id == item.id);
            int noteIndex = _notes.indexOf(originalNote);

            if (newGroup == 'Pinned') {
              originalNote.isPinned = true;
            } else {
              originalNote.isPinned = false;
              if (newGroup == 'Uncategorized') {
                originalNote.group = null;
              } else {
                originalNote.group = newGroup;
              }
            }
            
            _notes.removeAt(noteIndex);
            
            int newNoteIndex = 0;
            for (int i = 0; i < newIndex; i++) {
              if (flatList[i] is Note) {
                newNoteIndex++;
              }
            }

            if (newNoteIndex > _notes.length) {
              newNoteIndex = _notes.length;
            }
            _notes.insert(newNoteIndex, originalNote);
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

  int _getFlatListIndex(Note note, List<dynamic> flatList) {
    return flatList.indexOf(note);
  }
}
