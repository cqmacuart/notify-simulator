import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/template_model.dart';
import '../models/variable_model.dart';

class TemplateEditorScreen extends StatefulWidget {
  final TemplateModel? initial;
  final List<VariableModel> variables;

  const TemplateEditorScreen({
    super.key,
    this.initial,
    required this.variables,
  });

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _appLabelCtrl;
  String? _largeIconPath;
  String? _bigPicturePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _bodyCtrl = TextEditingController(text: t?.body ?? '');
    _appLabelCtrl = TextEditingController(text: t?.appNameLabel ?? '');
    _largeIconPath = t?.largeIconPath;
    _bigPicturePath = t?.bigPicturePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _appLabelCtrl.dispose();
    super.dispose();
  }

  Future<String?> _pickImage(String slotName) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return null;

    // Copy to app storage so the path survives gallery moves.
    final appDir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${appDir.path}/noti_images');
    await destDir.create(recursive: true);
    final dest = '${destDir.path}/${slotName}_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(xFile.path).copy(dest);
    return dest;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final result = TemplateModel(
        id: widget.initial?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        largeIconPath: _largeIconPath,
        bigPicturePath: _bigPicturePath,
        appNameLabel: _appLabelCtrl.text.trim().isEmpty
            ? null
            : _appLabelCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, result);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _imageTile({
    required String label,
    required String? path,
    required VoidCallback onPick,
    required VoidCallback onClear,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(hint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        if (path != null && File(path).existsSync())
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClear,
              ),
            ],
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.image),
            label: Text('Elegir $label'),
            onPressed: onPick,
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _variableChip(String name) {
    return ActionChip(
      label: Text('{$name}'),
      onPressed: () {
        // Inserts the placeholder at the cursor position in the focused field.
        final controllers = [_titleCtrl, _bodyCtrl];
        for (final c in controllers) {
          final sel = c.selection;
          if (sel.isValid) {
            final text = c.text;
            final insert = '{$name}';
            c.value = TextEditingValue(
              text: text.replaceRange(sel.start, sel.end, insert),
              selection: TextSelection.collapsed(
                offset: sel.start + insert.length,
              ),
            );
            return;
          }
        }
        // Fallback: append to body
        _bodyCtrl.text += '{$name}';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar plantilla' : 'Nueva plantilla'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Variables quick-insert
            if (widget.variables.isNotEmpty) ...[
              Text(
                'Insertar variable (toca para añadir al texto)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Wrap(
                spacing: 6,
                children: widget.variables
                    .map((v) => _variableChip(v.name))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la plantilla *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título de la notificación *',
                hintText: 'Ej: Tienes un nuevo ingreso',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Cuerpo del mensaje *',
                hintText: 'Ej: Your earnings: {valorMonetario} - {miSerial}',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _appLabelCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de app (subText / summaryText)',
                hintText: 'Ej: PayPal',
                border: OutlineInputBorder(),
                helperText: 'Aparece bajo el título de la notificación',
              ),
            ),
            const SizedBox(height: 16),

            _imageTile(
              label: 'Ícono grande (largeIcon)',
              path: _largeIconPath,
              hint: 'Ícono a COLOR visible a la derecha de la notificación.',
              onPick: () async {
                final p = await _pickImage('large_icon');
                if (p != null) setState(() => _largeIconPath = p);
              },
              onClear: () => setState(() => _largeIconPath = null),
            ),

            _imageTile(
              label: 'Imagen expandida (bigPicture)',
              path: _bigPicturePath,
              hint: 'Imagen grande visible al expandir la notificación (BigPictureStyle).',
              onPick: () async {
                final p = await _pickImage('big_picture');
                if (p != null) setState(() => _bigPicturePath = p);
              },
              onClear: () => setState(() => _bigPicturePath = null),
            ),

            const SizedBox(height: 16),
            const Card(
              color: Color(0xFFFFF9C4),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota sobre íconos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'El ícono pequeño de la barra de estado es monocromático y '
                      'está compilado en el APK; no se puede cambiar a color ni '
                      'suplantar en runtime. El ícono grande (derecha) y la imagen '
                      'expandida sí son a color y personalizables.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
