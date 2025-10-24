import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
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
  late final TextEditingController _groupController;
  late final QuillController _contentController;

  List<String> _attachments = [];
  bool isHasSaved = false;
  Timer? _hideToolbarTimer;
  bool _isTyping = false;

  void _onContentChanged() {
    // User mulai mengetik
    if (!_isTyping) {
      setState(() => _isTyping = true);
    }

    // Reset timer setiap kali ada input
    _hideToolbarTimer?.cancel();
    _hideToolbarTimer = Timer(const Duration(seconds: 10), () {
      // Hilangkan toolbar setelah 2 detik tidak ada ketikan
      setState(() => _isTyping = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title);
    _groupController = TextEditingController(text: widget.note?.group);
    _attachments = List.from(widget.note?.attachments ?? []);

    Document doc;
    try {
      if (widget.note?.content != null && widget.note!.content.isNotEmpty) {
        final json = jsonDecode(widget.note!.content);
        doc = Document.fromJson(json);
      } else {
        doc = Document();
      }
    } catch (e) {
      doc = Document()..insert(0, widget.note?.content ?? '');
    }

    _contentController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _hideToolbarTimer?.cancel();
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _groupController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final isImage = path.toLowerCase().endsWith('.jpg') ||
          path.toLowerCase().endsWith('.jpeg') ||
          path.toLowerCase().endsWith('.png') ||
          path.toLowerCase().endsWith('.gif');

      setState(() {
        if (isImage) {
          final imageEmbed = BlockEmbed.image(path);
          final offset = _contentController.selection.baseOffset;
          _contentController.document.insert(offset, imageEmbed);
        } else {
          _attachments.add(path);
        }
      });
    }
  }

  void _saveNoteAndPop() {
    if (isHasSaved) return;

    final title = _titleController.text.trim();
    final contentJson =
        jsonEncode(_contentController.document.toDelta().toJson());
    final contentText = _contentController.document.toPlainText().trim();

    final group = _groupController.text.trim();

    if (title.isEmpty || contentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content cannot be empty')),
      );
      return;
    }

    final noteToSave = Note(
      id: widget.note?.id ?? DateTime.now().toIso8601String(),
      title: title,
      content: contentJson,
      group: group,
      isPinned: widget.note?.isPinned ?? false,
      isSecret: widget.note?.isSecret ?? false,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      attachments: _attachments,
    );

    isHasSaved = true;

    if (mounted) Navigator.of(context).pop(noteToSave);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (isHasSaved || didPop) return;

        final title = _titleController.text.trim();
        final contentText = _contentController.document.toPlainText().trim();

        if (widget.autoSaveEnabled &&
            (title.isNotEmpty || contentText.isNotEmpty)) {
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
              icon: const Icon(Icons.attach_file),
              onPressed: _pickFile,
              tooltip: 'Attach File',
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveNoteAndPop,
              tooltip: 'Save Note',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                        labelText: 'Title',
                        border: InputBorder.none,
                        hintText: 'Enter title here...'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const Divider(height: 8),
                  TextField(
                    controller: _groupController,
                    decoration: const InputDecoration(
                        labelText: 'Group (Optional)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(6),
                        isDense: true),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const Divider(height: 8),
                  const Padding(padding: EdgeInsets.all(24)),
                  Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    child: QuillEditor.basic(
                      controller: _contentController,
                      config: QuillEditorConfig(
                        placeholder: 'Write your rich content here...',
                        embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_isTyping)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Theme.of(context).cardColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: QuillSimpleToolbar(
                    controller: _contentController,
                    config: QuillSimpleToolbarConfig(
                      showClipboardCut: true,
                      showClipboardCopy: true,
                      showClipboardPaste: true,
                      embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
