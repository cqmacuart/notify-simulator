import 'package:flutter/material.dart';

import '../models/variable_model.dart';

class VariableChip extends StatelessWidget {
  final VariableModel variable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VariableChip({
    super.key,
    required this.variable,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = variable.type == VariableType.money
        ? Icons.attach_money
        : Icons.tag;

    return InputChip(
      avatar: Icon(icon, size: 16),
      label: Text('{${variable.name}}'),
      onPressed: onEdit,
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.close, size: 16),
      tooltip: variable.type == VariableType.money ? 'Variable dinero' : 'Variable serial',
    );
  }
}
