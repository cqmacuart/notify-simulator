import 'dart:convert';

/// Represents a notification that has been scheduled (or fired immediately).
class ScheduledNotification {
  final int notifId;       // flutter_local_notifications id
  final String templateId;
  final String templateName;
  final String resolvedTitle;   // placeholders already replaced
  final String resolvedBody;
  final DateTime scheduledAt;   // moment when the alarm will fire
  final bool cancelled;

  const ScheduledNotification({
    required this.notifId,
    required this.templateId,
    required this.templateName,
    required this.resolvedTitle,
    required this.resolvedBody,
    required this.scheduledAt,
    this.cancelled = false,
  });

  ScheduledNotification copyWith({bool? cancelled}) => ScheduledNotification(
    notifId: notifId,
    templateId: templateId,
    templateName: templateName,
    resolvedTitle: resolvedTitle,
    resolvedBody: resolvedBody,
    scheduledAt: scheduledAt,
    cancelled: cancelled ?? this.cancelled,
  );

  Map<String, dynamic> toJson() => {
    'notifId': notifId,
    'templateId': templateId,
    'templateName': templateName,
    'resolvedTitle': resolvedTitle,
    'resolvedBody': resolvedBody,
    'scheduledAt': scheduledAt.toIso8601String(),
    'cancelled': cancelled,
  };

  factory ScheduledNotification.fromJson(Map<String, dynamic> j) =>
      ScheduledNotification(
        notifId: j['notifId'],
        templateId: j['templateId'],
        templateName: j['templateName'],
        resolvedTitle: j['resolvedTitle'],
        resolvedBody: j['resolvedBody'],
        scheduledAt: DateTime.parse(j['scheduledAt']),
        cancelled: j['cancelled'] ?? false,
      );

  static List<ScheduledNotification> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => ScheduledNotification.fromJson(e)).toList();
  }

  static String listToJson(List<ScheduledNotification> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());
}
