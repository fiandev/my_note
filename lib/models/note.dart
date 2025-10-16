class Note {
  String id;
  String title;
  String content;
  String? group;
  bool isPinned;
  DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.group,
    this.isPinned = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'group': group,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      group: map['group'],
      isPinned: map['isPinned'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}