import 'dart:convert';
import 'dart:math';

enum VariableType { money, serial }

class MoneyConfig {
  final String symbol;
  final double min;
  final double max;
  final int decimals;
  final bool useThousandsSeparator;

  const MoneyConfig({
    this.symbol = '\$',
    this.min = 100,
    this.max = 9999,
    this.decimals = 2,
    this.useThousandsSeparator = true,
  });

  MoneyConfig copyWith({
    String? symbol,
    double? min,
    double? max,
    int? decimals,
    bool? useThousandsSeparator,
  }) => MoneyConfig(
    symbol: symbol ?? this.symbol,
    min: min ?? this.min,
    max: max ?? this.max,
    decimals: decimals ?? this.decimals,
    useThousandsSeparator: useThousandsSeparator ?? this.useThousandsSeparator,
  );

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'min': min,
    'max': max,
    'decimals': decimals,
    'useThousandsSeparator': useThousandsSeparator,
  };

  factory MoneyConfig.fromJson(Map<String, dynamic> j) => MoneyConfig(
    symbol: j['symbol'] ?? '\$',
    min: (j['min'] ?? 100).toDouble(),
    max: (j['max'] ?? 9999).toDouble(),
    decimals: j['decimals'] ?? 2,
    useThousandsSeparator: j['useThousandsSeparator'] ?? true,
  );
}

class SerialConfig {
  final String prefix;
  final int length;
  final bool alphanumeric;

  const SerialConfig({
    this.prefix = 'INV-',
    this.length = 6,
    this.alphanumeric = true,
  });

  SerialConfig copyWith({String? prefix, int? length, bool? alphanumeric}) =>
      SerialConfig(
        prefix: prefix ?? this.prefix,
        length: length ?? this.length,
        alphanumeric: alphanumeric ?? this.alphanumeric,
      );

  Map<String, dynamic> toJson() => {
    'prefix': prefix,
    'length': length,
    'alphanumeric': alphanumeric,
  };

  factory SerialConfig.fromJson(Map<String, dynamic> j) => SerialConfig(
    prefix: j['prefix'] ?? 'INV-',
    length: j['length'] ?? 6,
    alphanumeric: j['alphanumeric'] ?? true,
  );
}

class VariableModel {
  final String id;
  final String name;
  final VariableType type;
  final MoneyConfig? moneyConfig;
  final SerialConfig? serialConfig;

  const VariableModel({
    required this.id,
    required this.name,
    required this.type,
    this.moneyConfig,
    this.serialConfig,
  });

  /// Generates a concrete value for this variable (called at schedule time).
  String generate() {
    final rng = Random();
    switch (type) {
      case VariableType.money:
        final cfg = moneyConfig ?? const MoneyConfig();
        final amount = cfg.min + rng.nextDouble() * (cfg.max - cfg.min);
        final formatted = _formatMoney(amount, cfg);
        return '${cfg.symbol}$formatted';
      case VariableType.serial:
        final cfg = serialConfig ?? const SerialConfig();
        final chars = cfg.alphanumeric
            ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
            : '0123456789';
        final part = List.generate(
          cfg.length,
          (_) => chars[rng.nextInt(chars.length)],
        ).join();
        return '${cfg.prefix}$part';
    }
  }

  String _formatMoney(double amount, MoneyConfig cfg) {
    final fixed = amount.toStringAsFixed(cfg.decimals);
    if (!cfg.useThousandsSeparator) return fixed;
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }

  VariableModel copyWith({
    String? name,
    VariableType? type,
    MoneyConfig? moneyConfig,
    SerialConfig? serialConfig,
  }) => VariableModel(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    moneyConfig: moneyConfig ?? this.moneyConfig,
    serialConfig: serialConfig ?? this.serialConfig,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'moneyConfig': moneyConfig?.toJson(),
    'serialConfig': serialConfig?.toJson(),
  };

  factory VariableModel.fromJson(Map<String, dynamic> j) => VariableModel(
    id: j['id'],
    name: j['name'],
    type: VariableType.values.byName(j['type']),
    moneyConfig: j['moneyConfig'] != null
        ? MoneyConfig.fromJson(j['moneyConfig'])
        : null,
    serialConfig: j['serialConfig'] != null
        ? SerialConfig.fromJson(j['serialConfig'])
        : null,
  );

  static List<VariableModel> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => VariableModel.fromJson(e)).toList();
  }

  static String listToJson(List<VariableModel> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());
}
