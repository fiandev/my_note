import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final int index;
  final int Function(Note) getFlatListIndex;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
    required this.index,
    required this.getFlatListIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Pastikan locale 'id_ID' sudah diinisialisasi
    initializeDateFormatting('id_ID', null);

    return ReorderableDragStartListener(
      index: getFlatListIndex(note),
      key: key,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          onLongPress: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Note'),
                content: Text('Are you sure you want to delete "${note.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              onDelete();
            }
          },
            child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Baris judul + tombol pin
                 Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Expanded(
                       child: Text(
                         note.title,
                         style: Theme.of(context).textTheme.titleLarge,
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                     IconButton(
                       icon: Icon(
                         note.isPinned
                             ? Icons.push_pin
                             : Icons.push_pin_outlined,
                         color: note.isPinned
                             ? Theme.of(context).colorScheme.primary
                             : null,
                       ),
                       onPressed: onTogglePin,
                       tooltip: note.isPinned ? 'Unpin Note' : 'Pin Note',
                     ),
                   ],
                 ),

                const SizedBox(height: 8),

                // Konten note
                Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Baris bawah: Group + Tanggal
                Row(
                  children: [
                    if (note.group != null && note.group!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          note.group!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const Spacer(),

                    // Format tanggal
                    Text(
                      DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID')
                          .format(note.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
