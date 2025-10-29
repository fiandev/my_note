import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// Assuming MainScreen is in pages/main_screen.dart

class SplashPage extends StatefulWidget {
  final bool initialized;
  final VoidCallback onFinishInitialization;
  final Widget Function() mainScreenBuilder;

  const SplashPage({
    super.key,
    required this.initialized,
    required this.onFinishInitialization,
    required this.mainScreenBuilder,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacityAnim;

  // Minimal splash duration agar tidak langsung lompat
  final Duration _minSplashDuration = const Duration(milliseconds: 1000);
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _animController.forward();

    // Periksa periodik apakah inisialisasi sudah selesai dan minimal duration terpenuhi
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final elapsed = DateTime.now().difference(_startTime);
      if (widget.initialized && elapsed >= _minSplashDuration) {
        timer.cancel();
        _goToMain();
      }
    });
  }

  void _goToMain() {
    // lakukan transisi pushReplacement ke MainScreen (dengan fade)
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => widget.mainScreenBuilder(),
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  @override
  void didUpdateWidget(covariant SplashPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // jika sebelumnya belum inisialisasi dan sekarang sudah, cek langsung
    if (!oldWidget.initialized && widget.initialized) {
      final elapsed = DateTime.now().difference(_startTime);
      if (elapsed >= _minSplashDuration) {
        _goToMain();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan logo (pakai Image.asset atau FlutterLogo jika asset bermasalah)
    Widget logo;
    try {
      logo = Image.asset(
        'assets/logo-splash.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const FlutterLogo(size: 120),
      );
    } catch (_) {
      logo = const FlutterLogo(size: 120);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              logo,
              const SizedBox(height: 12),
              Text(
                'app_name'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
