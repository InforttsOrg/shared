import 'emblem_registry.g.dart';

/// Which seasonal livery is live, and when.
///
/// The calendar itself is data (`brand/occasions.json` → `kEmblemOccasions`);
/// this file only answers "what is today?". The point of the split is that a
/// festival date is a content change, not a code change.
///
/// ```dart
/// final EmblemOccasion? today = EmblemOccasions.forDate(DateTime.now());
/// EmblemRenderer.paint(canvas, centre, radius, spec,
///     livery: today);          // rim + accent follow the season
/// ```
///
/// A season dresses **every** emblem of the app for the same window. Apps that
/// cannot change their launcher icon at runtime (iOS) still use this to theme
/// in-app headers, splash screens and the about page, and to decide which
/// pre-built icon set to activate (Android activity-alias, web manifest).
abstract final class EmblemOccasions {
  /// The occasion whose date matches [day], or `null` on an ordinary day.
  ///
  /// Exact `YYYY-MM-DD` entries win over annual `MM-DD` ones, so a lunar
  /// festival lands on the right Gregorian day.
  static EmblemOccasion? forDate(DateTime day) {
    final String iso = _iso(day);
    final String monthDay = iso.substring(5);
    for (final EmblemOccasion occasion in kEmblemOccasions.values) {
      if (occasion.dates.contains(iso)) return occasion;
    }
    for (final EmblemOccasion occasion in kEmblemOccasions.values) {
      if (occasion.dates.contains(monthDay)) return occasion;
    }
    return null;
  }

  /// Today's occasion, if any.
  static EmblemOccasion? get today => forDate(DateTime.now());

  static EmblemOccasion? byKey(String key) => kEmblemOccasions[key];

  /// Every dated occurrence from [from] to [to] inclusive, soonest first —
  /// what an app needs to pre-render or pre-activate its icon sets.
  static List<({DateTime date, EmblemOccasion occasion})> upcoming({
    DateTime? from,
    DateTime? to,
  }) {
    final DateTime now = DateTime.now();
    final DateTime start = from ?? now;
    final DateTime end = to ?? DateTime(start.year + 1, start.month, start.day);
    final List<({DateTime date, EmblemOccasion occasion})> out =
        <({DateTime date, EmblemOccasion occasion})>[];
    for (final EmblemOccasion occasion in kEmblemOccasions.values) {
      for (final String entry in occasion.dates) {
        for (final DateTime? date in _datesFor(entry, start.year)) {
          if (date == null) continue;
          if (date.isBefore(start) || date.isAfter(end)) continue;
          out.add((date: date, occasion: occasion));
        }
      }
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// A date entry as concrete day(s): annual entries open in the window's year
  /// and the year after, so a window that spans New Year sees both.
  static Iterable<DateTime?> _datesFor(String entry, int year) sync* {
    if (entry.length == 10) {
      yield DateTime.tryParse(entry);
      return;
    }
    yield _monthDayIn(year, entry);
    yield _monthDayIn(year + 1, entry);
  }

  static DateTime? _monthDayIn(int year, String monthDay) {
    final int? month = int.tryParse(monthDay.substring(0, 2));
    final int? day = int.tryParse(monthDay.substring(3, 5));
    if (month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  static String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
