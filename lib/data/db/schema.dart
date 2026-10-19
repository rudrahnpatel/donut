import 'package:drift/drift.dart';

/// Committed blocks: the source of truth that syncs.
///
/// Times are floating local minutes (see `core/time/day_minutes.dart`).
/// Deleted rows stay as tombstones (`deleted = true`) so the deletion syncs.
@DataClassName('BlockRow')
class Blocks extends Table {
  TextColumn get id => text()();
  IntColumn get startMin => integer()();
  IntColumn get durMin => integer()();
  TextColumn get emoji => text().nullable()();
  TextColumn get activityId => text().nullable()();
  TextColumn get note => text().nullable()();

  /// The entry's own colour (ARGB); an activity's colour wins over it.
  IntColumn get color => integer().nullable()();
  TextColumn get seriesId => text().nullable()();

  /// A series instance edited by hand; the generator leaves it alone.
  BoolColumn get detached => boolean().withDefault(const Constant(false))();
  TextColumn get hlc => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

enum EditState { pending, draft }

/// Unsaved changes layered over [Blocks]: one row per touched block holding
/// its full proposed state. Written on every edit so nothing is lost if the
/// app dies; Save folds them into [Blocks], X deletes them.
@DataClassName('BlockEditRow')
class BlockEdits extends Table {
  TextColumn get blockId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  IntColumn get startMin => integer()();
  IntColumn get durMin => integer()();
  TextColumn get emoji => text().nullable()();
  TextColumn get activityId => text().nullable()();
  TextColumn get note => text().nullable()();

  /// The entry's own colour (ARGB); an activity's colour wins over it.
  IntColumn get color => integer().nullable()();
  TextColumn get seriesId => text().nullable()();

  /// HLC of the saved block when editing began; null for new blocks. If the
  /// saved row's HLC moves on (a sync), the edit is in conflict.
  TextColumn get baseHlc => text().nullable()();
  IntColumn get state => intEnum<EditState>()();
  IntColumn get editedAt => integer()();

  @override
  Set<Column> get primaryKey => {blockId};
}

@DataClassName('ActivityRow')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text()();
  IntColumn get color => integer()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get hlc => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TodoRow')
class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get activityId => text().nullable()();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();

  /// The block this to-do is scheduled into, if any.
  TextColumn get blockId => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get hlc => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A saved day layout; [blocksJson] holds `[{s, d, e?, a?, n?}]` with `s` as
/// minute-of-day (may exceed 1440 for spill) and `d` as duration.
@DataClassName('TemplateRow')
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get blocksJson => text()();
  TextColumn get hlc => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A reusable sequence of steps ("Commute": get ready 5 → walk 5 → train
/// 40) with no times of its own; it is laid out when used, from a start or
/// back from a pin. [stepsJson] holds `[{d, n?, a?, e?, c?}]`: duration,
/// label, activity, emoji, colour.
@DataClassName('ChainRow')
class Chains extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get stepsJson => text()();
  TextColumn get hlc => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Time actually worked, measured on the desktop (the Noctalia "Donut
/// Work" plugin, or estimated from Claude Code's logs for earlier days).
/// Floating local minutes like blocks; [projectsJson] maps project name →
/// seconds (projects can overlap, so they may add up to more than the
/// session). Synced, so the phone shows it too.
@DataClassName('WorkSessionRow')
class WorkSessions extends Table {
  /// `<source>-<start epoch ms>`: stable while the session grows.
  TextColumn get id => text()();
  IntColumn get startMin => integer()();
  IntColumn get endMin => integer()();
  TextColumn get projectsJson => text()();

  /// `tracker` (the plugin) or `claude-logs` (estimated history).
  TextColumn get source => text()();
  BoolColumn get manual => boolean().withDefault(const Constant(false))();
  TextColumn get hlc => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A recurring block. Instances are generated as ordinary [Blocks] rows with
/// deterministic ids (UUIDv5 of series id + day) a fixed window ahead.
@DataClassName('SeriesRow')
class Series extends Table {
  TextColumn get id => text()();

  /// `daily` or `weekly:1,3,5` (ISO weekdays, 1 = Monday).
  TextColumn get rule => text()();
  IntColumn get startMinOfDay => integer()();
  IntColumn get durMin => integer()();
  TextColumn get emoji => text().nullable()();
  TextColumn get activityId => text().nullable()();
  TextColumn get note => text().nullable()();

  /// First and (optional) last epoch day the series applies to.
  IntColumn get fromDay => integer()();
  IntColumn get untilDay => integer().nullable()();
  TextColumn get hlc => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A point in time to plan around: "Reach by 4:55", "Meeting at 5:00".
/// Pins stand on their own, so moving an entry doesn't move a deadline.
/// Pins dropped in plan mode are [draft] until ✓ and never sync before.
@DataClassName('PinRow')
class Pins extends Table {
  TextColumn get id => text()();

  /// Floating local minute, like blocks.
  IntColumn get atMin => integer()();

  /// `reachBy`, `meetingAt`, `leaveBy` or `custom` (see `PinKind`).
  TextColumn get kind => text()();

  /// The text of a custom pin.
  TextColumn get label => text().nullable()();
  BoolColumn get draft => boolean().withDefault(const Constant(false))();
  TextColumn get hlc => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Where a block lives in a remote system (e.g. its Google event id + etag).
@DataClassName('RemoteLinkRow')
class RemoteLinks extends Table {
  TextColumn get blockId => text()();
  TextColumn get provider => text()();
  TextColumn get remoteId => text()();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column> get primaryKey => {blockId, provider};
}

/// Settings that follow the user across devices (synced, LWW per key).
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get hlc => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Device-local state: device id, sync tokens, file ids. Never synced.
@DataClassName('LocalKvRow')
class LocalKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
