import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CountDownTimer extends StatefulWidget {
  final bool startTimer;

  const CountDownTimer({super.key, required this.startTimer});

  @override
  State<CountDownTimer> createState() => _CountDownTimerState();
}

class _CountDownTimerState extends State<CountDownTimer> {
  Duration _duration = const Duration();
  Timer? _timer;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _duration = Duration(seconds: _duration.inSeconds + 1);
      });
    });
  }

  void _stopTimer() {
    if (!mounted) return;
    setState(() {
      _timer?.cancel();
      _timer = null;
      _duration = const Duration();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timer == null || !widget.startTimer) {
      widget.startTimer ? _startTimer() : _stopTimer();
    }

    String twoDigit(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigit(_duration.inHours.remainder(60));
    final minutes = twoDigit(_duration.inMinutes.remainder(60));
    final seconds = twoDigit(_duration.inSeconds.remainder(60));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      '$hours:$minutes:$seconds',
      style: HpTextStyles.displayTimer.copyWith(
        fontSize: 26,
        color: widget.startTimer
            ? HpColors.accentEmerald
            : (isDark ? HpColors.textSecondary : HpColors.lightTextSecondary),
      ),
    );
  }
}
