import 'dart:convert';

/// Moves entries with a given label from one activity (or none) to another:
/// "Home chores" with no activity → Chores. Matching is on the label and
/// the activity it has now, so a rule never touches an entry the user has
/// already filed somewhere else, and running it twice changes nothing.
class RefileRule {
  const RefileRule({required this.label, required this.from, required this.to});

  /// The entry's label (block note), compared trimmed and case-insensitive.
  final String label;

  /// The activity id the entry must have now; null means "no activity".
  final String? from;

  /// The activity id it moves to.
  final String to;

  bool matches(String? note, String? activityId) =>
      note != null &&
      note.trim().toLowerCase() == label.trim().toLowerCase() &&
      activityId == from;
}

/// The activity an entry labelled [note] filed under [activityId] should
/// move to, or null if no rule applies.
String? refiledActivity(
  String? note,
  String? activityId,
  Iterable<RefileRule> rules,
) {
  for (final r in rules) {
    if (r.matches(note, activityId)) return r.to;
  }
  return null;
}

/// A template's `blocksJson` (`[{s, d, e?, a?, n?}]`) with [rules] applied,
/// or null when nothing in it changes.
String? refileTemplateJson(String blocksJson, Iterable<RefileRule> rules) {
  final list = (jsonDecode(blocksJson) as List).cast<Map<String, dynamic>>();
  var changed = false;
  for (final b in list) {
    final to = refiledActivity(b['n'] as String?, b['a'] as String?, rules);
    if (to == null) continue;
    b['a'] = to;
    changed = true;
  }
  return changed ? jsonEncode(list) : null;
}
