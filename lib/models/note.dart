import 'dart:convert';

class Note {
  String id;
  String title;
  String content;
  String? group;
  bool isPinned;
  bool isSecret;
  DateTime createdAt;

  // Tambahan baru → list path file/gambar
  List<String> attachments;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.group,
    this.isPinned = false,
    required this.createdAt,
    this.isSecret = false,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'group': group,
      'isSecret': isSecret,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'attachments': attachments,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    List<String> attachments = [];
    if (map['attachments'] != null) {
      if (map['attachments'] is String) {
        attachments = List<String>.from(json.decode(map['attachments']));
      } else if (map['attachments'] is List) {
        attachments = List<String>.from(map['attachments']);
      }
    }
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      group: map['group'],
      isPinned: map['isPinned'] ?? false,
      isSecret: map['isSecret'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      attachments: attachments,
    );
  }
}
