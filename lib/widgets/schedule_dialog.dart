import 'package:flutter/material.dart';

import '../models/template_model.dart';
import '../models/variable_model.dart';
import '../models/schedule_result.dart';

/// Dialog that lets the user choose when to fire a notification:
/// immediately, at a specific time, or randomly within a window.
class ScheduleDialog extends StatefulWidget {
  final TemplateModel template;
  final List<VariableModel> variables;

  const ScheduleDialog({
    super.key,
    required this.template,
    required this.variables,
  });

  @override
  State<ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  ScheduleMode _mode = ScheduleMode.immediate;

  // Scheduled mode
  TimeOfDay _scheduledTime = TimeOfDay.now();
  DateTime _scheduledDate = DateTime.now();

  // Random mode
  TimeOfDay _windowStartTime = TimeOfDay.now();
  DateTime _windowStartDate = DateTime.now();
  int _windowMinutes = 60;
  int _randomCount = 3;

  Future<void> _pickDate(
    DateTime current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickTime(
    TimeOfDay current,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) onPicked(picked);
  }

  DateTime _combine(DateTime date, TimeOfDay time) => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

  void _confirm() {
    ScheduleResult result;

    switch (_mode) {
      case ScheduleMode.immediate:
        result = const ScheduleResult.immediate();
      case ScheduleMode.scheduled:
        final dt = _combine(_scheduledDate, _scheduledTime);
        if (dt.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La hora debe ser en el futuro')),
          );
          return;
        }
        result = ScheduleResult.scheduled(dt);
      case ScheduleMode.random:
        final start = _combine(_windowStartDate, _windowStartTime);
        if (start.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El inicio de la ventana debe ser en el futuro'),
            ),
          );
          return;
        }
        final end = start.add(Duration(minutes: _windowMinutes));
        result = ScheduleResult.random(start: start, end: end, n: _randomCount);
    }

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Generar: ${widget.template.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<ScheduleMode>(
              segments: const [
                ButtonSegment(
                  value: ScheduleMode.immediate,
                  label: Text('Ahora'),
                  icon: Icon(Icons.flash_on, size: 16),
                ),
                ButtonSegment(
                  value: ScheduleMode.scheduled,
                  label: Text('Hora fija'),
                  icon: Icon(Icons.alarm, size: 16),
                ),
                ButtonSegment(
                  value: ScheduleMode.random,
                  label: Text('Aleatorias'),
                  icon: Icon(Icons.shuffle, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 16),

            if (_mode == ScheduleMode.immediate)
              const Text(
                'Se enviará inmediatamente (con la app abierta).',
                style: TextStyle(color: Colors.grey),
              ),

            if (_mode == ScheduleMode.scheduled) ...[
              const Text('Fecha y hora de disparo:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                      ),
                      onPressed: () => _pickDate(
                        _scheduledDate,
                        (d) => setState(() => _scheduledDate = d),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_scheduledTime.format(context)),
                      onPressed: () => _pickTime(
                        _scheduledTime,
                        (t) => setState(() => _scheduledTime = t),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'La notificación llegará a esa hora aunque la app esté cerrada '
                '(requiere Autostart activo en MIUI).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],

            if (_mode == ScheduleMode.random) ...[
              const Text('Inicio de la ventana:'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        '${_windowStartDate.day}/${_windowStartDate.month}/${_windowStartDate.year}',
                      ),
                      onPressed: () => _pickDate(
                        _windowStartDate,
                        (d) => setState(() => _windowStartDate = d),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_windowStartTime.format(context)),
                      onPressed: () => _pickTime(
                        _windowStartTime,
                        (t) => setState(() => _windowStartTime = t),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Duración (min): '),
                  Expanded(
                    child: Slider(
                      value: _windowMinutes.toDouble(),
                      min: 10,
                      max: 480,
                      divisions: 47,
                      label: '$_windowMinutes min',
                      onChanged: (v) =>
                          setState(() => _windowMinutes = v.round()),
                    ),
                  ),
                  Text('$_windowMinutes'),
                ],
              ),
              Row(
                children: [
                  const Text('Cantidad: '),
                  Expanded(
                    child: Slider(
                      value: _randomCount.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: '$_randomCount',
                      onChanged: (v) =>
                          setState(() => _randomCount = v.round()),
                    ),
                  ),
                  Text('$_randomCount'),
                ],
              ),
              Text(
                'Se pre-calcularán $_randomCount instantes aleatorios dentro '
                'de una ventana de $_windowMinutes min y se registrarán como '
                'alarmas exactas individuales. La app puede cerrarse '
                'inmediatamente después.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(
            _mode == ScheduleMode.immediate
                ? 'Enviar ahora'
                : _mode == ScheduleMode.scheduled
                    ? 'Programar'
                    : 'Programar $_randomCount aleatorias',
          ),
        ),
      ],
    );
  }
}
