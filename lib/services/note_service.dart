import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../utils/crypto_helper.dart';

class NoteService {
  static const _notesKey = 'notes';
  final _crypto = CryptoHelper();

  Future<List<Note>> loadAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesData = prefs.getString(_notesKey);
    if (notesData != null) {
      try {
        final List<dynamic> jsonList = json.decode(notesData);
        return jsonList
            .map((json) => Note.fromMap(json.cast<String, dynamic>()))
            .toList();
      } catch (e) {
        // If parsing fails, return empty list
        return [];
      }
    }
    return [];
  }

  Future<List<Note>> loadNotes() async {
    final notes = await loadAllNotes();
    return notes.where((note) => !note.isSecret).toList();
  }

  Future<List<Note>> getSecretNotes(String pin) async {
    final notes = await loadAllNotes();
    return notes.where((note) => note.isSecret).map((note) {
      try {
        note.content = _crypto.decrypt(note.content, pin, note.id);
      } catch (_) {
        note.content = '[Encrypted] Wrong PIN or Corrupted data';
      }
      return note;
    }).toList();
  }

  Future<void> saveNotes(List<Note> notes, {String? pin}) async {
    // Load all existing notes
    final allNotes = await loadAllNotes();

    // Update or add notes
    for (var note in notes) {
      final index = allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        allNotes[index] = note;
      } else {
        allNotes.add(note);
      }
    }

    // Encrypt secret notes
    final List<Map<String, dynamic>> notesJson = allNotes.map((note) {
      final noteMap = note.toMap();
      if (note.isSecret) {
        if (pin == null || pin.isEmpty) {
          throw Exception('PIN is required to save secret note');
        }
        noteMap['content'] = _crypto.encrypt(note.content, pin, note.id);
      }
      return noteMap;
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(notesJson);
    await prefs.setString(_notesKey, jsonString);
  }
}
