import 'package:flutter/material.dart';

import '../models/template_model.dart';
import '../models/variable_model.dart';
import '../models/scheduled_notification.dart';
import '../models/schedule_result.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/miui_service.dart';
import '../widgets/miui_banner.dart';
import '../widgets/permission_card.dart';
import '../widgets/template_card.dart';
import '../widgets/variable_chip.dart';
import '../widgets/schedule_dialog.dart';
import 'template_editor_screen.dart';
import 'variable_editor_screen.dart';
import 'scheduled_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TemplateModel> _templates = [];
  List<VariableModel> _variables = [];
  List<ScheduledNotification> _scheduled = [];

  bool _notifEnabled = false;
  bool _exactAlarmEnabled = false;
  bool _batteryUnrestricted = false;
  bool _isMiui = false;

  late final _LifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _load();
    _checkPermissions();
    MiuiService.isMiui().then((v) {
      if (mounted) setState(() => _isMiui = v);
    });
    // Re-check permissions whenever the app returns to foreground (e.g. after
    // the user toggled a setting in the system Settings app).
    _lifecycleObserver = _LifecycleObserver(_checkPermissions);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  void _load() {
    setState(() {
      _templates = StorageService.loadTemplates();
      _variables = StorageService.loadVariables();
      _scheduled = StorageService.loadScheduled();
    });
  }

  Future<void> _checkPermissions() async {
    final n = await NotificationService.areNotificationsEnabled();
    final e = await NotificationService.canScheduleExactAlarms();
    final b = await NotificationService.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _notifEnabled = n;
      _exactAlarmEnabled = e;
      _batteryUnrestricted = b;
    });
  }

  // ── Cold-delivery self-test ───────────────────────────────────────────────

  Future<void> _runColdTest() async {
    if (!_notifEnabled) {
      _snack('Activa los permisos de notificación primero');
      return;
    }
    if (!_exactAlarmEnabled) {
      _snack('Activa la alarma exacta primero — es la causa del problema');
      return;
    }
    final fireAt = await NotificationService.scheduleColdTest(seconds: 60);
    _load();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🧪 Prueba en frío programada'),
        content: Text(
          'Una notificación de prueba disparará a las ${_fmt(fireAt)} '
          '(en ~1 minuto).\n\n'
          'AHORA, para comprobar la entrega en frío de verdad:\n\n'
          '1. Cierra esta app por completo (deslízala fuera de Recientes).\n'
          '2. Bloquea la pantalla y espera ~1 minuto.\n'
          '3. La notificación "✅ Prueba en frío" debe aparecer SIN abrir la app.\n\n'
          'Si aparece → la entrega en frío funciona en tu teléfono.\n'
          'Si NO aparece → revisa alarma exacta, batería y (en Xiaomi) Autostart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ── Template actions ──────────────────────────────────────────────────────

  Future<void> _openTemplateEditor([TemplateModel? tpl]) async {
    final result = await Navigator.push<TemplateModel>(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(
          initial: tpl,
          variables: _variables,
        ),
      ),
    );
    if (result == null) return;
    final idx = _templates.indexWhere((t) => t.id == result.id);
    if (idx >= 0) {
      _templates[idx] = result;
    } else {
      _templates.add(result);
    }
    await StorageService.saveTemplates(_templates);
    _load();
  }

  Future<void> _deleteTemplate(TemplateModel tpl) async {
    final ok = await _confirm('¿Eliminar plantilla "${tpl.name}"?');
    if (!ok) return;
    _templates.removeWhere((t) => t.id == tpl.id);
    await StorageService.saveTemplates(_templates);
    _load();
  }

  Future<void> _testNotification(TemplateModel tpl) async {
    if (!_notifEnabled) {
      _snack('Activa los permisos de notificación primero');
      return;
    }
    await NotificationService.showImmediate(tpl, _variables);
    _snack('Notificación de prueba enviada');
    _load();
  }

  Future<void> _generateNotification(TemplateModel tpl) async {
    if (!_notifEnabled) {
      _snack('Activa los permisos de notificación primero');
      return;
    }
    final result = await showDialog<ScheduleResult>(
      context: context,
      builder: (_) => ScheduleDialog(template: tpl, variables: _variables),
    );
    if (result == null || !mounted) return;

    switch (result.mode) {
      case ScheduleMode.immediate:
        await NotificationService.showImmediate(tpl, _variables);
        _snack('Notificación generada ahora');
      case ScheduleMode.scheduled:
        // No early-return: if exact alarm is off (typical on Samsung), confirm
        // with the user instead of failing silently.
        if (!_exactAlarmEnabled && !await _confirmInexactSchedule()) return;
        await NotificationService.scheduleAt(tpl, _variables, result.time!);
        _snack(_exactAlarmEnabled
            ? 'Programada (exacta) para ${_fmt(result.time!)}'
            : 'Programada (inexacta, puede retrasarse) para ${_fmt(result.time!)}');
      case ScheduleMode.random:
        if (!_exactAlarmEnabled && !await _confirmInexactSchedule()) return;
        final list = await NotificationService.scheduleRandom(
          tpl: tpl,
          variables: _variables,
          windowStart: result.windowStart!,
          windowEnd: result.windowEnd!,
          count: result.count!,
        );
        _snack('${list.length} notificaciones programadas'
            '${_exactAlarmEnabled ? '' : ' (inexactas, pueden retrasarse)'}');
    }
    _load();
  }

  /// Shown when scheduling without the exact-alarm permission (common on Samsung
  /// One UI, where "Alarmas y recordatorios" is a separate special access).
  /// Offers to open the settings screen or proceed with inexact scheduling.
  Future<bool> _confirmInexactSchedule() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Falta permiso de alarma exacta'),
        content: const Text(
          'El permiso "Alarmas y recordatorios" está desactivado. En Samsung es '
          'un permiso SEPARADO de notificaciones y batería, fácil de pasar por '
          'alto.\n\n'
          'Sin él, Android sólo permite alarmas INEXACTAS: la notificación '
          'llegará, pero puede retrasarse varios minutos.\n\n'
          '¿Qué quieres hacer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'settings'),
            child: const Text('Abrir ajustes'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'inexact'),
            child: const Text('Programar igual'),
          ),
        ],
      ),
    );
    if (choice == 'settings') {
      await NotificationService.requestExactAlarmPermission();
      await _checkPermissions();
      // Don't schedule now; let the user retry after granting.
      return false;
    }
    return choice == 'inexact';
  }

  // ── Variable actions ──────────────────────────────────────────────────────

  Future<void> _openVariableEditor([VariableModel? v]) async {
    final result = await Navigator.push<VariableModel>(
      context,
      MaterialPageRoute(builder: (_) => VariableEditorScreen(initial: v)),
    );
    if (result == null) return;
    final idx = _variables.indexWhere((x) => x.id == result.id);
    if (idx >= 0) {
      _variables[idx] = result;
    } else {
      _variables.add(result);
    }
    await StorageService.saveVariables(_variables);
    _load();
  }

  Future<void> _deleteVariable(VariableModel v) async {
    final ok = await _confirm('¿Eliminar variable "${v.name}"?');
    if (!ok) return;
    _variables.removeWhere((x) => x.id == v.id);
    await StorageService.saveVariables(_variables);
    _load();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  int get _pendingCount => _scheduled
      .where((s) => !s.cancelled && s.scheduledAt.isAfter(DateTime.now()))
      .length;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NotiSim'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.schedule),
                tooltip: 'Notificaciones programadas',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduledListScreen(
                        scheduled: _scheduled,
                        onCancel: (id) async {
                          await NotificationService.cancel(id);
                          _load();
                        },
                        onCancelAll: () async {
                          await NotificationService.cancelAll();
                          _load();
                        },
                      ),
                    ),
                  );
                  _load();
                },
              ),
              if (_pendingCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_pendingCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _load();
          await _checkPermissions();
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ── MIUI banner ──────────────────────────────────────────────
            if (_isMiui) ...[
              const MiuiBanner(),
              const SizedBox(height: 12),
            ],

            // ── Permissions ──────────────────────────────────────────────
            PermissionCard(
              notifEnabled: _notifEnabled,
              exactAlarmEnabled: _exactAlarmEnabled,
              batteryUnrestricted: _batteryUnrestricted,
              onRequestNotif: () async {
                await NotificationService.requestNotificationPermission();
                await _checkPermissions();
              },
              onRequestExact: () async {
                await NotificationService.requestExactAlarmPermission();
                await _checkPermissions();
              },
              onRequestBattery: () async {
                await NotificationService.requestIgnoreBatteryOptimizations();
                await _checkPermissions();
              },
            ),
            const SizedBox(height: 8),

            // ── Cold-delivery self-test ──────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.science_outlined),
              label: const Text('Probar entrega en frío (cierra la app)'),
              onPressed: _runColdTest,
            ),
            const SizedBox(height: 16),

            // ── Variables section ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Variables (${_variables.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Nueva variable',
                  onPressed: () => _openVariableEditor(),
                ),
              ],
            ),
            if (_variables.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Sin variables. Añade una con el botón +.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _variables
                    .map(
                      (v) => VariableChip(
                        variable: v,
                        onEdit: () => _openVariableEditor(v),
                        onDelete: () => _deleteVariable(v),
                      ),
                    )
                    .toList(),
              ),
            const Divider(height: 24),

            // ── Templates section ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plantillas (${_templates.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva notificación'),
                  onPressed: () => _openTemplateEditor(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_templates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Sin plantillas.\nPulsa "Nueva notificación" para crear una.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_templates.map(
                (tpl) => TemplateCard(
                  template: tpl,
                  onTest: () => _testNotification(tpl),
                  onGenerate: () => _generateNotification(tpl),
                  onEdit: () => _openTemplateEditor(tpl),
                  onDelete: () => _deleteTemplate(tpl),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

/// Calls [onResume] each time the app returns to the foreground, so permission
/// state reflects changes the user made in the system Settings app.
class _LifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function() onResume;
  _LifecycleObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
