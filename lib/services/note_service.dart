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
      final List<dynamic> notesJson = json.decode(notesData);
      return notesJson.map((json) => Note.fromMap(json)).toList();
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
        // Jika PIN salah, konten tidak bisa didekripsi
        note.content = '[Encrypted] Wrong PIN or Corrupted data';
      }
      return note;
    }).toList();
  }

  /// Simpan semua notes — otomatis encrypt konten untuk note yang isSecret == true
  Future<void> saveNotes(List<Note> notes, {String? pin}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> notesJson = notes.map((note) {
      final noteMap = note.toMap();

      if (note.isSecret) {
        if (pin == null || pin.isEmpty) {
          throw Exception('PIN is required to save secret note');
        }
        noteMap['content'] =
            _crypto.encrypt(note.content, pin, note.id); // encrypt content
      }

      return noteMap;
    }).toList();

    await prefs.setString(_notesKey, json.encode(notesJson));
  }
}
