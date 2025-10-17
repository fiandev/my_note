import 'package:flutter_test/flutter_test.dart';
import 'package:my_note/models/note.dart';

void main() {
  group('Simple Unit Test', () {
    test('Addition works correctly', () {
      expect(1 + 1, 2);
    });

    test('Subtraction works correctly', () {
      expect(5 - 2, 3);
    });

    test('Note.fromMap and toMap work correctly', () {
      final now = DateTime.now();
      final note = Note(
        id: '123',
        title: 'Test Note',
        content: 'This is a test note content.',
        group: 'Work',
        isPinned: true,
        createdAt: now,
      );

      final map = note.toMap();
      expect(map['id'], '123');
      expect(map['title'], 'Test Note');
      expect(map['content'], 'This is a test note content.');
      expect(map['group'], 'Work');
      expect(map['isPinned'], true);
      expect(DateTime.parse(map['createdAt']), now);

      final newNote = Note.fromMap(map);
      expect(newNote.id, '123');
      expect(newNote.title, 'Test Note');
      expect(newNote.content, 'This is a test note content.');
      expect(newNote.group, 'Work');
      expect(newNote.isPinned, true);
      expect(newNote.createdAt.toIso8601String(), now.toIso8601String());
    });
  });
}
