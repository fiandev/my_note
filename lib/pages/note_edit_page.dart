import 'package:flutter/material.dart';
import '../models/note.dart';

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
                // border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.headlineSmall,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _groupController,
              decoration: const InputDecoration(
                labelText: 'Group (Optional)',
                // border: OutlineInputBorder(),
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
