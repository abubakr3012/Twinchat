import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/call.dart';
import '../../../domain/repositories/calls_repository.dart';

/// CallScreen — экран активного звонка.
/// Создаёт звонок через API, тикает таймер, позволяет завершить.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.chatId, this.callType = CallType.voice});

  final int chatId;
  final CallType callType;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _timer;
  int _seconds = 0;
  Call? _call;
  String? _error;
  bool _loading = true;
  bool _muted = false;
  bool _video = false;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      final call = await GetIt.I<CallsRepository>().create(
        chatId: widget.chatId,
        type: widget.callType,
      );
      if (!mounted) return;
      setState(() {
        _call = call;
        _loading = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  Future<void> _end() async {
    _timer?.cancel();
    final id = _call?.id;
    if (id != null) {
      try {
        await GetIt.I<CallsRepository>().end(id);
      } catch (_) {}
    }
    if (mounted) context.go('/chats');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            CircleAvatar(
              radius: 64,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '#${widget.chatId}',
                style: const TextStyle(color: Colors.white, fontSize: 32),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Звонок',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _loading
                  ? 'Подключение…'
                  : (_error ?? _format(_seconds)),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleButton(
                  icon: _muted ? Icons.mic_off : Icons.mic,
                  onTap: () => setState(() => _muted = !_muted),
                ),
                _CircleButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onTap: _end,
                ),
                _CircleButton(
                  icon: _video ? Icons.videocam : Icons.videocam_off,
                  onTap: () => setState(() => _video = !_video),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
          ),
          child: Icon(icon, color: Colors.black87, size: 32),
        ),
      ),
    );
  }
}