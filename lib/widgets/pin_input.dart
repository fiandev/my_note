import 'package:flutter/material.dart';

class PinInputWidget extends StatefulWidget {
  final int pinLength;
  final void Function(String) onSubmit;

  const PinInputWidget({
    super.key,
    this.pinLength = 6,
    required this.onSubmit,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  List<String> enteredPin = [];
  bool _isLocked = false; // mencegah input saat submit

  void _addDigit(String digit) {
    if (_isLocked) return;
    if (enteredPin.length < widget.pinLength) {
      setState(() => enteredPin.add(digit));
      if (enteredPin.length == widget.pinLength) {
        _isLocked = true;
        final pin = enteredPin.join();

        // Panggil callback, lalu reset otomatis
        Future.delayed(const Duration(milliseconds: 150), () {
          widget.onSubmit(pin);
          if (mounted) {
            setState(() {
              enteredPin.clear();
              _isLocked = false;
            });
          }
        });
      }
    }
  }

  void _removeDigit() {
    if (_isLocked) return;
    if (enteredPin.isNotEmpty) {
      setState(() => enteredPin.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = 70.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pinLength, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < enteredPin.length
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 3 * size + 40,
          child: Column(
            children: [
              for (var row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['', '0', '<']
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: row.map((key) {
                      if (key.isEmpty) {
                        return SizedBox(width: size);
                      } else if (key == '<') {
                        return _buildButton(
                          icon: Icons.backspace,
                          onPressed: _removeDigit,
                          color: Colors.red,
                          size: size,
                        );
                      } else {
                        return _buildButton(
                          label: key,
                          onPressed: () => _addDigit(key),
                          size: size,
                        );
                      }
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    String? label,
    IconData? icon,
    required VoidCallback onPressed,
    Color? color,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const CircleBorder(),
        ),
        onPressed: _isLocked ? null : onPressed,
        child: icon != null
            ? Icon(icon)
            : Text(label!, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
