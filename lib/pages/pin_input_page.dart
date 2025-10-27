import 'package:flutter/material.dart';
import '../widgets/pin_input.dart';

class PinInputPage extends StatefulWidget {
  final String title;
  final String hint;
  final void Function(String) onSubmit;

  const PinInputPage({
    super.key,
    required this.title,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<PinInputPage> createState() => _PinInputPageState();
}

class _PinInputPageState extends State<PinInputPage> {
  String? _error;

  void _handleSubmit(String pin) {
    widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.hint),
            const SizedBox(height: 4),
            if (_error != null)
              Column(
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                ],
              ),
            PinInputWidget(
              pinLength: 6,
              onSubmit: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}