import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/variable_model.dart';

class VariableEditorScreen extends StatefulWidget {
  final VariableModel? initial;
  const VariableEditorScreen({super.key, this.initial});

  @override
  State<VariableEditorScreen> createState() => _VariableEditorScreenState();
}

class _VariableEditorScreenState extends State<VariableEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late VariableType _type;

  // Money fields
  late final TextEditingController _symbolCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late int _decimals;
  late bool _thousands;

  // Serial fields
  late final TextEditingController _prefixCtrl;
  late final TextEditingController _lengthCtrl;
  late bool _alphanumeric;

  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    _nameCtrl = TextEditingController(text: v?.name ?? '');
    _type = v?.type ?? VariableType.money;

    final m = v?.moneyConfig ?? const MoneyConfig();
    _symbolCtrl = TextEditingController(text: m.symbol);
    _minCtrl = TextEditingController(text: m.min.toString());
    _maxCtrl = TextEditingController(text: m.max.toString());
    _decimals = m.decimals;
    _thousands = m.useThousandsSeparator;

    final s = v?.serialConfig ?? const SerialConfig();
    _prefixCtrl = TextEditingController(text: s.prefix);
    _lengthCtrl = TextEditingController(text: s.length.toString());
    _alphanumeric = s.alphanumeric;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _symbolCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _prefixCtrl.dispose();
    _lengthCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final result = VariableModel(
      id: widget.initial?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      type: _type,
      moneyConfig: _type == VariableType.money
          ? MoneyConfig(
              symbol: _symbolCtrl.text,
              min: double.tryParse(_minCtrl.text) ?? 100,
              max: double.tryParse(_maxCtrl.text) ?? 9999,
              decimals: _decimals,
              useThousandsSeparator: _thousands,
            )
          : null,
      serialConfig: _type == VariableType.serial
          ? SerialConfig(
              prefix: _prefixCtrl.text,
              length: int.tryParse(_lengthCtrl.text) ?? 6,
              alphanumeric: _alphanumeric,
            )
          : null,
    );

    Navigator.pop(context, result);
  }

  Widget _moneyFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _symbolCtrl,
        decoration: const InputDecoration(
          labelText: 'Símbolo / código',
          hintText: r'$  €  USD',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _minCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Mínimo',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Número inválido' : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _maxCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Máximo',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Número inválido' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          const Text('Decimales:'),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _decimals,
            items: [0, 1, 2, 3]
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (v) => setState(() => _decimals = v!),
          ),
          const SizedBox(width: 16),
          const Text('Miles:'),
          Switch(
            value: _thousands,
            onChanged: (v) => setState(() => _thousands = v),
          ),
        ],
      ),
    ],
  );

  Widget _serialFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _prefixCtrl,
        decoration: const InputDecoration(
          labelText: 'Prefijo (puede estar vacío)',
          hintText: 'INV-',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _lengthCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Longitud de la parte aleatoria',
          border: OutlineInputBorder(),
        ),
        validator: (v) =>
            (int.tryParse(v ?? '') ?? 0) < 1 ? 'Mínimo 1' : null,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          const Text('Alfanumérico (A-Z 0-9):'),
          Switch(
            value: _alphanumeric,
            onChanged: (v) => setState(() => _alphanumeric = v),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _alphanumeric ? 'Letras mayúsculas + números' : 'Solo números',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Nueva variable' : 'Editar variable',
        ),
        actions: [
          TextButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la variable *',
                hintText: 'valorMonetario',
                helperText: 'Se usa como {valorMonetario} en las plantillas',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (v.contains(' ')) return 'Sin espacios';
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text('Tipo de variable'),
            const SizedBox(height: 8),
            SegmentedButton<VariableType>(
              segments: const [
                ButtonSegment(
                  value: VariableType.money,
                  label: Text('Dinero'),
                  icon: Icon(Icons.attach_money),
                ),
                ButtonSegment(
                  value: VariableType.serial,
                  label: Text('Serial'),
                  icon: Icon(Icons.tag),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            if (_type == VariableType.money) _moneyFields(),
            if (_type == VariableType.serial) _serialFields(),

            const SizedBox(height: 24),
            const Card(
              color: Color(0xFFE3F2FD),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'El valor se genera en el momento de programar la notificación '
                  '(no al dispararse). Cada notificación que programes recibe su '
                  'propio valor aleatorio único.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
