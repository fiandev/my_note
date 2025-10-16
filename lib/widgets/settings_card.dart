import 'package:flutter/material.dart';
import 'package:my_note/models/ui_models.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.cardInfo});

  final CardInfo cardInfo;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardInfo.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(cardInfo.icon, size: 30, color: cardInfo.color),
            const Spacer(),
            Text(
              cardInfo.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: cardInfo.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}