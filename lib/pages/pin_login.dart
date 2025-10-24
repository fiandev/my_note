import 'package:flutter/material.dart';
import 'package:my_note/pages/secret_note_list_page.dart';
import '../services/pin_service.dart';
import '../widgets/pin_input.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  final _pinService = PinService();
  String? _error;

  Future<void> _handleSubmit(String pin) async {
    final ok = await _pinService.verifyPin(pin);

    if (ok) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SecretNoteListPage(
            pin: pin,
          ),
        ),
      );
    } else {
      setState(() => _error = "PIN salah, coba lagi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Masukkan PIN")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Masukkan PIN Anda untuk melanjutkan"),
            const SizedBox(height: 4),
            if (_error != null)
              Column(
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                ],
              ),
            PinInputWidget(onSubmit: _handleSubmit),
          ],
        ),
      ),
    );
  }
}
