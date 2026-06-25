/// Holds the user's selection from ScheduleDialog.
enum ScheduleMode { immediate, scheduled, random }

class ScheduleResult {
  final ScheduleMode mode;
  final DateTime? time;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final int? count;

  const ScheduleResult.immediate()
      : mode = ScheduleMode.immediate,
        time = null,
        windowStart = null,
        windowEnd = null,
        count = null;

  const ScheduleResult.scheduled(DateTime t)
      : mode = ScheduleMode.scheduled,
        time = t,
        windowStart = null,
        windowEnd = null,
        count = null;

  const ScheduleResult.random({
    required DateTime start,
    required DateTime end,
    required int n,
  })  : mode = ScheduleMode.random,
        time = null,
        windowStart = start,
        windowEnd = end,
        count = n;
}
