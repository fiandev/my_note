 import 'package:flutter/material.dart';
 import 'package:easy_localization/easy_localization.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
           Text(
             'no_notes_yet'.tr(),
             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                   color: Colors.grey.shade600,
                 ),
           ),
           const SizedBox(height: 8),
           Text(
             'tap_plus_create'.tr(),
             style: TextStyle(color: Colors.grey.shade500),
           ),
        ],
      ),
    );
  }
}