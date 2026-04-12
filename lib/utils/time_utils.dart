class TimeUtils {
  static DateTime toLocal(String? iso) {
    if (iso == null || iso.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static String formatClock(String? iso) {
    final dt = toLocal(iso);
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  static String formatDateLabel(String? iso) {
    final dt = toLocal(iso);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return "Today";
    if (d == today.subtract(const Duration(days: 1))) return "Yesterday";
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  static String timeAgo(DateTime? dt) {
    if (dt == null) return "";
    final local = dt.isUtc ? dt.toLocal() : dt;
    final diff = DateTime.now().difference(local);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${(diff.inDays / 7).floor()}w ago";
  }

  static bool isSameDay(String? a, String? b) {
    if (a == null || b == null) return true;
    try {
      final da = DateTime.parse(a).toLocal();
      final db = DateTime.parse(b).toLocal();
      return da.year == db.year && da.month == db.month && da.day == db.day;
    } catch (_) {
      return true;
    }
  }

  static String nowUtc() => DateTime.now().toUtc().toIso8601String();
}