import 'package:flutter/material.dart';

import '../services/miui_service.dart';

/// Critical onboarding banner shown on Xiaomi/MIUI devices.
/// Without these manual steps the app's alarms WILL NOT fire with app closed.
class MiuiBanner extends StatelessWidget {
  const MiuiBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFF6F00),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Configuración requerida en MIUI / HyperOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'MIUI agresivamente mata procesos en segundo plano. '
              'Sin estos tres pasos, las notificaciones programadas NO '
              'llegarán cuando la app esté cerrada. Esto es una limitación '
              'del sistema operativo, no un bug de la app.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const _Step(
              number: '1',
              title: 'Inicio automático (Autostart)',
              description:
                  'Seguridad → Permisos → Inicio automático → activa esta app.',
            ),
            const _Step(
              number: '2',
              title: 'Batería sin restricciones',
              description:
                  'Ajustes → Batería → (esta app) → Sin restricciones.',
            ),
            const _Step(
              number: '3',
              title: 'Bloquear en Recientes',
              description:
                  'Abre Recientes (cuadrado), mantén pulsado la tarjeta de la app → Bloquear (candado).',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () async {
                      final ok = await MiuiService.openAutostart();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudo abrir automáticamente. '
                              'Ve a Seguridad → Permisos → Inicio automático.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Abrir Autostart'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () async {
                      final ok = await MiuiService.openBatteryOptimization();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudo abrir automáticamente. '
                              'Ve a Ajustes → Batería y busca esta app.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Abrir Batería'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _Step({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFFFF6F00),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
