import 'dart:io';

import 'package:flutter/material.dart';

import '../models/template_model.dart';

class TemplateCard extends StatelessWidget {
  final TemplateModel template;
  final VoidCallback onTest;
  final VoidCallback onGenerate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTest,
    required this.onGenerate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = template.largeIconPath != null &&
        File(template.largeIconPath!).existsSync();
    final hasPic = template.bigPicturePath != null &&
        File(template.bigPicturePath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPic)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.file(
                File(template.bigPicturePath!),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ListTile(
            leading: hasIcon
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(template.largeIconPath!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : const CircleAvatar(child: Icon(Icons.notifications)),
            title: Text(
              template.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  template.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (template.appNameLabel != null)
                  Text(
                    'App: ${template.appNameLabel}',
                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Probar'),
                  onPressed: onTest,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Generar'),
                  onPressed: onGenerate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
