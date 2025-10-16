import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class NoteService {
  static const _notesKey = 'notes';

  Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesData = prefs.getString(_notesKey);
    if (notesData != null) {
      final List<dynamic> notesJson = json.decode(notesData);
      return notesJson.map((json) => Note.fromMap(json)).toList();
    }
    return [];
  }

  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> notesJson =
        notes.map((note) => note.toMap()).toList();
    await prefs.setString(_notesKey, json.encode(notesJson));
  }
}