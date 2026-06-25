import 'package:shared_preferences/shared_preferences.dart';
import '../models/variable_model.dart';
import '../models/template_model.dart';
import '../models/scheduled_notification.dart';

const _kVariables = 'variables_v1';
const _kTemplates = 'templates_v1';
const _kScheduled = 'scheduled_v1';
const _kNextId = 'next_notif_id';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Variables ──────────────────────────────────────────────────────────────

  static List<VariableModel> loadVariables() {
    final raw = _prefs!.getString(_kVariables);
    if (raw == null || raw.isEmpty) return [];
    return VariableModel.listFromJson(raw);
  }

  static Future<void> saveVariables(List<VariableModel> items) =>
      _prefs!.setString(_kVariables, VariableModel.listToJson(items));

  // ── Templates ─────────────────────────────────────────────────────────────

  static List<TemplateModel> loadTemplates() {
    final raw = _prefs!.getString(_kTemplates);
    if (raw == null || raw.isEmpty) return [];
    return TemplateModel.listFromJson(raw);
  }

  static Future<void> saveTemplates(List<TemplateModel> items) =>
      _prefs!.setString(_kTemplates, TemplateModel.listToJson(items));

  // ── Scheduled notifications ───────────────────────────────────────────────

  static List<ScheduledNotification> loadScheduled() {
    final raw = _prefs!.getString(_kScheduled);
    if (raw == null || raw.isEmpty) return [];
    return ScheduledNotification.listFromJson(raw);
  }

  static Future<void> saveScheduled(List<ScheduledNotification> items) =>
      _prefs!.setString(_kScheduled, ScheduledNotification.listToJson(items));

  // ── Notification ID counter ───────────────────────────────────────────────

  static int nextNotifId() {
    final id = _prefs!.getInt(_kNextId) ?? 1;
    _prefs!.setInt(_kNextId, id + 1);
    return id;
  }
}
