import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteEditPage extends StatefulWidget {
  final Note? note;
  final bool autoSaveEnabled;

  const NoteEditPage({super.key, this.note, required this.autoSaveEnabled});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _groupController;
  bool isHasSaved = false;

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

  // void _saveNoteAndPop() {
  //   if (isHasSaved) return;

  //   final title = _titleController.text.trim();
  //   final content = _contentController.text.trim();
  //   final group = _groupController.text.trim();

  //   if (title.isEmpty && content.isEmpty) {
  //     Navigator.of(context).pop(); // keluar tanpa menyimpan
  //     return;
  //   }

  //   final noteToSave = Note(
  //     id: widget.note?.id ?? DateTime.now().toIso8601String(),
  //     title: title,
  //     content: content,
  //     group: group,
  //     isPinned: widget.note?.isPinned ?? false,
  //     createdAt: widget.note?.createdAt ?? DateTime.now(),
  //   );

  //   isHasSaved = true;

  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (mounted) Navigator.of(context).pop(noteToSave);
  //   });
  // }

  void _saveNoteAndPop() {
    if (isHasSaved) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final group = _groupController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content cannot be empty')),
      );
      return;
    }

    if (title.isEmpty && content.isEmpty) {
      Navigator.of(context).pop(); // keluar tanpa menyimpan
      return;
    }

    final noteToSave = Note(
      id: widget.note?.id ?? DateTime.now().toIso8601String(),
      title: title,
      content: content,
      group: group,
      isPinned: widget.note?.isPinned ?? false,
      isSecret: widget.note?.isSecret ?? false,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
    );

    isHasSaved = true;

    if (mounted) Navigator.of(context).pop(noteToSave);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // onPopInvokedWithResult: (didPop, result) async {
      //   if (isHasSaved || didPop) return;

      //   final title = _titleController.text.trim();
      //   final content = _contentController.text.trim();

      //   if (widget.autoSaveEnabled && title.isNotEmpty && content.isNotEmpty) {
      //     _saveNoteAndPop();
      //   } else {
      //     Navigator.of(context).pop();
      //   }
      // },
      onPopInvokedWithResult: (didPop, result) {
        if (isHasSaved || didPop) return;

        final title = _titleController.text.trim();
        final content = _contentController.text.trim();

        if (widget.autoSaveEnabled &&
            (title.isNotEmpty || content.isNotEmpty)) {
          _saveNoteAndPop();
        } else {
          Navigator.of(context).pop();
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveNoteAndPop,
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
                decoration: const InputDecoration(labelText: 'Title'),
                style: Theme.of(context).textTheme.headlineSmall,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _groupController,
                decoration:
                    const InputDecoration(labelText: 'Group (Optional)'),
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
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
