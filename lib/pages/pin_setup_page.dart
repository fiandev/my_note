 import 'package:flutter/material.dart';
 import '../services/pin_service.dart';
 import '../widgets/pin_input.dart';
 import 'package:easy_localization/easy_localization.dart';

class PinSetupPage extends StatefulWidget {
  final bool isForReset;

  const PinSetupPage({super.key, this.isForReset = false});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  final _pinService = PinService();
  String? _firstPin;
  String? _error;
  bool _isConfirming = false;

  void _handleSubmit(String pin) async {
    if (!_isConfirming) {
      setState(() {
        _firstPin = pin;
        _isConfirming = true;
        _error = null;
      });
    } else {
      if (pin == _firstPin) {
        if (widget.isForReset) {
          Navigator.pop(context, pin);
        } else {
          await _pinService.savePin(pin);
          if (mounted) Navigator.pop(context, pin);
        }
      } else {
        setState(() {
           _error = 'pin_mismatch'.tr();
           _firstPin = null;
           _isConfirming = false;
         });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
           title: Text(_isConfirming ? 'confirm_pin'.tr() : 'create_pin'.tr())),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(_isConfirming
                 ? 'reenter_pin'.tr()
                 : 'enter_new_pin'.tr()),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            PinInputWidget(onSubmit: _handleSubmit),
          ],
        ),
      ),
    );
  }
}
