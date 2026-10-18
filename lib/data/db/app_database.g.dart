// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BlocksTable extends Blocks with TableInfo<$BlocksTable, BlockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinMeta = const VerificationMeta(
    'startMin',
  );
  @override
  late final GeneratedColumn<int> startMin = GeneratedColumn<int>(
    'start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durMinMeta = const VerificationMeta('durMin');
  @override
  late final GeneratedColumn<int> durMin = GeneratedColumn<int>(
    'dur_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detachedMeta = const VerificationMeta(
    'detached',
  );
  @override
  late final GeneratedColumn<bool> detached = GeneratedColumn<bool>(
    'detached',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("detached" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startMin,
    durMin,
    emoji,
    activityId,
    note,
    color,
    seriesId,
    detached,
    hlc,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_min')) {
      context.handle(
        _startMinMeta,
        startMin.isAcceptableOrUnknown(data['start_min']!, _startMinMeta),
      );
    } else if (isInserting) {
      context.missing(_startMinMeta);
    }
    if (data.containsKey('dur_min')) {
      context.handle(
        _durMinMeta,
        durMin.isAcceptableOrUnknown(data['dur_min']!, _durMinMeta),
      );
    } else if (isInserting) {
      context.missing(_durMinMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('detached')) {
      context.handle(
        _detachedMeta,
        detached.isAcceptableOrUnknown(data['detached']!, _detachedMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min'],
      )!,
      durMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dur_min'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      detached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}detached'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $BlocksTable createAlias(String alias) {
    return $BlocksTable(attachedDatabase, alias);
  }
}

class BlockRow extends DataClass implements Insertable<BlockRow> {
  final String id;
  final int startMin;
  final int durMin;
  final String? emoji;
  final String? activityId;
  final String? note;

  /// The entry's own colour (ARGB); an activity's colour wins over it.
  final int? color;
  final String? seriesId;

  /// A series instance edited by hand; the generator leaves it alone.
  final bool detached;
  final String hlc;
  final bool deleted;
  const BlockRow({
    required this.id,
    required this.startMin,
    required this.durMin,
    this.emoji,
    this.activityId,
    this.note,
    this.color,
    this.seriesId,
    required this.detached,
    required this.hlc,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_min'] = Variable<int>(startMin);
    map['dur_min'] = Variable<int>(durMin);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    if (!nullToAbsent || activityId != null) {
      map['activity_id'] = Variable<String>(activityId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    map['detached'] = Variable<bool>(detached);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  BlocksCompanion toCompanion(bool nullToAbsent) {
    return BlocksCompanion(
      id: Value(id),
      startMin: Value(startMin),
      durMin: Value(durMin),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      activityId: activityId == null && nullToAbsent
          ? const Value.absent()
          : Value(activityId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      detached: Value(detached),
      hlc: Value(hlc),
      deleted: Value(deleted),
    );
  }

  factory BlockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockRow(
      id: serializer.fromJson<String>(json['id']),
      startMin: serializer.fromJson<int>(json['startMin']),
      durMin: serializer.fromJson<int>(json['durMin']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      activityId: serializer.fromJson<String?>(json['activityId']),
      note: serializer.fromJson<String?>(json['note']),
      color: serializer.fromJson<int?>(json['color']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      detached: serializer.fromJson<bool>(json['detached']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startMin': serializer.toJson<int>(startMin),
      'durMin': serializer.toJson<int>(durMin),
      'emoji': serializer.toJson<String?>(emoji),
      'activityId': serializer.toJson<String?>(activityId),
      'note': serializer.toJson<String?>(note),
      'color': serializer.toJson<int?>(color),
      'seriesId': serializer.toJson<String?>(seriesId),
      'detached': serializer.toJson<bool>(detached),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  BlockRow copyWith({
    String? id,
    int? startMin,
    int? durMin,
    Value<String?> emoji = const Value.absent(),
    Value<String?> activityId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> color = const Value.absent(),
    Value<String?> seriesId = const Value.absent(),
    bool? detached,
    String? hlc,
    bool? deleted,
  }) => BlockRow(
    id: id ?? this.id,
    startMin: startMin ?? this.startMin,
    durMin: durMin ?? this.durMin,
    emoji: emoji.present ? emoji.value : this.emoji,
    activityId: activityId.present ? activityId.value : this.activityId,
    note: note.present ? note.value : this.note,
    color: color.present ? color.value : this.color,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    detached: detached ?? this.detached,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
  );
  BlockRow copyWithCompanion(BlocksCompanion data) {
    return BlockRow(
      id: data.id.present ? data.id.value : this.id,
      startMin: data.startMin.present ? data.startMin.value : this.startMin,
      durMin: data.durMin.present ? data.durMin.value : this.durMin,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      note: data.note.present ? data.note.value : this.note,
      color: data.color.present ? data.color.value : this.color,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      detached: data.detached.present ? data.detached.value : this.detached,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockRow(')
          ..write('id: $id, ')
          ..write('startMin: $startMin, ')
          ..write('durMin: $durMin, ')
          ..write('emoji: $emoji, ')
          ..write('activityId: $activityId, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('seriesId: $seriesId, ')
          ..write('detached: $detached, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startMin,
    durMin,
    emoji,
    activityId,
    note,
    color,
    seriesId,
    detached,
    hlc,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockRow &&
          other.id == this.id &&
          other.startMin == this.startMin &&
          other.durMin == this.durMin &&
          other.emoji == this.emoji &&
          other.activityId == this.activityId &&
          other.note == this.note &&
          other.color == this.color &&
          other.seriesId == this.seriesId &&
          other.detached == this.detached &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted);
}

class BlocksCompanion extends UpdateCompanion<BlockRow> {
  final Value<String> id;
  final Value<int> startMin;
  final Value<int> durMin;
  final Value<String?> emoji;
  final Value<String?> activityId;
  final Value<String?> note;
  final Value<int?> color;
  final Value<String?> seriesId;
  final Value<bool> detached;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<int> rowid;
  const BlocksCompanion({
    this.id = const Value.absent(),
    this.startMin = const Value.absent(),
    this.durMin = const Value.absent(),
    this.emoji = const Value.absent(),
    this.activityId = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.detached = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlocksCompanion.insert({
    required String id,
    required int startMin,
    required int durMin,
    this.emoji = const Value.absent(),
    this.activityId = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.detached = const Value.absent(),
    required String hlc,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startMin = Value(startMin),
       durMin = Value(durMin),
       hlc = Value(hlc);
  static Insertable<BlockRow> custom({
    Expression<String>? id,
    Expression<int>? startMin,
    Expression<int>? durMin,
    Expression<String>? emoji,
    Expression<String>? activityId,
    Expression<String>? note,
    Expression<int>? color,
    Expression<String>? seriesId,
    Expression<bool>? detached,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startMin != null) 'start_min': startMin,
      if (durMin != null) 'dur_min': durMin,
      if (emoji != null) 'emoji': emoji,
      if (activityId != null) 'activity_id': activityId,
      if (note != null) 'note': note,
      if (color != null) 'color': color,
      if (seriesId != null) 'series_id': seriesId,
      if (detached != null) 'detached': detached,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlocksCompanion copyWith({
    Value<String>? id,
    Value<int>? startMin,
    Value<int>? durMin,
    Value<String?>? emoji,
    Value<String?>? activityId,
    Value<String?>? note,
    Value<int?>? color,
    Value<String?>? seriesId,
    Value<bool>? detached,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return BlocksCompanion(
      id: id ?? this.id,
      startMin: startMin ?? this.startMin,
      durMin: durMin ?? this.durMin,
      emoji: emoji ?? this.emoji,
      activityId: activityId ?? this.activityId,
      note: note ?? this.note,
      color: color ?? this.color,
      seriesId: seriesId ?? this.seriesId,
      detached: detached ?? this.detached,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startMin.present) {
      map['start_min'] = Variable<int>(startMin.value);
    }
    if (durMin.present) {
      map['dur_min'] = Variable<int>(durMin.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (detached.present) {
      map['detached'] = Variable<bool>(detached.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlocksCompanion(')
          ..write('id: $id, ')
          ..write('startMin: $startMin, ')
          ..write('durMin: $durMin, ')
          ..write('emoji: $emoji, ')
          ..write('activityId: $activityId, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('seriesId: $seriesId, ')
          ..write('detached: $detached, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlockEditsTable extends BlockEdits
    with TableInfo<$BlockEditsTable, BlockEditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlockEditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startMinMeta = const VerificationMeta(
    'startMin',
  );
  @override
  late final GeneratedColumn<int> startMin = GeneratedColumn<int>(
    'start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durMinMeta = const VerificationMeta('durMin');
  @override
  late final GeneratedColumn<int> durMin = GeneratedColumn<int>(
    'dur_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseHlcMeta = const VerificationMeta(
    'baseHlc',
  );
  @override
  late final GeneratedColumn<String> baseHlc = GeneratedColumn<String>(
    'base_hlc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EditState, int> state =
      GeneratedColumn<int>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<EditState>($BlockEditsTable.$converterstate);
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    blockId,
    deleted,
    startMin,
    durMin,
    emoji,
    activityId,
    note,
    color,
    seriesId,
    baseHlc,
    state,
    editedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'block_edits';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlockEditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blockIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('start_min')) {
      context.handle(
        _startMinMeta,
        startMin.isAcceptableOrUnknown(data['start_min']!, _startMinMeta),
      );
    } else if (isInserting) {
      context.missing(_startMinMeta);
    }
    if (data.containsKey('dur_min')) {
      context.handle(
        _durMinMeta,
        durMin.isAcceptableOrUnknown(data['dur_min']!, _durMinMeta),
      );
    } else if (isInserting) {
      context.missing(_durMinMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('base_hlc')) {
      context.handle(
        _baseHlcMeta,
        baseHlc.isAcceptableOrUnknown(data['base_hlc']!, _baseHlcMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {blockId};
  @override
  BlockEditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockEditRow(
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      startMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min'],
      )!,
      durMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dur_min'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      baseHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_hlc'],
      ),
      state: $BlockEditsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}state'],
        )!,
      ),
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
    );
  }

  @override
  $BlockEditsTable createAlias(String alias) {
    return $BlockEditsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EditState, int, int> $converterstate =
      const EnumIndexConverter<EditState>(EditState.values);
}

class BlockEditRow extends DataClass implements Insertable<BlockEditRow> {
  final String blockId;
  final bool deleted;
  final int startMin;
  final int durMin;
  final String? emoji;
  final String? activityId;
  final String? note;

  /// The entry's own colour (ARGB); an activity's colour wins over it.
  final int? color;
  final String? seriesId;

  /// HLC of the saved block when editing began; null for new blocks. If the
  /// saved row's HLC moves on (a sync), the edit is in conflict.
  final String? baseHlc;
  final EditState state;
  final int editedAt;
  const BlockEditRow({
    required this.blockId,
    required this.deleted,
    required this.startMin,
    required this.durMin,
    this.emoji,
    this.activityId,
    this.note,
    this.color,
    this.seriesId,
    this.baseHlc,
    required this.state,
    required this.editedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['block_id'] = Variable<String>(blockId);
    map['deleted'] = Variable<bool>(deleted);
    map['start_min'] = Variable<int>(startMin);
    map['dur_min'] = Variable<int>(durMin);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    if (!nullToAbsent || activityId != null) {
      map['activity_id'] = Variable<String>(activityId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || baseHlc != null) {
      map['base_hlc'] = Variable<String>(baseHlc);
    }
    {
      map['state'] = Variable<int>(
        $BlockEditsTable.$converterstate.toSql(state),
      );
    }
    map['edited_at'] = Variable<int>(editedAt);
    return map;
  }

  BlockEditsCompanion toCompanion(bool nullToAbsent) {
    return BlockEditsCompanion(
      blockId: Value(blockId),
      deleted: Value(deleted),
      startMin: Value(startMin),
      durMin: Value(durMin),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      activityId: activityId == null && nullToAbsent
          ? const Value.absent()
          : Value(activityId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      baseHlc: baseHlc == null && nullToAbsent
          ? const Value.absent()
          : Value(baseHlc),
      state: Value(state),
      editedAt: Value(editedAt),
    );
  }

  factory BlockEditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockEditRow(
      blockId: serializer.fromJson<String>(json['blockId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      startMin: serializer.fromJson<int>(json['startMin']),
      durMin: serializer.fromJson<int>(json['durMin']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      activityId: serializer.fromJson<String?>(json['activityId']),
      note: serializer.fromJson<String?>(json['note']),
      color: serializer.fromJson<int?>(json['color']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      baseHlc: serializer.fromJson<String?>(json['baseHlc']),
      state: $BlockEditsTable.$converterstate.fromJson(
        serializer.fromJson<int>(json['state']),
      ),
      editedAt: serializer.fromJson<int>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'blockId': serializer.toJson<String>(blockId),
      'deleted': serializer.toJson<bool>(deleted),
      'startMin': serializer.toJson<int>(startMin),
      'durMin': serializer.toJson<int>(durMin),
      'emoji': serializer.toJson<String?>(emoji),
      'activityId': serializer.toJson<String?>(activityId),
      'note': serializer.toJson<String?>(note),
      'color': serializer.toJson<int?>(color),
      'seriesId': serializer.toJson<String?>(seriesId),
      'baseHlc': serializer.toJson<String?>(baseHlc),
      'state': serializer.toJson<int>(
        $BlockEditsTable.$converterstate.toJson(state),
      ),
      'editedAt': serializer.toJson<int>(editedAt),
    };
  }

  BlockEditRow copyWith({
    String? blockId,
    bool? deleted,
    int? startMin,
    int? durMin,
    Value<String?> emoji = const Value.absent(),
    Value<String?> activityId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> color = const Value.absent(),
    Value<String?> seriesId = const Value.absent(),
    Value<String?> baseHlc = const Value.absent(),
    EditState? state,
    int? editedAt,
  }) => BlockEditRow(
    blockId: blockId ?? this.blockId,
    deleted: deleted ?? this.deleted,
    startMin: startMin ?? this.startMin,
    durMin: durMin ?? this.durMin,
    emoji: emoji.present ? emoji.value : this.emoji,
    activityId: activityId.present ? activityId.value : this.activityId,
    note: note.present ? note.value : this.note,
    color: color.present ? color.value : this.color,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    baseHlc: baseHlc.present ? baseHlc.value : this.baseHlc,
    state: state ?? this.state,
    editedAt: editedAt ?? this.editedAt,
  );
  BlockEditRow copyWithCompanion(BlockEditsCompanion data) {
    return BlockEditRow(
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      startMin: data.startMin.present ? data.startMin.value : this.startMin,
      durMin: data.durMin.present ? data.durMin.value : this.durMin,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      note: data.note.present ? data.note.value : this.note,
      color: data.color.present ? data.color.value : this.color,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      baseHlc: data.baseHlc.present ? data.baseHlc.value : this.baseHlc,
      state: data.state.present ? data.state.value : this.state,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockEditRow(')
          ..write('blockId: $blockId, ')
          ..write('deleted: $deleted, ')
          ..write('startMin: $startMin, ')
          ..write('durMin: $durMin, ')
          ..write('emoji: $emoji, ')
          ..write('activityId: $activityId, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('seriesId: $seriesId, ')
          ..write('baseHlc: $baseHlc, ')
          ..write('state: $state, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    blockId,
    deleted,
    startMin,
    durMin,
    emoji,
    activityId,
    note,
    color,
    seriesId,
    baseHlc,
    state,
    editedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockEditRow &&
          other.blockId == this.blockId &&
          other.deleted == this.deleted &&
          other.startMin == this.startMin &&
          other.durMin == this.durMin &&
          other.emoji == this.emoji &&
          other.activityId == this.activityId &&
          other.note == this.note &&
          other.color == this.color &&
          other.seriesId == this.seriesId &&
          other.baseHlc == this.baseHlc &&
          other.state == this.state &&
          other.editedAt == this.editedAt);
}

class BlockEditsCompanion extends UpdateCompanion<BlockEditRow> {
  final Value<String> blockId;
  final Value<bool> deleted;
  final Value<int> startMin;
  final Value<int> durMin;
  final Value<String?> emoji;
  final Value<String?> activityId;
  final Value<String?> note;
  final Value<int?> color;
  final Value<String?> seriesId;
  final Value<String?> baseHlc;
  final Value<EditState> state;
  final Value<int> editedAt;
  final Value<int> rowid;
  const BlockEditsCompanion({
    this.blockId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.startMin = const Value.absent(),
    this.durMin = const Value.absent(),
    this.emoji = const Value.absent(),
    this.activityId = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.baseHlc = const Value.absent(),
    this.state = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlockEditsCompanion.insert({
    required String blockId,
    this.deleted = const Value.absent(),
    required int startMin,
    required int durMin,
    this.emoji = const Value.absent(),
    this.activityId = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.baseHlc = const Value.absent(),
    required EditState state,
    required int editedAt,
    this.rowid = const Value.absent(),
  }) : blockId = Value(blockId),
       startMin = Value(startMin),
       durMin = Value(durMin),
       state = Value(state),
       editedAt = Value(editedAt);
  static Insertable<BlockEditRow> custom({
    Expression<String>? blockId,
    Expression<bool>? deleted,
    Expression<int>? startMin,
    Expression<int>? durMin,
    Expression<String>? emoji,
    Expression<String>? activityId,
    Expression<String>? note,
    Expression<int>? color,
    Expression<String>? seriesId,
    Expression<String>? baseHlc,
    Expression<int>? state,
    Expression<int>? editedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (blockId != null) 'block_id': blockId,
      if (deleted != null) 'deleted': deleted,
      if (startMin != null) 'start_min': startMin,
      if (durMin != null) 'dur_min': durMin,
      if (emoji != null) 'emoji': emoji,
      if (activityId != null) 'activity_id': activityId,
      if (note != null) 'note': note,
      if (color != null) 'color': color,
      if (seriesId != null) 'series_id': seriesId,
      if (baseHlc != null) 'base_hlc': baseHlc,
      if (state != null) 'state': state,
      if (editedAt != null) 'edited_at': editedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlockEditsCompanion copyWith({
    Value<String>? blockId,
    Value<bool>? deleted,
    Value<int>? startMin,
    Value<int>? durMin,
    Value<String?>? emoji,
    Value<String?>? activityId,
    Value<String?>? note,
    Value<int?>? color,
    Value<String?>? seriesId,
    Value<String?>? baseHlc,
    Value<EditState>? state,
    Value<int>? editedAt,
    Value<int>? rowid,
  }) {
    return BlockEditsCompanion(
      blockId: blockId ?? this.blockId,
      deleted: deleted ?? this.deleted,
      startMin: startMin ?? this.startMin,
      durMin: durMin ?? this.durMin,
      emoji: emoji ?? this.emoji,
      activityId: activityId ?? this.activityId,
      note: note ?? this.note,
      color: color ?? this.color,
      seriesId: seriesId ?? this.seriesId,
      baseHlc: baseHlc ?? this.baseHlc,
      state: state ?? this.state,
      editedAt: editedAt ?? this.editedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (startMin.present) {
      map['start_min'] = Variable<int>(startMin.value);
    }
    if (durMin.present) {
      map['dur_min'] = Variable<int>(durMin.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (baseHlc.present) {
      map['base_hlc'] = Variable<String>(baseHlc.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(
        $BlockEditsTable.$converterstate.toSql(state.value),
      );
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlockEditsCompanion(')
          ..write('blockId: $blockId, ')
          ..write('deleted: $deleted, ')
          ..write('startMin: $startMin, ')
          ..write('durMin: $durMin, ')
          ..write('emoji: $emoji, ')
          ..write('activityId: $activityId, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('seriesId: $seriesId, ')
          ..write('baseHlc: $baseHlc, ')
          ..write('state: $state, ')
          ..write('editedAt: $editedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, ActivityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    emoji,
    color,
    pinned,
    archived,
    sortOrder,
    hlc,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class ActivityRow extends DataClass implements Insertable<ActivityRow> {
  final String id;
  final String name;
  final String emoji;
  final int color;
  final bool pinned;
  final bool archived;
  final int sortOrder;
  final String hlc;
  final bool deleted;
  const ActivityRow({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.pinned,
    required this.archived,
    required this.sortOrder,
    required this.hlc,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['color'] = Variable<int>(color);
    map['pinned'] = Variable<bool>(pinned);
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      color: Value(color),
      pinned: Value(pinned),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
      hlc: Value(hlc),
      deleted: Value(deleted),
    );
  }

  factory ActivityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      color: serializer.fromJson<int>(json['color']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'color': serializer.toJson<int>(color),
      'pinned': serializer.toJson<bool>(pinned),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  ActivityRow copyWith({
    String? id,
    String? name,
    String? emoji,
    int? color,
    bool? pinned,
    bool? archived,
    int? sortOrder,
    String? hlc,
    bool? deleted,
  }) => ActivityRow(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    color: color ?? this.color,
    pinned: pinned ?? this.pinned,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
  );
  ActivityRow copyWithCompanion(ActivitiesCompanion data) {
    return ActivityRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      color: data.color.present ? data.color.value : this.color,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('color: $color, ')
          ..write('pinned: $pinned, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    emoji,
    color,
    pinned,
    archived,
    sortOrder,
    hlc,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.color == this.color &&
          other.pinned == this.pinned &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted);
}

class ActivitiesCompanion extends UpdateCompanion<ActivityRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<int> color;
  final Value<bool> pinned;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<int> rowid;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.color = const Value.absent(),
    this.pinned = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    required String id,
    required String name,
    required String emoji,
    required int color,
    this.pinned = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required String hlc,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       emoji = Value(emoji),
       color = Value(color),
       hlc = Value(hlc);
  static Insertable<ActivityRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<int>? color,
    Expression<bool>? pinned,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
      if (pinned != null) 'pinned': pinned,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? emoji,
    Value<int>? color,
    Value<bool>? pinned,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('color: $color, ')
          ..write('pinned: $pinned, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodosTable extends Todos with TableInfo<$TodosTable, TodoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    title,
    done,
    blockId,
    createdAt,
    hlc,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class TodoRow extends DataClass implements Insertable<TodoRow> {
  final String id;
  final String? activityId;
  final String title;
  final bool done;

  /// The block this to-do is scheduled into, if any.
  final String? blockId;
  final int createdAt;
  final String hlc;
  final bool deleted;
  const TodoRow({
    required this.id,
    this.activityId,
    required this.title,
    required this.done,
    this.blockId,
    required this.createdAt,
    required this.hlc,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || activityId != null) {
      map['activity_id'] = Variable<String>(activityId);
    }
    map['title'] = Variable<String>(title);
    map['done'] = Variable<bool>(done);
    if (!nullToAbsent || blockId != null) {
      map['block_id'] = Variable<String>(blockId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      activityId: activityId == null && nullToAbsent
          ? const Value.absent()
          : Value(activityId),
      title: Value(title),
      done: Value(done),
      blockId: blockId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockId),
      createdAt: Value(createdAt),
      hlc: Value(hlc),
      deleted: Value(deleted),
    );
  }

  factory TodoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoRow(
      id: serializer.fromJson<String>(json['id']),
      activityId: serializer.fromJson<String?>(json['activityId']),
      title: serializer.fromJson<String>(json['title']),
      done: serializer.fromJson<bool>(json['done']),
      blockId: serializer.fromJson<String?>(json['blockId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityId': serializer.toJson<String?>(activityId),
      'title': serializer.toJson<String>(title),
      'done': serializer.toJson<bool>(done),
      'blockId': serializer.toJson<String?>(blockId),
      'createdAt': serializer.toJson<int>(createdAt),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  TodoRow copyWith({
    String? id,
    Value<String?> activityId = const Value.absent(),
    String? title,
    bool? done,
    Value<String?> blockId = const Value.absent(),
    int? createdAt,
    String? hlc,
    bool? deleted,
  }) => TodoRow(
    id: id ?? this.id,
    activityId: activityId.present ? activityId.value : this.activityId,
    title: title ?? this.title,
    done: done ?? this.done,
    blockId: blockId.present ? blockId.value : this.blockId,
    createdAt: createdAt ?? this.createdAt,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
  );
  TodoRow copyWithCompanion(TodosCompanion data) {
    return TodoRow(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      title: data.title.present ? data.title.value : this.title,
      done: data.done.present ? data.done.value : this.done,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoRow(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('blockId: $blockId, ')
          ..write('createdAt: $createdAt, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityId,
    title,
    done,
    blockId,
    createdAt,
    hlc,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoRow &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.title == this.title &&
          other.done == this.done &&
          other.blockId == this.blockId &&
          other.createdAt == this.createdAt &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted);
}

class TodosCompanion extends UpdateCompanion<TodoRow> {
  final Value<String> id;
  final Value<String?> activityId;
  final Value<String> title;
  final Value<bool> done;
  final Value<String?> blockId;
  final Value<int> createdAt;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<int> rowid;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.title = const Value.absent(),
    this.done = const Value.absent(),
    this.blockId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodosCompanion.insert({
    required String id,
    this.activityId = const Value.absent(),
    required String title,
    this.done = const Value.absent(),
    this.blockId = const Value.absent(),
    required int createdAt,
    required String hlc,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       hlc = Value(hlc);
  static Insertable<TodoRow> custom({
    Expression<String>? id,
    Expression<String>? activityId,
    Expression<String>? title,
    Expression<bool>? done,
    Expression<String>? blockId,
    Expression<int>? createdAt,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (title != null) 'title': title,
      if (done != null) 'done': done,
      if (blockId != null) 'block_id': blockId,
      if (createdAt != null) 'created_at': createdAt,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodosCompanion copyWith({
    Value<String>? id,
    Value<String?>? activityId,
    Value<String>? title,
    Value<bool>? done,
    Value<String?>? blockId,
    Value<int>? createdAt,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return TodosCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      title: title ?? this.title,
      done: done ?? this.done,
      blockId: blockId ?? this.blockId,
      createdAt: createdAt ?? this.createdAt,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('blockId: $blockId, ')
          ..write('createdAt: $createdAt, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, TemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blocksJsonMeta = const VerificationMeta(
    'blocksJson',
  );
  @override
  late final GeneratedColumn<String> blocksJson = GeneratedColumn<String>(
    'blocks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, blocksJson, hlc, deleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('blocks_json')) {
      context.handle(
        _blocksJsonMeta,
        blocksJson.isAcceptableOrUnknown(data['blocks_json']!, _blocksJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_blocksJsonMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      blocksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocks_json'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class TemplateRow extends DataClass implements Insertable<TemplateRow> {
  final String id;
  final String name;
  final String blocksJson;
  final String hlc;
  final bool deleted;
  const TemplateRow({
    required this.id,
    required this.name,
    required this.blocksJson,
    required this.hlc,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['blocks_json'] = Variable<String>(blocksJson);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      name: Value(name),
      blocksJson: Value(blocksJson),
      hlc: Value(hlc),
      deleted: Value(deleted),
    );
  }

  factory TemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      blocksJson: serializer.fromJson<String>(json['blocksJson']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'blocksJson': serializer.toJson<String>(blocksJson),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  TemplateRow copyWith({
    String? id,
    String? name,
    String? blocksJson,
    String? hlc,
    bool? deleted,
  }) => TemplateRow(
    id: id ?? this.id,
    name: name ?? this.name,
    blocksJson: blocksJson ?? this.blocksJson,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
  );
  TemplateRow copyWithCompanion(TemplatesCompanion data) {
    return TemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      blocksJson: data.blocksJson.present
          ? data.blocksJson.value
          : this.blocksJson,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('blocksJson: $blocksJson, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, blocksJson, hlc, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.blocksJson == this.blocksJson &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted);
}

class TemplatesCompanion extends UpdateCompanion<TemplateRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> blocksJson;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.blocksJson = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String name,
    required String blocksJson,
    required String hlc,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       blocksJson = Value(blocksJson),
       hlc = Value(hlc);
  static Insertable<TemplateRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? blocksJson,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (blocksJson != null) 'blocks_json': blocksJson,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? blocksJson,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      blocksJson: blocksJson ?? this.blocksJson,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (blocksJson.present) {
      map['blocks_json'] = Variable<String>(blocksJson.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('blocksJson: $blocksJson, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesTable extends Series with TableInfo<$SeriesTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleMeta = const VerificationMeta('rule');
  @override
  late final GeneratedColumn<String> rule = GeneratedColumn<String>(
    'rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinOfDayMeta = const VerificationMeta(
    'startMinOfDay',
  );
  @override
  late final GeneratedColumn<int> startMinOfDay = GeneratedColumn<int>(
    'start_min_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durMinMeta = const VerificationMeta('durMin');
  @override
  late final GeneratedColumn<int> durMin = GeneratedColumn<int>(
    'dur_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromDayMeta = const VerificationMeta(
    'fromDay',
  );
  @override
  late final GeneratedColumn<int> fromDay = GeneratedColumn<int>(
    'from_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _untilDayMeta = const VerificationMeta(
    'untilDay',
  );
  @override
  late final GeneratedColumn<int> untilDay = GeneratedColumn<int>(
    'until_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rule,
    startMinOfDay,
    durMin,
    emoji,
    activityId,
    note,
    fromDay,
    untilDay,
    hlc,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rule')) {
      context.handle(
        _ruleMeta,
        rule.isAcceptableOrUnknown(data['rule']!, _ruleMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleMeta);
    }
    if (data.containsKey('start_min_of_day')) {
      context.handle(
        _startMinOfDayMeta,
        startMinOfDay.isAcceptableOrUnknown(
          data['start_min_of_day']!,
          _startMinOfDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinOfDayMeta);
    }
    if (data.containsKey('dur_min')) {
      context.handle(
        _durMinMeta,
        durMin.isAcceptableOrUnknown(data['dur_min']!, _durMinMeta),
      );
    } else if (isInserting) {
      context.missing(_durMinMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('from_day')) {
      context.handle(
        _fromDayMeta,
        fromDay.isAcceptableOrUnknown(data['from_day']!, _fromDayMeta),
      );
    } else if (isInserting) {
      context.missing(_fromDayMeta);
    }
    if (data.containsKey('until_day')) {
      context.handle(
        _untilDayMeta,
        untilDay.isAcceptableOrUnknown(data['until_day']!, _untilDayMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule'],
      )!,
      startMinOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min_of_day'],
      )!,
      durMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dur_min'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      fromDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_day'],
      )!,
      untilDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}until_day'],
      ),
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $SeriesTable createAlias(String alias) {
    return $SeriesTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final String id;

  /// `daily` or `weekly:1,3,5` (ISO weekdays, 1 = Monday).
  final String rule;
  final int startMinOfDay;
  final int durMin;
  final String? emoji;
  final String? activityId;
  final String? note;

  /// First and (optional) last epoch day the series applies to.
  final int fromDay;
  final int? untilDay;
  final String hlc;
  final bool deleted;
  const SeriesRow({
    required this.id,
    required this.rule,
    required this.startMinOfDay,
    required this.durMin,
    this.emoji,
    this.activityId,
    this.note,
    required this.fromDay,
    this.untilDay,
    required this.hlc,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rule'] = Variable<String>(rule);
    map['start_min_of_day'] = Variable<int>(startMinOfDay);
    map['dur_min'] = Variable<int>(durMin);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    if (!nullToAbsent || activityId != null) {
      map['activity_id'] = Variable<String>(activityId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['from_day'] = Variable<int>(fromDay);
    if (!nullToAbsent || untilDay != null) {
      map['until_day'] = Variable<int>(untilDay);
    }
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  SeriesCompanion toCompanion(bool nullToAbsent) {
    return SeriesCompanion(
      id: Value(id),
      rule: Value(rule),
      startMinOfDay: Value(startMinOfDay),
      durMin: Value(durMin),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      activityId: activityId == null && nullToAbsent
          ? const Value.absent()
          : Value(activityId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      fromDay: Value(fromDay),
      untilDay: untilDay == null && nullToAbsent
          ? const Value.absent()
          : Value(untilDay),
      hlc: Value(hlc),
      deleted: Value(deleted),
    );
  }

  factory SeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      id: serializer.fromJson<String>(json['id']),
      rule: serializer.fromJson<String>(json['rule']),
      startMinOfDay: serializer.fromJson<int>(json['startMinOfDay']),
      durMin: serializer.fromJson<int>(json['durMin']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      activityId: serializer.fromJson<String?>(json['activityId']),
      note: serializer.fromJson<String?>(json['note']),
      fromDay: serializer.fromJson<int>(json['fromDay']),
      untilDay: serializer.fromJson<int?>(json['untilDay']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rule': serializer.toJson<String>(rule),
      'startMinOfDay': serializer.toJson<int>(startMinOfDay),
      'durMin': serializer.toJson<int>(durMin),
      'emoji': serializer.toJson<String?>(emoji),
      'activityId': serializer.toJson<String?>(activityId),
      'note': serializer.toJson<String?>(note),
      'fromDay': serializer.toJson<int>(fromDay),
      'untilDay': serializer.toJson<int?>(untilDay),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  SeriesRow copyWith({
    String? id,
    String? rule,
    int? startMinOfDay,
    int? durMin,
    Value<String?> emoji = const Value.absent(),
    Value<String?> activityId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? fromDay,
    Value<int?> untilDay = const Value.absent(),
    String? hlc,
    bool? deleted,
  }) => SeriesRow(
    id: id ?? this.id,
    rule: rule ?? this.rule,
    startMinOfDay: startMinOfDay ?? this.startMinOfDay,
    durMin: durMin ?? this.durMin,
    emoji: emoji.present ? emoji.value : this.emoji,
    activityId: activityId.present ? activityId.value : this.activityId,
    note: note.present ? note.value : this.note,
    fromDay: fromDay ?? this.fromDay,
    untilDay: untilDay.present ? untilDay.value : this.untilDay,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
  );
  SeriesRow copyWithCompanion(SeriesCompanion data) {
    return SeriesRow(
      id: data.id.present ? data.id.value : this.id,
      rule: data.rule.present ? data.rule.value : this.rule,
      startMinOfDay: data.startMinOfDay.present
          ? data.startMinOfDay.value
          : this.startMinOfDay,
      durMin: data.durMin.present ? data.durMin.value : this.durMin,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      note: data.note.present ? data.note.value : this.note,
      fromDay: data.fromDay.present ? data.fromDay.value : this.fromDay,
      untilDay: data.untilDay.present ? data.untilDay.value : this.untilDay,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('id: $id, ')
          ..write('rule: $rule, ')
          ..write('startMinOfDay: $startMinOfDay, ')
          ..write('durMin: $durMin, ')
          ..write('emoji: $emoji, ')
          ..write('activityId: $activityId, ')
          ..write('note: $note, ')
          ..write('fromDay: $fromDay, ')
          ..write('untilDay: $untilDay, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rule,
    startMinOfDay,
    durMin,
    emoji,
    activityId,
    note,
    fromDay,
    untilDay,
    hlc,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.id == this.id &&
          other.rule == this.rule &&
          other.startMinOfDay == this.startMinOfDay &&
          other.durMin == this.durMin &&
          other.emoji == this.emoji &&
          other.activityId == this.activityId &&
          other.note == this.note &&
          other.fromDay == this.fromDay &&
          other.untilDay == this.untilDay &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted);
}

class SeriesCompanion extends UpdateCompanion<SeriesRow> {
  final Value<String> id;
  final Value<String> rule;
  final Value<int> startMinOfDay;
  final Value<int> durMin;
  final Value<String?> emoji;
  final Value<String?> activityId;
  final Value<String?> note;
  final Value<int> fromDay;
  final Value<int?> untilDay;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<int> rowid;
  const SeriesCompanion({
    this.id = const Value.absent(),
    this.rule = const Value.absent(),
    this.startMinOfDay = const Value.absent(),
    this.durMin = const Value.absent(),
    this.emoji = const Value.absent(),
    this.activityId = const Value.absent(),
    this.note = const Value.absent(),
    this.fromDay = const Value.absent(),
    this.untilDay = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesCompanion.insert({
    required String id,
    required String rule,
    required int startMinOfDay,
    required int durMin,
    this.emoji = const Value.absent(),
    this.activityId = const Value.absent(),
    this.note = const Value.absent(),
    required int fromDay,
    this.untilDay = const Value.absent(),
    required String hlc,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rule = Value(rule),
       startMinOfDay = Value(startMinOfDay),
       durMin = Value(durMin),
       fromDay = Value(fromDay),
       hlc = Value(hlc);
  static Insertable<SeriesRow> custom({
    Expression<String>? id,
    Expression<String>? rule,
    Expression<int>? startMinOfDay,
    Expression<int>? durMin,
    Expression<String>? emoji,
    Expression<String>? activityId,
    Expression<String>? note,
    Expression<int>? fromDay,
    Expression<int>? untilDay,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rule != null) 'rule': rule,
      if (startMinOfDay != null) 'start_min_of_day': startMinOfDay,
      if (durMin != null) 'dur_min': durMin,
      if (emoji != null) 'emoji': emoji,
      if (activityId != null) 'activity_id': activityId,
      if (note != null) 'note': note,
      if (fromDay != null) 'from_day': fromDay,
      if (untilDay != null) 'until_day': untilDay,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesCompanion copyWith({
    Value<String>? id,
    Value<String>? rule,
    Value<int>? startMinOfDay,
    Value<int>? durMin,
    Value<String?>? emoji,
    Value<String?>? activityId,
    Value<String?>? note,
    Value<int>? fromDay,
    Value<int?>? untilDay,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return SeriesCompanion(
      id: id ?? this.id,
      rule: rule ?? this.rule,
      startMinOfDay: startMinOfDay ?? this.startMinOfDay,
      durMin: durMin ?? this.durMin,
      emoji: emoji ?? this.emoji,
      activityId: activityId ?? this.activityId,
      note: note ?? this.note,
      fromDay: fromDay ?? this.fromDay,
      untilDay: untilDay ?? this.untilDay,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rule.present) {
      map['rule'] = Variable<String>(rule.value);
    }
    if (startMinOfDay.present) {
      map['start_min_of_day'] = Variable<int>(startMinOfDay.value);
    }
    if (durMin.present) {
      map['dur_min'] = Variable<int>(durMin.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (fromDay.present) {
      map['from_day'] = Variable<int>(fromDay.value);
    }
    if (untilDay.present) {
      map['until_day'] = Variable<int>(untilDay.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesCompanion(')
          ..write('id: $id, ')
          ..write('rule: $rule, ')
          ..write('startMinOfDay: $startMinOfDay, ')
          ..write('durMin: $durMin, ')
          ..write('emoji: $emoji, ')
          ..write('activityId: $activityId, ')
          ..write('note: $note, ')
          ..write('fromDay: $fromDay, ')
          ..write('untilDay: $untilDay, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PinsTable extends Pins with TableInfo<$PinsTable, PinRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMinMeta = const VerificationMeta('atMin');
  @override
  late final GeneratedColumn<int> atMin = GeneratedColumn<int>(
    'at_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _draftMeta = const VerificationMeta('draft');
  @override
  late final GeneratedColumn<bool> draft = GeneratedColumn<bool>(
    'draft',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("draft" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    atMin,
    kind,
    label,
    draft,
    hlc,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<PinRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('at_min')) {
      context.handle(
        _atMinMeta,
        atMin.isAcceptableOrUnknown(data['at_min']!, _atMinMeta),
      );
    } else if (isInserting) {
      context.missing(_atMinMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('draft')) {
      context.handle(
        _draftMeta,
        draft.isAcceptableOrUnknown(data['draft']!, _draftMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PinRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      atMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_min'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      draft: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}draft'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $PinsTable createAlias(String alias) {
    return $PinsTable(attachedDatabase, alias);
  }
}

class PinRow extends DataClass implements Insertable<PinRow> {
  final String id;

  /// Floating local minute, like blocks.
  final int atMin;

  /// `reachBy`, `meetingAt`, `leaveBy` or `custom` (see `PinKind`).
  final String kind;

  /// The text of a custom pin.
  final String? label;
  final bool draft;
  final String hlc;
  final bool deleted;
  const PinRow({
    required this.id,
    required this.atMin,
    required this.kind,
    this.label,
    required this.draft,
    required this.hlc,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['at_min'] = Variable<int>(atMin);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['draft'] = Variable<bool>(draft);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  PinsCompanion toCompanion(bool nullToAbsent) {
    return PinsCompanion(
      id: Value(id),
      atMin: Value(atMin),
      kind: Value(kind),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      draft: Value(draft),
      hlc: Value(hlc),
      deleted: Value(deleted),
    );
  }

  factory PinRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PinRow(
      id: serializer.fromJson<String>(json['id']),
      atMin: serializer.fromJson<int>(json['atMin']),
      kind: serializer.fromJson<String>(json['kind']),
      label: serializer.fromJson<String?>(json['label']),
      draft: serializer.fromJson<bool>(json['draft']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'atMin': serializer.toJson<int>(atMin),
      'kind': serializer.toJson<String>(kind),
      'label': serializer.toJson<String?>(label),
      'draft': serializer.toJson<bool>(draft),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  PinRow copyWith({
    String? id,
    int? atMin,
    String? kind,
    Value<String?> label = const Value.absent(),
    bool? draft,
    String? hlc,
    bool? deleted,
  }) => PinRow(
    id: id ?? this.id,
    atMin: atMin ?? this.atMin,
    kind: kind ?? this.kind,
    label: label.present ? label.value : this.label,
    draft: draft ?? this.draft,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
  );
  PinRow copyWithCompanion(PinsCompanion data) {
    return PinRow(
      id: data.id.present ? data.id.value : this.id,
      atMin: data.atMin.present ? data.atMin.value : this.atMin,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
      draft: data.draft.present ? data.draft.value : this.draft,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PinRow(')
          ..write('id: $id, ')
          ..write('atMin: $atMin, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('draft: $draft, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, atMin, kind, label, draft, hlc, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PinRow &&
          other.id == this.id &&
          other.atMin == this.atMin &&
          other.kind == this.kind &&
          other.label == this.label &&
          other.draft == this.draft &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted);
}

class PinsCompanion extends UpdateCompanion<PinRow> {
  final Value<String> id;
  final Value<int> atMin;
  final Value<String> kind;
  final Value<String?> label;
  final Value<bool> draft;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<int> rowid;
  const PinsCompanion({
    this.id = const Value.absent(),
    this.atMin = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.draft = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PinsCompanion.insert({
    required String id,
    required int atMin,
    required String kind,
    this.label = const Value.absent(),
    this.draft = const Value.absent(),
    required String hlc,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       atMin = Value(atMin),
       kind = Value(kind),
       hlc = Value(hlc);
  static Insertable<PinRow> custom({
    Expression<String>? id,
    Expression<int>? atMin,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<bool>? draft,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (atMin != null) 'at_min': atMin,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (draft != null) 'draft': draft,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PinsCompanion copyWith({
    Value<String>? id,
    Value<int>? atMin,
    Value<String>? kind,
    Value<String?>? label,
    Value<bool>? draft,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return PinsCompanion(
      id: id ?? this.id,
      atMin: atMin ?? this.atMin,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      draft: draft ?? this.draft,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (atMin.present) {
      map['at_min'] = Variable<int>(atMin.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (draft.present) {
      map['draft'] = Variable<bool>(draft.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PinsCompanion(')
          ..write('id: $id, ')
          ..write('atMin: $atMin, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('draft: $draft, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteLinksTable extends RemoteLinks
    with TableInfo<$RemoteLinksTable, RemoteLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [blockId, provider, remoteId, etag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteLinkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blockIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {blockId, provider};
  @override
  RemoteLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteLinkRow(
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
    );
  }

  @override
  $RemoteLinksTable createAlias(String alias) {
    return $RemoteLinksTable(attachedDatabase, alias);
  }
}

class RemoteLinkRow extends DataClass implements Insertable<RemoteLinkRow> {
  final String blockId;
  final String provider;
  final String remoteId;
  final String? etag;
  const RemoteLinkRow({
    required this.blockId,
    required this.provider,
    required this.remoteId,
    this.etag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['block_id'] = Variable<String>(blockId);
    map['provider'] = Variable<String>(provider);
    map['remote_id'] = Variable<String>(remoteId);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  RemoteLinksCompanion toCompanion(bool nullToAbsent) {
    return RemoteLinksCompanion(
      blockId: Value(blockId),
      provider: Value(provider),
      remoteId: Value(remoteId),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory RemoteLinkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteLinkRow(
      blockId: serializer.fromJson<String>(json['blockId']),
      provider: serializer.fromJson<String>(json['provider']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'blockId': serializer.toJson<String>(blockId),
      'provider': serializer.toJson<String>(provider),
      'remoteId': serializer.toJson<String>(remoteId),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  RemoteLinkRow copyWith({
    String? blockId,
    String? provider,
    String? remoteId,
    Value<String?> etag = const Value.absent(),
  }) => RemoteLinkRow(
    blockId: blockId ?? this.blockId,
    provider: provider ?? this.provider,
    remoteId: remoteId ?? this.remoteId,
    etag: etag.present ? etag.value : this.etag,
  );
  RemoteLinkRow copyWithCompanion(RemoteLinksCompanion data) {
    return RemoteLinkRow(
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      provider: data.provider.present ? data.provider.value : this.provider,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteLinkRow(')
          ..write('blockId: $blockId, ')
          ..write('provider: $provider, ')
          ..write('remoteId: $remoteId, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(blockId, provider, remoteId, etag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteLinkRow &&
          other.blockId == this.blockId &&
          other.provider == this.provider &&
          other.remoteId == this.remoteId &&
          other.etag == this.etag);
}

class RemoteLinksCompanion extends UpdateCompanion<RemoteLinkRow> {
  final Value<String> blockId;
  final Value<String> provider;
  final Value<String> remoteId;
  final Value<String?> etag;
  final Value<int> rowid;
  const RemoteLinksCompanion({
    this.blockId = const Value.absent(),
    this.provider = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteLinksCompanion.insert({
    required String blockId,
    required String provider,
    required String remoteId,
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : blockId = Value(blockId),
       provider = Value(provider),
       remoteId = Value(remoteId);
  static Insertable<RemoteLinkRow> custom({
    Expression<String>? blockId,
    Expression<String>? provider,
    Expression<String>? remoteId,
    Expression<String>? etag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (blockId != null) 'block_id': blockId,
      if (provider != null) 'provider': provider,
      if (remoteId != null) 'remote_id': remoteId,
      if (etag != null) 'etag': etag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteLinksCompanion copyWith({
    Value<String>? blockId,
    Value<String>? provider,
    Value<String>? remoteId,
    Value<String?>? etag,
    Value<int>? rowid,
  }) {
    return RemoteLinksCompanion(
      blockId: blockId ?? this.blockId,
      provider: provider ?? this.provider,
      remoteId: remoteId ?? this.remoteId,
      etag: etag ?? this.etag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteLinksCompanion(')
          ..write('blockId: $blockId, ')
          ..write('provider: $provider, ')
          ..write('remoteId: $remoteId, ')
          ..write('etag: $etag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, hlc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  final String hlc;
  const SettingRow({required this.key, required this.value, required this.hlc});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['hlc'] = Variable<String>(hlc);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      hlc: Value(hlc),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      hlc: serializer.fromJson<String>(json['hlc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'hlc': serializer.toJson<String>(hlc),
    };
  }

  SettingRow copyWith({String? key, String? value, String? hlc}) => SettingRow(
    key: key ?? this.key,
    value: value ?? this.value,
    hlc: hlc ?? this.hlc,
  );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('hlc: $hlc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, hlc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.hlc == this.hlc);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> hlc;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.hlc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required String hlc,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       hlc = Value(hlc);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? hlc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (hlc != null) 'hlc': hlc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<String>? hlc,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      hlc: hlc ?? this.hlc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('hlc: $hlc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalKvTable extends LocalKv with TableInfo<$LocalKvTable, LocalKvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalKvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalKvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalKvRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalKvTable createAlias(String alias) {
    return $LocalKvTable(attachedDatabase, alias);
  }
}

class LocalKvRow extends DataClass implements Insertable<LocalKvRow> {
  final String key;
  final String value;
  const LocalKvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalKvCompanion toCompanion(bool nullToAbsent) {
    return LocalKvCompanion(key: Value(key), value: Value(value));
  }

  factory LocalKvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalKvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalKvRow copyWith({String? key, String? value}) =>
      LocalKvRow(key: key ?? this.key, value: value ?? this.value);
  LocalKvRow copyWithCompanion(LocalKvCompanion data) {
    return LocalKvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalKvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalKvRow &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalKvCompanion extends UpdateCompanion<LocalKvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalKvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalKvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BlocksTable blocks = $BlocksTable(this);
  late final $BlockEditsTable blockEdits = $BlockEditsTable(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $TodosTable todos = $TodosTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $SeriesTable series = $SeriesTable(this);
  late final $PinsTable pins = $PinsTable(this);
  late final $RemoteLinksTable remoteLinks = $RemoteLinksTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $LocalKvTable localKv = $LocalKvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    blocks,
    blockEdits,
    activities,
    todos,
    templates,
    series,
    pins,
    remoteLinks,
    settings,
    localKv,
  ];
}

typedef $$BlocksTableCreateCompanionBuilder = BlocksCompanion Function({
  required String id,
  required int startMin,
  required int durMin,
  Value<String?> emoji,
  Value<String?> activityId,
  Value<String?> note,
  Value<int?> color,
  Value<String?> seriesId,
  Value<bool> detached,
  required String hlc,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$BlocksTableUpdateCompanionBuilder = BlocksCompanion Function({
  Value<String> id,
  Value<int> startMin,
  Value<int> durMin,
  Value<String?> emoji,
  Value<String?> activityId,
  Value<String?> note,
  Value<int?> color,
  Value<String?> seriesId,
  Value<bool> detached,
  Value<String> hlc,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$BlocksTableFilterComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durMin => $composableBuilder(
    column: $table.durMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get detached => $composableBuilder(
    column: $table.detached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durMin => $composableBuilder(
    column: $table.durMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get detached => $composableBuilder(
    column: $table.detached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startMin =>
      $composableBuilder(column: $table.startMin, builder: (column) => column);

  GeneratedColumn<int> get durMin =>
      $composableBuilder(column: $table.durMin, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<bool> get detached =>
      $composableBuilder(column: $table.detached, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$BlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlocksTable,
          BlockRow,
          $$BlocksTableFilterComposer,
          $$BlocksTableOrderingComposer,
          $$BlocksTableAnnotationComposer,
          $$BlocksTableCreateCompanionBuilder,
          $$BlocksTableUpdateCompanionBuilder,
          (BlockRow, BaseReferences<_$AppDatabase, $BlocksTable, BlockRow>),
          BlockRow,
          PrefetchHooks Function()
        > {
  $$BlocksTableTableManager(_$AppDatabase db, $BlocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> startMin = const Value.absent(),
                Value<int> durMin = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<bool> detached = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlocksCompanion(
                id: id,
                startMin: startMin,
                durMin: durMin,
                emoji: emoji,
                activityId: activityId,
                note: note,
                color: color,
                seriesId: seriesId,
                detached: detached,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int startMin,
                required int durMin,
                Value<String?> emoji = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<bool> detached = const Value.absent(),
                required String hlc,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlocksCompanion.insert(
                id: id,
                startMin: startMin,
                durMin: durMin,
                emoji: emoji,
                activityId: activityId,
                note: note,
                color: color,
                seriesId: seriesId,
                detached: detached,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlocksTable, BlockRow>(table),
                  BaseReferences<_$AppDatabase, $BlocksTable, BlockRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlocksTable,
      BlockRow,
      $$BlocksTableFilterComposer,
      $$BlocksTableOrderingComposer,
      $$BlocksTableAnnotationComposer,
      $$BlocksTableCreateCompanionBuilder,
      $$BlocksTableUpdateCompanionBuilder,
      (BlockRow, BaseReferences<_$AppDatabase, $BlocksTable, BlockRow>),
      BlockRow,
      PrefetchHooks Function()
    >;
typedef $$BlockEditsTableCreateCompanionBuilder = BlockEditsCompanion Function({
  required String blockId,
  Value<bool> deleted,
  required int startMin,
  required int durMin,
  Value<String?> emoji,
  Value<String?> activityId,
  Value<String?> note,
  Value<int?> color,
  Value<String?> seriesId,
  Value<String?> baseHlc,
  required EditState state,
  required int editedAt,
  Value<int> rowid,
});
typedef $$BlockEditsTableUpdateCompanionBuilder = BlockEditsCompanion Function({
  Value<String> blockId,
  Value<bool> deleted,
  Value<int> startMin,
  Value<int> durMin,
  Value<String?> emoji,
  Value<String?> activityId,
  Value<String?> note,
  Value<int?> color,
  Value<String?> seriesId,
  Value<String?> baseHlc,
  Value<EditState> state,
  Value<int> editedAt,
  Value<int> rowid,
});

class $$BlockEditsTableFilterComposer
    extends Composer<_$AppDatabase, $BlockEditsTable> {
  $$BlockEditsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durMin => $composableBuilder(
    column: $table.durMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseHlc => $composableBuilder(
    column: $table.baseHlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EditState, EditState, int> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlockEditsTableOrderingComposer
    extends Composer<_$AppDatabase, $BlockEditsTable> {
  $$BlockEditsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durMin => $composableBuilder(
    column: $table.durMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseHlc => $composableBuilder(
    column: $table.baseHlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlockEditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlockEditsTable> {
  $$BlockEditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get startMin =>
      $composableBuilder(column: $table.startMin, builder: (column) => column);

  GeneratedColumn<int> get durMin =>
      $composableBuilder(column: $table.durMin, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get baseHlc =>
      $composableBuilder(column: $table.baseHlc, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EditState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);
}

class $$BlockEditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlockEditsTable,
          BlockEditRow,
          $$BlockEditsTableFilterComposer,
          $$BlockEditsTableOrderingComposer,
          $$BlockEditsTableAnnotationComposer,
          $$BlockEditsTableCreateCompanionBuilder,
          $$BlockEditsTableUpdateCompanionBuilder,
          (
            BlockEditRow,
            BaseReferences<_$AppDatabase, $BlockEditsTable, BlockEditRow>,
          ),
          BlockEditRow,
          PrefetchHooks Function()
        > {
  $$BlockEditsTableTableManager(_$AppDatabase db, $BlockEditsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlockEditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlockEditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlockEditsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> blockId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> startMin = const Value.absent(),
                Value<int> durMin = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> baseHlc = const Value.absent(),
                Value<EditState> state = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlockEditsCompanion(
                blockId: blockId,
                deleted: deleted,
                startMin: startMin,
                durMin: durMin,
                emoji: emoji,
                activityId: activityId,
                note: note,
                color: color,
                seriesId: seriesId,
                baseHlc: baseHlc,
                state: state,
                editedAt: editedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String blockId,
                Value<bool> deleted = const Value.absent(),
                required int startMin,
                required int durMin,
                Value<String?> emoji = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> baseHlc = const Value.absent(),
                required EditState state,
                required int editedAt,
                Value<int> rowid = const Value.absent(),
              }) => BlockEditsCompanion.insert(
                blockId: blockId,
                deleted: deleted,
                startMin: startMin,
                durMin: durMin,
                emoji: emoji,
                activityId: activityId,
                note: note,
                color: color,
                seriesId: seriesId,
                baseHlc: baseHlc,
                state: state,
                editedAt: editedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlockEditsTable, BlockEditRow>(table),
                  BaseReferences<_$AppDatabase, $BlockEditsTable, BlockEditRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlockEditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlockEditsTable,
      BlockEditRow,
      $$BlockEditsTableFilterComposer,
      $$BlockEditsTableOrderingComposer,
      $$BlockEditsTableAnnotationComposer,
      $$BlockEditsTableCreateCompanionBuilder,
      $$BlockEditsTableUpdateCompanionBuilder,
      (
        BlockEditRow,
        BaseReferences<_$AppDatabase, $BlockEditsTable, BlockEditRow>,
      ),
      BlockEditRow,
      PrefetchHooks Function()
    >;
typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  required String id,
  required String name,
  required String emoji,
  required int color,
  Value<bool> pinned,
  Value<bool> archived,
  Value<int> sortOrder,
  required String hlc,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> emoji,
  Value<int> color,
  Value<bool> pinned,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<String> hlc,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitiesTable,
          ActivityRow,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (
            ActivityRow,
            BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityRow>,
          ),
          ActivityRow,
          PrefetchHooks Function()
        > {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                name: name,
                emoji: emoji,
                color: color,
                pinned: pinned,
                archived: archived,
                sortOrder: sortOrder,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String emoji,
                required int color,
                Value<bool> pinned = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required String hlc,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion.insert(
                id: id,
                name: name,
                emoji: emoji,
                color: color,
                pinned: pinned,
                archived: archived,
                sortOrder: sortOrder,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivitiesTable, ActivityRow>(table),
                  BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitiesTable,
      ActivityRow,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (
        ActivityRow,
        BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityRow>,
      ),
      ActivityRow,
      PrefetchHooks Function()
    >;
typedef $$TodosTableCreateCompanionBuilder = TodosCompanion Function({
  required String id,
  Value<String?> activityId,
  required String title,
  Value<bool> done,
  Value<String?> blockId,
  required int createdAt,
  required String hlc,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$TodosTableUpdateCompanionBuilder = TodosCompanion Function({
  Value<String> id,
  Value<String?> activityId,
  Value<String> title,
  Value<bool> done,
  Value<String?> blockId,
  Value<int> createdAt,
  Value<String> hlc,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$TodosTableFilterComposer extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodosTableOrderingComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$TodosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodosTable,
          TodoRow,
          $$TodosTableFilterComposer,
          $$TodosTableOrderingComposer,
          $$TodosTableAnnotationComposer,
          $$TodosTableCreateCompanionBuilder,
          $$TodosTableUpdateCompanionBuilder,
          (TodoRow, BaseReferences<_$AppDatabase, $TodosTable, TodoRow>),
          TodoRow,
          PrefetchHooks Function()
        > {
  $$TodosTableTableManager(_$AppDatabase db, $TodosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<String?> blockId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodosCompanion(
                id: id,
                activityId: activityId,
                title: title,
                done: done,
                blockId: blockId,
                createdAt: createdAt,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> activityId = const Value.absent(),
                required String title,
                Value<bool> done = const Value.absent(),
                Value<String?> blockId = const Value.absent(),
                required int createdAt,
                required String hlc,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodosCompanion.insert(
                id: id,
                activityId: activityId,
                title: title,
                done: done,
                blockId: blockId,
                createdAt: createdAt,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TodosTable, TodoRow>(table),
                  BaseReferences<_$AppDatabase, $TodosTable, TodoRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TodosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodosTable,
      TodoRow,
      $$TodosTableFilterComposer,
      $$TodosTableOrderingComposer,
      $$TodosTableAnnotationComposer,
      $$TodosTableCreateCompanionBuilder,
      $$TodosTableUpdateCompanionBuilder,
      (TodoRow, BaseReferences<_$AppDatabase, $TodosTable, TodoRow>),
      TodoRow,
      PrefetchHooks Function()
    >;
typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required String name,
  required String blocksJson,
  required String hlc,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> blocksJson,
  Value<String> hlc,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          TemplateRow,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (
            TemplateRow,
            BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>,
          ),
          TemplateRow,
          PrefetchHooks Function()
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> blocksJson = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(
                id: id,
                name: name,
                blocksJson: blocksJson,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String blocksJson,
                required String hlc,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                name: name,
                blocksJson: blocksJson,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplatesTable, TemplateRow>(table),
                  BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      TemplateRow,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (
        TemplateRow,
        BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>,
      ),
      TemplateRow,
      PrefetchHooks Function()
    >;
typedef $$SeriesTableCreateCompanionBuilder = SeriesCompanion Function({
  required String id,
  required String rule,
  required int startMinOfDay,
  required int durMin,
  Value<String?> emoji,
  Value<String?> activityId,
  Value<String?> note,
  required int fromDay,
  Value<int?> untilDay,
  required String hlc,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$SeriesTableUpdateCompanionBuilder = SeriesCompanion Function({
  Value<String> id,
  Value<String> rule,
  Value<int> startMinOfDay,
  Value<int> durMin,
  Value<String?> emoji,
  Value<String?> activityId,
  Value<String?> note,
  Value<int> fromDay,
  Value<int?> untilDay,
  Value<String> hlc,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$SeriesTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesTable> {
  $$SeriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinOfDay => $composableBuilder(
    column: $table.startMinOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durMin => $composableBuilder(
    column: $table.durMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromDay => $composableBuilder(
    column: $table.fromDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get untilDay => $composableBuilder(
    column: $table.untilDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesTable> {
  $$SeriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinOfDay => $composableBuilder(
    column: $table.startMinOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durMin => $composableBuilder(
    column: $table.durMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromDay => $composableBuilder(
    column: $table.fromDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get untilDay => $composableBuilder(
    column: $table.untilDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesTable> {
  $$SeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rule =>
      $composableBuilder(column: $table.rule, builder: (column) => column);

  GeneratedColumn<int> get startMinOfDay => $composableBuilder(
    column: $table.startMinOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durMin =>
      $composableBuilder(column: $table.durMin, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get fromDay =>
      $composableBuilder(column: $table.fromDay, builder: (column) => column);

  GeneratedColumn<int> get untilDay =>
      $composableBuilder(column: $table.untilDay, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$SeriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesTable,
          SeriesRow,
          $$SeriesTableFilterComposer,
          $$SeriesTableOrderingComposer,
          $$SeriesTableAnnotationComposer,
          $$SeriesTableCreateCompanionBuilder,
          $$SeriesTableUpdateCompanionBuilder,
          (SeriesRow, BaseReferences<_$AppDatabase, $SeriesTable, SeriesRow>),
          SeriesRow,
          PrefetchHooks Function()
        > {
  $$SeriesTableTableManager(_$AppDatabase db, $SeriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rule = const Value.absent(),
                Value<int> startMinOfDay = const Value.absent(),
                Value<int> durMin = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> fromDay = const Value.absent(),
                Value<int?> untilDay = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesCompanion(
                id: id,
                rule: rule,
                startMinOfDay: startMinOfDay,
                durMin: durMin,
                emoji: emoji,
                activityId: activityId,
                note: note,
                fromDay: fromDay,
                untilDay: untilDay,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rule,
                required int startMinOfDay,
                required int durMin,
                Value<String?> emoji = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int fromDay,
                Value<int?> untilDay = const Value.absent(),
                required String hlc,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesCompanion.insert(
                id: id,
                rule: rule,
                startMinOfDay: startMinOfDay,
                durMin: durMin,
                emoji: emoji,
                activityId: activityId,
                note: note,
                fromDay: fromDay,
                untilDay: untilDay,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SeriesTable, SeriesRow>(table),
                  BaseReferences<_$AppDatabase, $SeriesTable, SeriesRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesTable,
      SeriesRow,
      $$SeriesTableFilterComposer,
      $$SeriesTableOrderingComposer,
      $$SeriesTableAnnotationComposer,
      $$SeriesTableCreateCompanionBuilder,
      $$SeriesTableUpdateCompanionBuilder,
      (SeriesRow, BaseReferences<_$AppDatabase, $SeriesTable, SeriesRow>),
      SeriesRow,
      PrefetchHooks Function()
    >;
typedef $$PinsTableCreateCompanionBuilder = PinsCompanion Function({
  required String id,
  required int atMin,
  required String kind,
  Value<String?> label,
  Value<bool> draft,
  required String hlc,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$PinsTableUpdateCompanionBuilder = PinsCompanion Function({
  Value<String> id,
  Value<int> atMin,
  Value<String> kind,
  Value<String?> label,
  Value<bool> draft,
  Value<String> hlc,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$PinsTableFilterComposer extends Composer<_$AppDatabase, $PinsTable> {
  $$PinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMin => $composableBuilder(
    column: $table.atMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get draft => $composableBuilder(
    column: $table.draft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PinsTableOrderingComposer extends Composer<_$AppDatabase, $PinsTable> {
  $$PinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMin => $composableBuilder(
    column: $table.atMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get draft => $composableBuilder(
    column: $table.draft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PinsTable> {
  $$PinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get atMin =>
      $composableBuilder(column: $table.atMin, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get draft =>
      $composableBuilder(column: $table.draft, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$PinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PinsTable,
          PinRow,
          $$PinsTableFilterComposer,
          $$PinsTableOrderingComposer,
          $$PinsTableAnnotationComposer,
          $$PinsTableCreateCompanionBuilder,
          $$PinsTableUpdateCompanionBuilder,
          (PinRow, BaseReferences<_$AppDatabase, $PinsTable, PinRow>),
          PinRow,
          PrefetchHooks Function()
        > {
  $$PinsTableTableManager(_$AppDatabase db, $PinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> atMin = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<bool> draft = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PinsCompanion(
                id: id,
                atMin: atMin,
                kind: kind,
                label: label,
                draft: draft,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int atMin,
                required String kind,
                Value<String?> label = const Value.absent(),
                Value<bool> draft = const Value.absent(),
                required String hlc,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PinsCompanion.insert(
                id: id,
                atMin: atMin,
                kind: kind,
                label: label,
                draft: draft,
                hlc: hlc,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PinsTable, PinRow>(table),
                  BaseReferences<_$AppDatabase, $PinsTable, PinRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PinsTable,
      PinRow,
      $$PinsTableFilterComposer,
      $$PinsTableOrderingComposer,
      $$PinsTableAnnotationComposer,
      $$PinsTableCreateCompanionBuilder,
      $$PinsTableUpdateCompanionBuilder,
      (PinRow, BaseReferences<_$AppDatabase, $PinsTable, PinRow>),
      PinRow,
      PrefetchHooks Function()
    >;
typedef $$RemoteLinksTableCreateCompanionBuilder =
    RemoteLinksCompanion Function({
      required String blockId,
      required String provider,
      required String remoteId,
      Value<String?> etag,
      Value<int> rowid,
    });
typedef $$RemoteLinksTableUpdateCompanionBuilder =
    RemoteLinksCompanion Function({
      Value<String> blockId,
      Value<String> provider,
      Value<String> remoteId,
      Value<String?> etag,
      Value<int> rowid,
    });

class $$RemoteLinksTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteLinksTable> {
  $$RemoteLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteLinksTable> {
  $$RemoteLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteLinksTable> {
  $$RemoteLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$RemoteLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteLinksTable,
          RemoteLinkRow,
          $$RemoteLinksTableFilterComposer,
          $$RemoteLinksTableOrderingComposer,
          $$RemoteLinksTableAnnotationComposer,
          $$RemoteLinksTableCreateCompanionBuilder,
          $$RemoteLinksTableUpdateCompanionBuilder,
          (
            RemoteLinkRow,
            BaseReferences<_$AppDatabase, $RemoteLinksTable, RemoteLinkRow>,
          ),
          RemoteLinkRow,
          PrefetchHooks Function()
        > {
  $$RemoteLinksTableTableManager(_$AppDatabase db, $RemoteLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> blockId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteLinksCompanion(
                blockId: blockId,
                provider: provider,
                remoteId: remoteId,
                etag: etag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String blockId,
                required String provider,
                required String remoteId,
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteLinksCompanion.insert(
                blockId: blockId,
                provider: provider,
                remoteId: remoteId,
                etag: etag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemoteLinksTable, RemoteLinkRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RemoteLinksTable,
                    RemoteLinkRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteLinksTable,
      RemoteLinkRow,
      $$RemoteLinksTableFilterComposer,
      $$RemoteLinksTableOrderingComposer,
      $$RemoteLinksTableAnnotationComposer,
      $$RemoteLinksTableCreateCompanionBuilder,
      $$RemoteLinksTableUpdateCompanionBuilder,
      (
        RemoteLinkRow,
        BaseReferences<_$AppDatabase, $RemoteLinksTable, RemoteLinkRow>,
      ),
      RemoteLinkRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  required String hlc,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<String> hlc,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                hlc: hlc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required String hlc,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                hlc: hlc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$LocalKvTableCreateCompanionBuilder = LocalKvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$LocalKvTableUpdateCompanionBuilder = LocalKvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$LocalKvTableFilterComposer
    extends Composer<_$AppDatabase, $LocalKvTable> {
  $$LocalKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalKvTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalKvTable> {
  $$LocalKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalKvTable> {
  $$LocalKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalKvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalKvTable,
          LocalKvRow,
          $$LocalKvTableFilterComposer,
          $$LocalKvTableOrderingComposer,
          $$LocalKvTableAnnotationComposer,
          $$LocalKvTableCreateCompanionBuilder,
          $$LocalKvTableUpdateCompanionBuilder,
          (
            LocalKvRow,
            BaseReferences<_$AppDatabase, $LocalKvTable, LocalKvRow>,
          ),
          LocalKvRow,
          PrefetchHooks Function()
        > {
  $$LocalKvTableTableManager(_$AppDatabase db, $LocalKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalKvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => LocalKvCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalKvTable, LocalKvRow>(table),
                  BaseReferences<_$AppDatabase, $LocalKvTable, LocalKvRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalKvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalKvTable,
      LocalKvRow,
      $$LocalKvTableFilterComposer,
      $$LocalKvTableOrderingComposer,
      $$LocalKvTableAnnotationComposer,
      $$LocalKvTableCreateCompanionBuilder,
      $$LocalKvTableUpdateCompanionBuilder,
      (LocalKvRow, BaseReferences<_$AppDatabase, $LocalKvTable, LocalKvRow>),
      LocalKvRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db, _db.blocks);
  $$BlockEditsTableTableManager get blockEdits =>
      $$BlockEditsTableTableManager(_db, _db.blockEdits);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$SeriesTableTableManager get series =>
      $$SeriesTableTableManager(_db, _db.series);
  $$PinsTableTableManager get pins => $$PinsTableTableManager(_db, _db.pins);
  $$RemoteLinksTableTableManager get remoteLinks =>
      $$RemoteLinksTableTableManager(_db, _db.remoteLinks);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$LocalKvTableTableManager get localKv =>
      $$LocalKvTableTableManager(_db, _db.localKv);
}
