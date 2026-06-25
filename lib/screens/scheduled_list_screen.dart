import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scheduled_notification.dart';

class ScheduledListScreen extends StatefulWidget {
  final List<ScheduledNotification> scheduled;
  final Future<void> Function(int id) onCancel;
  final Future<void> Function() onCancelAll;

  const ScheduledListScreen({
    super.key,
    required this.scheduled,
    required this.onCancel,
    required this.onCancelAll,
  });

  @override
  State<ScheduledListScreen> createState() => _ScheduledListScreenState();
}

class _ScheduledListScreenState extends State<ScheduledListScreen> {
  late List<ScheduledNotification> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.scheduled)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<ScheduledNotification> get _pending => _items
      .where((s) => !s.cancelled && s.scheduledAt.isAfter(DateTime.now()))
      .toList();

  List<ScheduledNotification> get _past => _items
      .where((s) => s.cancelled || !s.scheduledAt.isAfter(DateTime.now()))
      .toList();

  String _fmt(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm').format(dt);

  Future<void> _cancel(ScheduledNotification sn) async {
    await widget.onCancel(sn.notifId);
    setState(() {
      final idx = _items.indexWhere((x) => x.notifId == sn.notifId);
      if (idx >= 0) _items[idx] = sn.copyWith(cancelled: true);
    });
  }

  Future<void> _cancelAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar todas'),
        content: const Text(
          '¿Cancelar todas las notificaciones pendientes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.onCancelAll();
    setState(() {
      _items = _items.map((s) {
        if (!s.cancelled && s.scheduledAt.isAfter(DateTime.now())) {
          return s.copyWith(cancelled: true);
        }
        return s;
      }).toList();
    });
  }

  Widget _tile(ScheduledNotification sn, {bool canCancel = false}) {
    final isPast = sn.scheduledAt.isBefore(DateTime.now());
    return ListTile(
      leading: Icon(
        sn.cancelled
            ? Icons.cancel_outlined
            : isPast
                ? Icons.check_circle_outline
                : Icons.alarm,
        color: sn.cancelled
            ? Colors.red
            : isPast
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
      ),
      title: Text(sn.resolvedTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${sn.templateName} · ${_fmt(sn.scheduledAt)}\n${sn.resolvedBody}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: canCancel
          ? IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancelar esta',
              onPressed: () => _cancel(sn),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final past = _past;

    return Scaffold(
      appBar: AppBar(
        title: Text('Programadas (${pending.length} pendientes)'),
        actions: [
          if (pending.isNotEmpty)
            TextButton(
              onPressed: _cancelAll,
              child: const Text(
                'Cancelar todas',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No hay notificaciones programadas'))
          : ListView(
              children: [
                if (pending.isNotEmpty) ...[
                  const _SectionHeader('Pendientes'),
                  ...pending.map((sn) => _tile(sn, canCancel: true)),
                ],
                if (past.isNotEmpty) ...[
                  const _SectionHeader('Pasadas / Canceladas'),
                  ...past.map((sn) => _tile(sn)),
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    ),
  );
}
