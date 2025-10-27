import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:my_note/services/note_service.dart';
import 'package:my_note/utils/crypto_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const _pinKey = 'user_pin_hash';
  final NoteService _noteService;
  final CryptoHelper _cryptoHelper;

  PinService()
      : _noteService = NoteService(),
        _cryptoHelper = CryptoHelper();

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hashPin(pin));
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  Future<void> resetPin(String newPin, String oldPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_pinKey);

    if (storedPin != null) {
      final notes = await _noteService.loadAllNotes();
      final decryptedNotes = notes.map((note) {
        if (note.isSecret) {
        try {
          note.content =
              _cryptoHelper.decrypt(note.content, oldPin, note.id);
        } catch (_) {
            note.content = '[Encrypted] Wrong PIN or Corrupted data';
          }
        }
        return note;
      }).toList();

      await _noteService.saveNotes(decryptedNotes, pin: newPin);
    }

    await prefs.remove(_pinKey);
    await savePin(newPin);
  }
}
