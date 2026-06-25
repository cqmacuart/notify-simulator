import 'package:flutter/material.dart';

class PermissionCard extends StatelessWidget {
  final bool notifEnabled;
  final bool exactAlarmEnabled;
  final bool batteryUnrestricted;
  final VoidCallback onRequestNotif;
  final VoidCallback onRequestExact;
  final VoidCallback onRequestBattery;

  const PermissionCard({
    super.key,
    required this.notifEnabled,
    required this.exactAlarmEnabled,
    required this.batteryUnrestricted,
    required this.onRequestNotif,
    required this.onRequestExact,
    required this.onRequestBattery,
  });

  @override
  Widget build(BuildContext context) {
    // Battery whitelist is strongly recommended but not strictly blocking.
    final criticalOk = notifEnabled && exactAlarmEnabled;
    final allOk = criticalOk && batteryUnrestricted;

    return Card(
      color: allOk ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allOk ? Icons.check_circle : Icons.info_outline,
                  color: allOk ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Permisos para entrega en frío',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row(
              context,
              label: 'Notificaciones',
              granted: notifEnabled,
              onRequest: onRequestNotif,
            ),
            _row(
              context,
              label: 'Alarma exacta (Alarmas y recordatorios)',
              granted: exactAlarmEnabled,
              onRequest: onRequestExact,
            ),
            _row(
              context,
              label: 'Batería sin restricciones',
              granted: batteryUnrestricted,
              onRequest: onRequestBattery,
            ),
            if (!exactAlarmEnabled)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '⚠ CRÍTICO: sin alarma exacta, Android degrada las '
                  'notificaciones programadas a "inexactas" y las difiere hasta '
                  'que despiertas el teléfono (típicamente al abrir una app). '
                  'Por eso parecía que solo llegaban al abrir la app.',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              )
            else if (!batteryUnrestricted)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Recomendado: sin esto, el SO puede forzar la detención de la '
                  'app y cancelar sus alarmas pendientes.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required bool granted,
    required VoidCallback onRequest,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check : Icons.close,
            size: 16,
            color: granted ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          if (!granted)
            TextButton(
              onPressed: onRequest,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Activar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
