// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $OutboxEventsTable extends OutboxEvents
    with TableInfo<$OutboxEventsTable, OutboxEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectIdMeta = const VerificationMeta(
    'objectId',
  );
  @override
  late final GeneratedColumn<int> objectId = GeneratedColumn<int>(
    'object_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadTypeMeta = const VerificationMeta(
    'payloadType',
  );
  @override
  late final GeneratedColumn<String> payloadType = GeneratedColumn<String>(
    'payload_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputModeMeta = const VerificationMeta(
    'inputMode',
  );
  @override
  late final GeneratedColumn<String> inputMode = GeneratedColumn<String>(
    'input_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptMeta = const VerificationMeta(
    'transcript',
  );
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
    'transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triageJsonMeta = const VerificationMeta(
    'triageJson',
  );
  @override
  late final GeneratedColumn<String> triageJson = GeneratedColumn<String>(
    'triage_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voicePathMeta = const VerificationMeta(
    'voicePath',
  );
  @override
  late final GeneratedColumn<String> voicePath = GeneratedColumn<String>(
    'voice_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('created'),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMsMeta = const VerificationMeta(
    'expiresAtMs',
  );
  @override
  late final GeneratedColumn<int> expiresAtMs = GeneratedColumn<int>(
    'expires_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    objectId,
    siteId,
    roomId,
    payloadType,
    inputMode,
    rawText,
    transcript,
    triageJson,
    voicePath,
    priority,
    payload,
    state,
    createdAtMs,
    updatedAtMs,
    expiresAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('object_id')) {
      context.handle(
        _objectIdMeta,
        objectId.isAcceptableOrUnknown(data['object_id']!, _objectIdMeta),
      );
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('payload_type')) {
      context.handle(
        _payloadTypeMeta,
        payloadType.isAcceptableOrUnknown(
          data['payload_type']!,
          _payloadTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadTypeMeta);
    }
    if (data.containsKey('input_mode')) {
      context.handle(
        _inputModeMeta,
        inputMode.isAcceptableOrUnknown(data['input_mode']!, _inputModeMeta),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('transcript')) {
      context.handle(
        _transcriptMeta,
        transcript.isAcceptableOrUnknown(data['transcript']!, _transcriptMeta),
      );
    }
    if (data.containsKey('triage_json')) {
      context.handle(
        _triageJsonMeta,
        triageJson.isAcceptableOrUnknown(data['triage_json']!, _triageJsonMeta),
      );
    }
    if (data.containsKey('voice_path')) {
      context.handle(
        _voicePathMeta,
        voicePath.isAcceptableOrUnknown(data['voice_path']!, _voicePathMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('expires_at_ms')) {
      context.handle(
        _expiresAtMsMeta,
        expiresAtMs.isAcceptableOrUnknown(
          data['expires_at_ms']!,
          _expiresAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  OutboxEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      objectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}object_id'],
      ),
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      payloadType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_type'],
      )!,
      inputMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_mode'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
      transcript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript'],
      ),
      triageJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}triage_json'],
      ),
      voicePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_path'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
    );
  }

  @override
  $OutboxEventsTable createAlias(String alias) {
    return $OutboxEventsTable(attachedDatabase, alias);
  }
}

class OutboxEvent extends DataClass implements Insertable<OutboxEvent> {
  final String eventId;
  final int? objectId;
  final String siteId;
  final String roomId;
  final String payloadType;
  final String? inputMode;
  final String? rawText;
  final String? transcript;
  final String? triageJson;
  final String? voicePath;
  final String priority;
  final Uint8List? payload;
  final String state;
  final int createdAtMs;
  final int updatedAtMs;
  final int expiresAtMs;
  const OutboxEvent({
    required this.eventId,
    this.objectId,
    required this.siteId,
    required this.roomId,
    required this.payloadType,
    this.inputMode,
    this.rawText,
    this.transcript,
    this.triageJson,
    this.voicePath,
    required this.priority,
    this.payload,
    required this.state,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.expiresAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    if (!nullToAbsent || objectId != null) {
      map['object_id'] = Variable<int>(objectId);
    }
    map['site_id'] = Variable<String>(siteId);
    map['room_id'] = Variable<String>(roomId);
    map['payload_type'] = Variable<String>(payloadType);
    if (!nullToAbsent || inputMode != null) {
      map['input_mode'] = Variable<String>(inputMode);
    }
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    if (!nullToAbsent || triageJson != null) {
      map['triage_json'] = Variable<String>(triageJson);
    }
    if (!nullToAbsent || voicePath != null) {
      map['voice_path'] = Variable<String>(voicePath);
    }
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<Uint8List>(payload);
    }
    map['state'] = Variable<String>(state);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    return map;
  }

  OutboxEventsCompanion toCompanion(bool nullToAbsent) {
    return OutboxEventsCompanion(
      eventId: Value(eventId),
      objectId: objectId == null && nullToAbsent
          ? const Value.absent()
          : Value(objectId),
      siteId: Value(siteId),
      roomId: Value(roomId),
      payloadType: Value(payloadType),
      inputMode: inputMode == null && nullToAbsent
          ? const Value.absent()
          : Value(inputMode),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
      triageJson: triageJson == null && nullToAbsent
          ? const Value.absent()
          : Value(triageJson),
      voicePath: voicePath == null && nullToAbsent
          ? const Value.absent()
          : Value(voicePath),
      priority: Value(priority),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      state: Value(state),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      expiresAtMs: Value(expiresAtMs),
    );
  }

  factory OutboxEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      objectId: serializer.fromJson<int?>(json['objectId']),
      siteId: serializer.fromJson<String>(json['siteId']),
      roomId: serializer.fromJson<String>(json['roomId']),
      payloadType: serializer.fromJson<String>(json['payloadType']),
      inputMode: serializer.fromJson<String?>(json['inputMode']),
      rawText: serializer.fromJson<String?>(json['rawText']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      triageJson: serializer.fromJson<String?>(json['triageJson']),
      voicePath: serializer.fromJson<String?>(json['voicePath']),
      priority: serializer.fromJson<String>(json['priority']),
      payload: serializer.fromJson<Uint8List?>(json['payload']),
      state: serializer.fromJson<String>(json['state']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'objectId': serializer.toJson<int?>(objectId),
      'siteId': serializer.toJson<String>(siteId),
      'roomId': serializer.toJson<String>(roomId),
      'payloadType': serializer.toJson<String>(payloadType),
      'inputMode': serializer.toJson<String?>(inputMode),
      'rawText': serializer.toJson<String?>(rawText),
      'transcript': serializer.toJson<String?>(transcript),
      'triageJson': serializer.toJson<String?>(triageJson),
      'voicePath': serializer.toJson<String?>(voicePath),
      'priority': serializer.toJson<String>(priority),
      'payload': serializer.toJson<Uint8List?>(payload),
      'state': serializer.toJson<String>(state),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
    };
  }

  OutboxEvent copyWith({
    String? eventId,
    Value<int?> objectId = const Value.absent(),
    String? siteId,
    String? roomId,
    String? payloadType,
    Value<String?> inputMode = const Value.absent(),
    Value<String?> rawText = const Value.absent(),
    Value<String?> transcript = const Value.absent(),
    Value<String?> triageJson = const Value.absent(),
    Value<String?> voicePath = const Value.absent(),
    String? priority,
    Value<Uint8List?> payload = const Value.absent(),
    String? state,
    int? createdAtMs,
    int? updatedAtMs,
    int? expiresAtMs,
  }) => OutboxEvent(
    eventId: eventId ?? this.eventId,
    objectId: objectId.present ? objectId.value : this.objectId,
    siteId: siteId ?? this.siteId,
    roomId: roomId ?? this.roomId,
    payloadType: payloadType ?? this.payloadType,
    inputMode: inputMode.present ? inputMode.value : this.inputMode,
    rawText: rawText.present ? rawText.value : this.rawText,
    transcript: transcript.present ? transcript.value : this.transcript,
    triageJson: triageJson.present ? triageJson.value : this.triageJson,
    voicePath: voicePath.present ? voicePath.value : this.voicePath,
    priority: priority ?? this.priority,
    payload: payload.present ? payload.value : this.payload,
    state: state ?? this.state,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
  );
  OutboxEvent copyWithCompanion(OutboxEventsCompanion data) {
    return OutboxEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      objectId: data.objectId.present ? data.objectId.value : this.objectId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      payloadType: data.payloadType.present
          ? data.payloadType.value
          : this.payloadType,
      inputMode: data.inputMode.present ? data.inputMode.value : this.inputMode,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      transcript: data.transcript.present
          ? data.transcript.value
          : this.transcript,
      triageJson: data.triageJson.present
          ? data.triageJson.value
          : this.triageJson,
      voicePath: data.voicePath.present ? data.voicePath.value : this.voicePath,
      priority: data.priority.present ? data.priority.value : this.priority,
      payload: data.payload.present ? data.payload.value : this.payload,
      state: data.state.present ? data.state.value : this.state,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEvent(')
          ..write('eventId: $eventId, ')
          ..write('objectId: $objectId, ')
          ..write('siteId: $siteId, ')
          ..write('roomId: $roomId, ')
          ..write('payloadType: $payloadType, ')
          ..write('inputMode: $inputMode, ')
          ..write('rawText: $rawText, ')
          ..write('transcript: $transcript, ')
          ..write('triageJson: $triageJson, ')
          ..write('voicePath: $voicePath, ')
          ..write('priority: $priority, ')
          ..write('payload: $payload, ')
          ..write('state: $state, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('expiresAtMs: $expiresAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    objectId,
    siteId,
    roomId,
    payloadType,
    inputMode,
    rawText,
    transcript,
    triageJson,
    voicePath,
    priority,
    $driftBlobEquality.hash(payload),
    state,
    createdAtMs,
    updatedAtMs,
    expiresAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEvent &&
          other.eventId == this.eventId &&
          other.objectId == this.objectId &&
          other.siteId == this.siteId &&
          other.roomId == this.roomId &&
          other.payloadType == this.payloadType &&
          other.inputMode == this.inputMode &&
          other.rawText == this.rawText &&
          other.transcript == this.transcript &&
          other.triageJson == this.triageJson &&
          other.voicePath == this.voicePath &&
          other.priority == this.priority &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          other.state == this.state &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.expiresAtMs == this.expiresAtMs);
}

class OutboxEventsCompanion extends UpdateCompanion<OutboxEvent> {
  final Value<String> eventId;
  final Value<int?> objectId;
  final Value<String> siteId;
  final Value<String> roomId;
  final Value<String> payloadType;
  final Value<String?> inputMode;
  final Value<String?> rawText;
  final Value<String?> transcript;
  final Value<String?> triageJson;
  final Value<String?> voicePath;
  final Value<String> priority;
  final Value<Uint8List?> payload;
  final Value<String> state;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> expiresAtMs;
  final Value<int> rowid;
  const OutboxEventsCompanion({
    this.eventId = const Value.absent(),
    this.objectId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.payloadType = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.rawText = const Value.absent(),
    this.transcript = const Value.absent(),
    this.triageJson = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.priority = const Value.absent(),
    this.payload = const Value.absent(),
    this.state = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEventsCompanion.insert({
    required String eventId,
    this.objectId = const Value.absent(),
    required String siteId,
    required String roomId,
    required String payloadType,
    this.inputMode = const Value.absent(),
    this.rawText = const Value.absent(),
    this.transcript = const Value.absent(),
    this.triageJson = const Value.absent(),
    this.voicePath = const Value.absent(),
    required String priority,
    this.payload = const Value.absent(),
    this.state = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    required int expiresAtMs,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       siteId = Value(siteId),
       roomId = Value(roomId),
       payloadType = Value(payloadType),
       priority = Value(priority),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       expiresAtMs = Value(expiresAtMs);
  static Insertable<OutboxEvent> custom({
    Expression<String>? eventId,
    Expression<int>? objectId,
    Expression<String>? siteId,
    Expression<String>? roomId,
    Expression<String>? payloadType,
    Expression<String>? inputMode,
    Expression<String>? rawText,
    Expression<String>? transcript,
    Expression<String>? triageJson,
    Expression<String>? voicePath,
    Expression<String>? priority,
    Expression<Uint8List>? payload,
    Expression<String>? state,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? expiresAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (objectId != null) 'object_id': objectId,
      if (siteId != null) 'site_id': siteId,
      if (roomId != null) 'room_id': roomId,
      if (payloadType != null) 'payload_type': payloadType,
      if (inputMode != null) 'input_mode': inputMode,
      if (rawText != null) 'raw_text': rawText,
      if (transcript != null) 'transcript': transcript,
      if (triageJson != null) 'triage_json': triageJson,
      if (voicePath != null) 'voice_path': voicePath,
      if (priority != null) 'priority': priority,
      if (payload != null) 'payload': payload,
      if (state != null) 'state': state,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEventsCompanion copyWith({
    Value<String>? eventId,
    Value<int?>? objectId,
    Value<String>? siteId,
    Value<String>? roomId,
    Value<String>? payloadType,
    Value<String?>? inputMode,
    Value<String?>? rawText,
    Value<String?>? transcript,
    Value<String?>? triageJson,
    Value<String?>? voicePath,
    Value<String>? priority,
    Value<Uint8List?>? payload,
    Value<String>? state,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? expiresAtMs,
    Value<int>? rowid,
  }) {
    return OutboxEventsCompanion(
      eventId: eventId ?? this.eventId,
      objectId: objectId ?? this.objectId,
      siteId: siteId ?? this.siteId,
      roomId: roomId ?? this.roomId,
      payloadType: payloadType ?? this.payloadType,
      inputMode: inputMode ?? this.inputMode,
      rawText: rawText ?? this.rawText,
      transcript: transcript ?? this.transcript,
      triageJson: triageJson ?? this.triageJson,
      voicePath: voicePath ?? this.voicePath,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
      state: state ?? this.state,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (objectId.present) {
      map['object_id'] = Variable<int>(objectId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (payloadType.present) {
      map['payload_type'] = Variable<String>(payloadType.value);
    }
    if (inputMode.present) {
      map['input_mode'] = Variable<String>(inputMode.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (triageJson.present) {
      map['triage_json'] = Variable<String>(triageJson.value);
    }
    if (voicePath.present) {
      map['voice_path'] = Variable<String>(voicePath.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('objectId: $objectId, ')
          ..write('siteId: $siteId, ')
          ..write('roomId: $roomId, ')
          ..write('payloadType: $payloadType, ')
          ..write('inputMode: $inputMode, ')
          ..write('rawText: $rawText, ')
          ..write('transcript: $transcript, ')
          ..write('triageJson: $triageJson, ')
          ..write('voicePath: $voicePath, ')
          ..write('priority: $priority, ')
          ..write('payload: $payload, ')
          ..write('state: $state, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InboxEventsTable extends InboxEvents
    with TableInfo<$InboxEventsTable, InboxEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InboxEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _objectIdMeta = const VerificationMeta(
    'objectId',
  );
  @override
  late final GeneratedColumn<int> objectId = GeneratedColumn<int>(
    'object_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadTypeMeta = const VerificationMeta(
    'payloadType',
  );
  @override
  late final GeneratedColumn<String> payloadType = GeneratedColumn<String>(
    'payload_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
    'peer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMsMeta = const VerificationMeta(
    'receivedAtMs',
  );
  @override
  late final GeneratedColumn<int> receivedAtMs = GeneratedColumn<int>(
    'received_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    objectId,
    eventId,
    siteId,
    roomId,
    payloadType,
    payload,
    peerId,
    receivedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbox_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<InboxEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('object_id')) {
      context.handle(
        _objectIdMeta,
        objectId.isAcceptableOrUnknown(data['object_id']!, _objectIdMeta),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('payload_type')) {
      context.handle(
        _payloadTypeMeta,
        payloadType.isAcceptableOrUnknown(
          data['payload_type']!,
          _payloadTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('received_at_ms')) {
      context.handle(
        _receivedAtMsMeta,
        receivedAtMs.isAcceptableOrUnknown(
          data['received_at_ms']!,
          _receivedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {objectId};
  @override
  InboxEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InboxEvent(
      objectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}object_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      payloadType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
      peerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_id'],
      )!,
      receivedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at_ms'],
      )!,
    );
  }

  @override
  $InboxEventsTable createAlias(String alias) {
    return $InboxEventsTable(attachedDatabase, alias);
  }
}

class InboxEvent extends DataClass implements Insertable<InboxEvent> {
  final int objectId;
  final String eventId;
  final String siteId;
  final String roomId;
  final String payloadType;
  final Uint8List payload;
  final String peerId;
  final int receivedAtMs;
  const InboxEvent({
    required this.objectId,
    required this.eventId,
    required this.siteId,
    required this.roomId,
    required this.payloadType,
    required this.payload,
    required this.peerId,
    required this.receivedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['object_id'] = Variable<int>(objectId);
    map['event_id'] = Variable<String>(eventId);
    map['site_id'] = Variable<String>(siteId);
    map['room_id'] = Variable<String>(roomId);
    map['payload_type'] = Variable<String>(payloadType);
    map['payload'] = Variable<Uint8List>(payload);
    map['peer_id'] = Variable<String>(peerId);
    map['received_at_ms'] = Variable<int>(receivedAtMs);
    return map;
  }

  InboxEventsCompanion toCompanion(bool nullToAbsent) {
    return InboxEventsCompanion(
      objectId: Value(objectId),
      eventId: Value(eventId),
      siteId: Value(siteId),
      roomId: Value(roomId),
      payloadType: Value(payloadType),
      payload: Value(payload),
      peerId: Value(peerId),
      receivedAtMs: Value(receivedAtMs),
    );
  }

  factory InboxEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InboxEvent(
      objectId: serializer.fromJson<int>(json['objectId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      siteId: serializer.fromJson<String>(json['siteId']),
      roomId: serializer.fromJson<String>(json['roomId']),
      payloadType: serializer.fromJson<String>(json['payloadType']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
      peerId: serializer.fromJson<String>(json['peerId']),
      receivedAtMs: serializer.fromJson<int>(json['receivedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'objectId': serializer.toJson<int>(objectId),
      'eventId': serializer.toJson<String>(eventId),
      'siteId': serializer.toJson<String>(siteId),
      'roomId': serializer.toJson<String>(roomId),
      'payloadType': serializer.toJson<String>(payloadType),
      'payload': serializer.toJson<Uint8List>(payload),
      'peerId': serializer.toJson<String>(peerId),
      'receivedAtMs': serializer.toJson<int>(receivedAtMs),
    };
  }

  InboxEvent copyWith({
    int? objectId,
    String? eventId,
    String? siteId,
    String? roomId,
    String? payloadType,
    Uint8List? payload,
    String? peerId,
    int? receivedAtMs,
  }) => InboxEvent(
    objectId: objectId ?? this.objectId,
    eventId: eventId ?? this.eventId,
    siteId: siteId ?? this.siteId,
    roomId: roomId ?? this.roomId,
    payloadType: payloadType ?? this.payloadType,
    payload: payload ?? this.payload,
    peerId: peerId ?? this.peerId,
    receivedAtMs: receivedAtMs ?? this.receivedAtMs,
  );
  InboxEvent copyWithCompanion(InboxEventsCompanion data) {
    return InboxEvent(
      objectId: data.objectId.present ? data.objectId.value : this.objectId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      payloadType: data.payloadType.present
          ? data.payloadType.value
          : this.payloadType,
      payload: data.payload.present ? data.payload.value : this.payload,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      receivedAtMs: data.receivedAtMs.present
          ? data.receivedAtMs.value
          : this.receivedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InboxEvent(')
          ..write('objectId: $objectId, ')
          ..write('eventId: $eventId, ')
          ..write('siteId: $siteId, ')
          ..write('roomId: $roomId, ')
          ..write('payloadType: $payloadType, ')
          ..write('payload: $payload, ')
          ..write('peerId: $peerId, ')
          ..write('receivedAtMs: $receivedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    objectId,
    eventId,
    siteId,
    roomId,
    payloadType,
    $driftBlobEquality.hash(payload),
    peerId,
    receivedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InboxEvent &&
          other.objectId == this.objectId &&
          other.eventId == this.eventId &&
          other.siteId == this.siteId &&
          other.roomId == this.roomId &&
          other.payloadType == this.payloadType &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          other.peerId == this.peerId &&
          other.receivedAtMs == this.receivedAtMs);
}

class InboxEventsCompanion extends UpdateCompanion<InboxEvent> {
  final Value<int> objectId;
  final Value<String> eventId;
  final Value<String> siteId;
  final Value<String> roomId;
  final Value<String> payloadType;
  final Value<Uint8List> payload;
  final Value<String> peerId;
  final Value<int> receivedAtMs;
  const InboxEventsCompanion({
    this.objectId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.payloadType = const Value.absent(),
    this.payload = const Value.absent(),
    this.peerId = const Value.absent(),
    this.receivedAtMs = const Value.absent(),
  });
  InboxEventsCompanion.insert({
    this.objectId = const Value.absent(),
    required String eventId,
    required String siteId,
    required String roomId,
    required String payloadType,
    required Uint8List payload,
    required String peerId,
    required int receivedAtMs,
  }) : eventId = Value(eventId),
       siteId = Value(siteId),
       roomId = Value(roomId),
       payloadType = Value(payloadType),
       payload = Value(payload),
       peerId = Value(peerId),
       receivedAtMs = Value(receivedAtMs);
  static Insertable<InboxEvent> custom({
    Expression<int>? objectId,
    Expression<String>? eventId,
    Expression<String>? siteId,
    Expression<String>? roomId,
    Expression<String>? payloadType,
    Expression<Uint8List>? payload,
    Expression<String>? peerId,
    Expression<int>? receivedAtMs,
  }) {
    return RawValuesInsertable({
      if (objectId != null) 'object_id': objectId,
      if (eventId != null) 'event_id': eventId,
      if (siteId != null) 'site_id': siteId,
      if (roomId != null) 'room_id': roomId,
      if (payloadType != null) 'payload_type': payloadType,
      if (payload != null) 'payload': payload,
      if (peerId != null) 'peer_id': peerId,
      if (receivedAtMs != null) 'received_at_ms': receivedAtMs,
    });
  }

  InboxEventsCompanion copyWith({
    Value<int>? objectId,
    Value<String>? eventId,
    Value<String>? siteId,
    Value<String>? roomId,
    Value<String>? payloadType,
    Value<Uint8List>? payload,
    Value<String>? peerId,
    Value<int>? receivedAtMs,
  }) {
    return InboxEventsCompanion(
      objectId: objectId ?? this.objectId,
      eventId: eventId ?? this.eventId,
      siteId: siteId ?? this.siteId,
      roomId: roomId ?? this.roomId,
      payloadType: payloadType ?? this.payloadType,
      payload: payload ?? this.payload,
      peerId: peerId ?? this.peerId,
      receivedAtMs: receivedAtMs ?? this.receivedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (objectId.present) {
      map['object_id'] = Variable<int>(objectId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (payloadType.present) {
      map['payload_type'] = Variable<String>(payloadType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (receivedAtMs.present) {
      map['received_at_ms'] = Variable<int>(receivedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InboxEventsCompanion(')
          ..write('objectId: $objectId, ')
          ..write('eventId: $eventId, ')
          ..write('siteId: $siteId, ')
          ..write('roomId: $roomId, ')
          ..write('payloadType: $payloadType, ')
          ..write('payload: $payload, ')
          ..write('peerId: $peerId, ')
          ..write('receivedAtMs: $receivedAtMs')
          ..write(')'))
        .toString();
  }
}

class $SiteManifestsTable extends SiteManifests
    with TableInfo<$SiteManifestsTable, SiteManifest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SiteManifestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteNameMeta = const VerificationMeta(
    'siteName',
  );
  @override
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
    'site_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meshCodeMeta = const VerificationMeta(
    'meshCode',
  );
  @override
  late final GeneratedColumn<String> meshCode = GeneratedColumn<String>(
    'mesh_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gatewayHintMeta = const VerificationMeta(
    'gatewayHint',
  );
  @override
  late final GeneratedColumn<String> gatewayHint = GeneratedColumn<String>(
    'gateway_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorityKeyIdMeta = const VerificationMeta(
    'authorityKeyId',
  );
  @override
  late final GeneratedColumn<String> authorityKeyId = GeneratedColumn<String>(
    'authority_key_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorityPublicKeyJwkMeta =
      const VerificationMeta('authorityPublicKeyJwk');
  @override
  late final GeneratedColumn<String> authorityPublicKeyJwk =
      GeneratedColumn<String>(
        'authority_public_key_jwk',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _validFromMsMeta = const VerificationMeta(
    'validFromMs',
  );
  @override
  late final GeneratedColumn<int> validFromMs = GeneratedColumn<int>(
    'valid_from_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validUntilMsMeta = const VerificationMeta(
    'validUntilMs',
  );
  @override
  late final GeneratedColumn<int> validUntilMs = GeneratedColumn<int>(
    'valid_until_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomsJsonMeta = const VerificationMeta(
    'roomsJson',
  );
  @override
  late final GeneratedColumn<String> roomsJson = GeneratedColumn<String>(
    'rooms_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedAtMsMeta = const VerificationMeta(
    'joinedAtMs',
  );
  @override
  late final GeneratedColumn<int> joinedAtMs = GeneratedColumn<int>(
    'joined_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    siteId,
    siteName,
    meshCode,
    gatewayHint,
    authorityKeyId,
    authorityPublicKeyJwk,
    validFromMs,
    validUntilMs,
    roomsJson,
    joinedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'site_manifests';
  @override
  VerificationContext validateIntegrity(
    Insertable<SiteManifest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('site_name')) {
      context.handle(
        _siteNameMeta,
        siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta),
      );
    } else if (isInserting) {
      context.missing(_siteNameMeta);
    }
    if (data.containsKey('mesh_code')) {
      context.handle(
        _meshCodeMeta,
        meshCode.isAcceptableOrUnknown(data['mesh_code']!, _meshCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_meshCodeMeta);
    }
    if (data.containsKey('gateway_hint')) {
      context.handle(
        _gatewayHintMeta,
        gatewayHint.isAcceptableOrUnknown(
          data['gateway_hint']!,
          _gatewayHintMeta,
        ),
      );
    }
    if (data.containsKey('authority_key_id')) {
      context.handle(
        _authorityKeyIdMeta,
        authorityKeyId.isAcceptableOrUnknown(
          data['authority_key_id']!,
          _authorityKeyIdMeta,
        ),
      );
    }
    if (data.containsKey('authority_public_key_jwk')) {
      context.handle(
        _authorityPublicKeyJwkMeta,
        authorityPublicKeyJwk.isAcceptableOrUnknown(
          data['authority_public_key_jwk']!,
          _authorityPublicKeyJwkMeta,
        ),
      );
    }
    if (data.containsKey('valid_from_ms')) {
      context.handle(
        _validFromMsMeta,
        validFromMs.isAcceptableOrUnknown(
          data['valid_from_ms']!,
          _validFromMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_validFromMsMeta);
    }
    if (data.containsKey('valid_until_ms')) {
      context.handle(
        _validUntilMsMeta,
        validUntilMs.isAcceptableOrUnknown(
          data['valid_until_ms']!,
          _validUntilMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_validUntilMsMeta);
    }
    if (data.containsKey('rooms_json')) {
      context.handle(
        _roomsJsonMeta,
        roomsJson.isAcceptableOrUnknown(data['rooms_json']!, _roomsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_roomsJsonMeta);
    }
    if (data.containsKey('joined_at_ms')) {
      context.handle(
        _joinedAtMsMeta,
        joinedAtMs.isAcceptableOrUnknown(
          data['joined_at_ms']!,
          _joinedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {siteId};
  @override
  SiteManifest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SiteManifest(
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      siteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_name'],
      )!,
      meshCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mesh_code'],
      )!,
      gatewayHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gateway_hint'],
      ),
      authorityKeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authority_key_id'],
      ),
      authorityPublicKeyJwk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authority_public_key_jwk'],
      ),
      validFromMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valid_from_ms'],
      )!,
      validUntilMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valid_until_ms'],
      )!,
      roomsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rooms_json'],
      )!,
      joinedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}joined_at_ms'],
      )!,
    );
  }

  @override
  $SiteManifestsTable createAlias(String alias) {
    return $SiteManifestsTable(attachedDatabase, alias);
  }
}

class SiteManifest extends DataClass implements Insertable<SiteManifest> {
  final String siteId;
  final String siteName;
  final String meshCode;
  final String? gatewayHint;
  final String? authorityKeyId;
  final String? authorityPublicKeyJwk;
  final int validFromMs;
  final int validUntilMs;
  final String roomsJson;
  final int joinedAtMs;
  const SiteManifest({
    required this.siteId,
    required this.siteName,
    required this.meshCode,
    this.gatewayHint,
    this.authorityKeyId,
    this.authorityPublicKeyJwk,
    required this.validFromMs,
    required this.validUntilMs,
    required this.roomsJson,
    required this.joinedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['site_id'] = Variable<String>(siteId);
    map['site_name'] = Variable<String>(siteName);
    map['mesh_code'] = Variable<String>(meshCode);
    if (!nullToAbsent || gatewayHint != null) {
      map['gateway_hint'] = Variable<String>(gatewayHint);
    }
    if (!nullToAbsent || authorityKeyId != null) {
      map['authority_key_id'] = Variable<String>(authorityKeyId);
    }
    if (!nullToAbsent || authorityPublicKeyJwk != null) {
      map['authority_public_key_jwk'] = Variable<String>(authorityPublicKeyJwk);
    }
    map['valid_from_ms'] = Variable<int>(validFromMs);
    map['valid_until_ms'] = Variable<int>(validUntilMs);
    map['rooms_json'] = Variable<String>(roomsJson);
    map['joined_at_ms'] = Variable<int>(joinedAtMs);
    return map;
  }

  SiteManifestsCompanion toCompanion(bool nullToAbsent) {
    return SiteManifestsCompanion(
      siteId: Value(siteId),
      siteName: Value(siteName),
      meshCode: Value(meshCode),
      gatewayHint: gatewayHint == null && nullToAbsent
          ? const Value.absent()
          : Value(gatewayHint),
      authorityKeyId: authorityKeyId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorityKeyId),
      authorityPublicKeyJwk: authorityPublicKeyJwk == null && nullToAbsent
          ? const Value.absent()
          : Value(authorityPublicKeyJwk),
      validFromMs: Value(validFromMs),
      validUntilMs: Value(validUntilMs),
      roomsJson: Value(roomsJson),
      joinedAtMs: Value(joinedAtMs),
    );
  }

  factory SiteManifest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SiteManifest(
      siteId: serializer.fromJson<String>(json['siteId']),
      siteName: serializer.fromJson<String>(json['siteName']),
      meshCode: serializer.fromJson<String>(json['meshCode']),
      gatewayHint: serializer.fromJson<String?>(json['gatewayHint']),
      authorityKeyId: serializer.fromJson<String?>(json['authorityKeyId']),
      authorityPublicKeyJwk: serializer.fromJson<String?>(
        json['authorityPublicKeyJwk'],
      ),
      validFromMs: serializer.fromJson<int>(json['validFromMs']),
      validUntilMs: serializer.fromJson<int>(json['validUntilMs']),
      roomsJson: serializer.fromJson<String>(json['roomsJson']),
      joinedAtMs: serializer.fromJson<int>(json['joinedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'siteId': serializer.toJson<String>(siteId),
      'siteName': serializer.toJson<String>(siteName),
      'meshCode': serializer.toJson<String>(meshCode),
      'gatewayHint': serializer.toJson<String?>(gatewayHint),
      'authorityKeyId': serializer.toJson<String?>(authorityKeyId),
      'authorityPublicKeyJwk': serializer.toJson<String?>(
        authorityPublicKeyJwk,
      ),
      'validFromMs': serializer.toJson<int>(validFromMs),
      'validUntilMs': serializer.toJson<int>(validUntilMs),
      'roomsJson': serializer.toJson<String>(roomsJson),
      'joinedAtMs': serializer.toJson<int>(joinedAtMs),
    };
  }

  SiteManifest copyWith({
    String? siteId,
    String? siteName,
    String? meshCode,
    Value<String?> gatewayHint = const Value.absent(),
    Value<String?> authorityKeyId = const Value.absent(),
    Value<String?> authorityPublicKeyJwk = const Value.absent(),
    int? validFromMs,
    int? validUntilMs,
    String? roomsJson,
    int? joinedAtMs,
  }) => SiteManifest(
    siteId: siteId ?? this.siteId,
    siteName: siteName ?? this.siteName,
    meshCode: meshCode ?? this.meshCode,
    gatewayHint: gatewayHint.present ? gatewayHint.value : this.gatewayHint,
    authorityKeyId: authorityKeyId.present
        ? authorityKeyId.value
        : this.authorityKeyId,
    authorityPublicKeyJwk: authorityPublicKeyJwk.present
        ? authorityPublicKeyJwk.value
        : this.authorityPublicKeyJwk,
    validFromMs: validFromMs ?? this.validFromMs,
    validUntilMs: validUntilMs ?? this.validUntilMs,
    roomsJson: roomsJson ?? this.roomsJson,
    joinedAtMs: joinedAtMs ?? this.joinedAtMs,
  );
  SiteManifest copyWithCompanion(SiteManifestsCompanion data) {
    return SiteManifest(
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      siteName: data.siteName.present ? data.siteName.value : this.siteName,
      meshCode: data.meshCode.present ? data.meshCode.value : this.meshCode,
      gatewayHint: data.gatewayHint.present
          ? data.gatewayHint.value
          : this.gatewayHint,
      authorityKeyId: data.authorityKeyId.present
          ? data.authorityKeyId.value
          : this.authorityKeyId,
      authorityPublicKeyJwk: data.authorityPublicKeyJwk.present
          ? data.authorityPublicKeyJwk.value
          : this.authorityPublicKeyJwk,
      validFromMs: data.validFromMs.present
          ? data.validFromMs.value
          : this.validFromMs,
      validUntilMs: data.validUntilMs.present
          ? data.validUntilMs.value
          : this.validUntilMs,
      roomsJson: data.roomsJson.present ? data.roomsJson.value : this.roomsJson,
      joinedAtMs: data.joinedAtMs.present
          ? data.joinedAtMs.value
          : this.joinedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SiteManifest(')
          ..write('siteId: $siteId, ')
          ..write('siteName: $siteName, ')
          ..write('meshCode: $meshCode, ')
          ..write('gatewayHint: $gatewayHint, ')
          ..write('authorityKeyId: $authorityKeyId, ')
          ..write('authorityPublicKeyJwk: $authorityPublicKeyJwk, ')
          ..write('validFromMs: $validFromMs, ')
          ..write('validUntilMs: $validUntilMs, ')
          ..write('roomsJson: $roomsJson, ')
          ..write('joinedAtMs: $joinedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    siteId,
    siteName,
    meshCode,
    gatewayHint,
    authorityKeyId,
    authorityPublicKeyJwk,
    validFromMs,
    validUntilMs,
    roomsJson,
    joinedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SiteManifest &&
          other.siteId == this.siteId &&
          other.siteName == this.siteName &&
          other.meshCode == this.meshCode &&
          other.gatewayHint == this.gatewayHint &&
          other.authorityKeyId == this.authorityKeyId &&
          other.authorityPublicKeyJwk == this.authorityPublicKeyJwk &&
          other.validFromMs == this.validFromMs &&
          other.validUntilMs == this.validUntilMs &&
          other.roomsJson == this.roomsJson &&
          other.joinedAtMs == this.joinedAtMs);
}

class SiteManifestsCompanion extends UpdateCompanion<SiteManifest> {
  final Value<String> siteId;
  final Value<String> siteName;
  final Value<String> meshCode;
  final Value<String?> gatewayHint;
  final Value<String?> authorityKeyId;
  final Value<String?> authorityPublicKeyJwk;
  final Value<int> validFromMs;
  final Value<int> validUntilMs;
  final Value<String> roomsJson;
  final Value<int> joinedAtMs;
  final Value<int> rowid;
  const SiteManifestsCompanion({
    this.siteId = const Value.absent(),
    this.siteName = const Value.absent(),
    this.meshCode = const Value.absent(),
    this.gatewayHint = const Value.absent(),
    this.authorityKeyId = const Value.absent(),
    this.authorityPublicKeyJwk = const Value.absent(),
    this.validFromMs = const Value.absent(),
    this.validUntilMs = const Value.absent(),
    this.roomsJson = const Value.absent(),
    this.joinedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SiteManifestsCompanion.insert({
    required String siteId,
    required String siteName,
    required String meshCode,
    this.gatewayHint = const Value.absent(),
    this.authorityKeyId = const Value.absent(),
    this.authorityPublicKeyJwk = const Value.absent(),
    required int validFromMs,
    required int validUntilMs,
    required String roomsJson,
    required int joinedAtMs,
    this.rowid = const Value.absent(),
  }) : siteId = Value(siteId),
       siteName = Value(siteName),
       meshCode = Value(meshCode),
       validFromMs = Value(validFromMs),
       validUntilMs = Value(validUntilMs),
       roomsJson = Value(roomsJson),
       joinedAtMs = Value(joinedAtMs);
  static Insertable<SiteManifest> custom({
    Expression<String>? siteId,
    Expression<String>? siteName,
    Expression<String>? meshCode,
    Expression<String>? gatewayHint,
    Expression<String>? authorityKeyId,
    Expression<String>? authorityPublicKeyJwk,
    Expression<int>? validFromMs,
    Expression<int>? validUntilMs,
    Expression<String>? roomsJson,
    Expression<int>? joinedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (siteId != null) 'site_id': siteId,
      if (siteName != null) 'site_name': siteName,
      if (meshCode != null) 'mesh_code': meshCode,
      if (gatewayHint != null) 'gateway_hint': gatewayHint,
      if (authorityKeyId != null) 'authority_key_id': authorityKeyId,
      if (authorityPublicKeyJwk != null)
        'authority_public_key_jwk': authorityPublicKeyJwk,
      if (validFromMs != null) 'valid_from_ms': validFromMs,
      if (validUntilMs != null) 'valid_until_ms': validUntilMs,
      if (roomsJson != null) 'rooms_json': roomsJson,
      if (joinedAtMs != null) 'joined_at_ms': joinedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SiteManifestsCompanion copyWith({
    Value<String>? siteId,
    Value<String>? siteName,
    Value<String>? meshCode,
    Value<String?>? gatewayHint,
    Value<String?>? authorityKeyId,
    Value<String?>? authorityPublicKeyJwk,
    Value<int>? validFromMs,
    Value<int>? validUntilMs,
    Value<String>? roomsJson,
    Value<int>? joinedAtMs,
    Value<int>? rowid,
  }) {
    return SiteManifestsCompanion(
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      meshCode: meshCode ?? this.meshCode,
      gatewayHint: gatewayHint ?? this.gatewayHint,
      authorityKeyId: authorityKeyId ?? this.authorityKeyId,
      authorityPublicKeyJwk:
          authorityPublicKeyJwk ?? this.authorityPublicKeyJwk,
      validFromMs: validFromMs ?? this.validFromMs,
      validUntilMs: validUntilMs ?? this.validUntilMs,
      roomsJson: roomsJson ?? this.roomsJson,
      joinedAtMs: joinedAtMs ?? this.joinedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (meshCode.present) {
      map['mesh_code'] = Variable<String>(meshCode.value);
    }
    if (gatewayHint.present) {
      map['gateway_hint'] = Variable<String>(gatewayHint.value);
    }
    if (authorityKeyId.present) {
      map['authority_key_id'] = Variable<String>(authorityKeyId.value);
    }
    if (authorityPublicKeyJwk.present) {
      map['authority_public_key_jwk'] = Variable<String>(
        authorityPublicKeyJwk.value,
      );
    }
    if (validFromMs.present) {
      map['valid_from_ms'] = Variable<int>(validFromMs.value);
    }
    if (validUntilMs.present) {
      map['valid_until_ms'] = Variable<int>(validUntilMs.value);
    }
    if (roomsJson.present) {
      map['rooms_json'] = Variable<String>(roomsJson.value);
    }
    if (joinedAtMs.present) {
      map['joined_at_ms'] = Variable<int>(joinedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SiteManifestsCompanion(')
          ..write('siteId: $siteId, ')
          ..write('siteName: $siteName, ')
          ..write('meshCode: $meshCode, ')
          ..write('gatewayHint: $gatewayHint, ')
          ..write('authorityKeyId: $authorityKeyId, ')
          ..write('authorityPublicKeyJwk: $authorityPublicKeyJwk, ')
          ..write('validFromMs: $validFromMs, ')
          ..write('validUntilMs: $validUntilMs, ')
          ..write('roomsJson: $roomsJson, ')
          ..write('joinedAtMs: $joinedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReverseRoutesTable extends ReverseRoutes
    with TableInfo<$ReverseRoutesTable, ReverseRoute> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReverseRoutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originEphemeralIdMeta = const VerificationMeta(
    'originEphemeralId',
  );
  @override
  late final GeneratedColumn<int> originEphemeralId = GeneratedColumn<int>(
    'origin_ephemeral_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousPeerEphemeralIdMeta =
      const VerificationMeta('previousPeerEphemeralId');
  @override
  late final GeneratedColumn<int> previousPeerEphemeralId =
      GeneratedColumn<int>(
        'previous_peer_ephemeral_id',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _previousPeerHintMeta = const VerificationMeta(
    'previousPeerHint',
  );
  @override
  late final GeneratedColumn<String> previousPeerHint = GeneratedColumn<String>(
    'previous_peer_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _learnedAtMsMeta = const VerificationMeta(
    'learnedAtMs',
  );
  @override
  late final GeneratedColumn<int> learnedAtMs = GeneratedColumn<int>(
    'learned_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learnedAtElapsedMsMeta =
      const VerificationMeta('learnedAtElapsedMs');
  @override
  late final GeneratedColumn<int> learnedAtElapsedMs = GeneratedColumn<int>(
    'learned_at_elapsed_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMsMeta = const VerificationMeta(
    'expiresAtMs',
  );
  @override
  late final GeneratedColumn<int> expiresAtMs = GeneratedColumn<int>(
    'expires_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedForwardHopCountMeta =
      const VerificationMeta('observedForwardHopCount');
  @override
  late final GeneratedColumn<int> observedForwardHopCount =
      GeneratedColumn<int>(
        'observed_forward_hop_count',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastReachableAtMsMeta = const VerificationMeta(
    'lastReachableAtMs',
  );
  @override
  late final GeneratedColumn<int> lastReachableAtMs = GeneratedColumn<int>(
    'last_reachable_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consecutiveFailuresMeta =
      const VerificationMeta('consecutiveFailures');
  @override
  late final GeneratedColumn<int> consecutiveFailures = GeneratedColumn<int>(
    'consecutive_failures',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _qualityScoreMeta = const VerificationMeta(
    'qualityScore',
  );
  @override
  late final GeneratedColumn<double> qualityScore = GeneratedColumn<double>(
    'quality_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    siteId,
    eventId,
    originEphemeralId,
    previousPeerEphemeralId,
    previousPeerHint,
    learnedAtMs,
    learnedAtElapsedMs,
    expiresAtMs,
    observedForwardHopCount,
    lastReachableAtMs,
    consecutiveFailures,
    qualityScore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reverse_routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReverseRoute> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('origin_ephemeral_id')) {
      context.handle(
        _originEphemeralIdMeta,
        originEphemeralId.isAcceptableOrUnknown(
          data['origin_ephemeral_id']!,
          _originEphemeralIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originEphemeralIdMeta);
    }
    if (data.containsKey('previous_peer_ephemeral_id')) {
      context.handle(
        _previousPeerEphemeralIdMeta,
        previousPeerEphemeralId.isAcceptableOrUnknown(
          data['previous_peer_ephemeral_id']!,
          _previousPeerEphemeralIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previousPeerEphemeralIdMeta);
    }
    if (data.containsKey('previous_peer_hint')) {
      context.handle(
        _previousPeerHintMeta,
        previousPeerHint.isAcceptableOrUnknown(
          data['previous_peer_hint']!,
          _previousPeerHintMeta,
        ),
      );
    }
    if (data.containsKey('learned_at_ms')) {
      context.handle(
        _learnedAtMsMeta,
        learnedAtMs.isAcceptableOrUnknown(
          data['learned_at_ms']!,
          _learnedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learnedAtMsMeta);
    }
    if (data.containsKey('learned_at_elapsed_ms')) {
      context.handle(
        _learnedAtElapsedMsMeta,
        learnedAtElapsedMs.isAcceptableOrUnknown(
          data['learned_at_elapsed_ms']!,
          _learnedAtElapsedMsMeta,
        ),
      );
    }
    if (data.containsKey('expires_at_ms')) {
      context.handle(
        _expiresAtMsMeta,
        expiresAtMs.isAcceptableOrUnknown(
          data['expires_at_ms']!,
          _expiresAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMsMeta);
    }
    if (data.containsKey('observed_forward_hop_count')) {
      context.handle(
        _observedForwardHopCountMeta,
        observedForwardHopCount.isAcceptableOrUnknown(
          data['observed_forward_hop_count']!,
          _observedForwardHopCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_observedForwardHopCountMeta);
    }
    if (data.containsKey('last_reachable_at_ms')) {
      context.handle(
        _lastReachableAtMsMeta,
        lastReachableAtMs.isAcceptableOrUnknown(
          data['last_reachable_at_ms']!,
          _lastReachableAtMsMeta,
        ),
      );
    }
    if (data.containsKey('consecutive_failures')) {
      context.handle(
        _consecutiveFailuresMeta,
        consecutiveFailures.isAcceptableOrUnknown(
          data['consecutive_failures']!,
          _consecutiveFailuresMeta,
        ),
      );
    }
    if (data.containsKey('quality_score')) {
      context.handle(
        _qualityScoreMeta,
        qualityScore.isAcceptableOrUnknown(
          data['quality_score']!,
          _qualityScoreMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    siteId,
    eventId,
    originEphemeralId,
    previousPeerEphemeralId,
  };
  @override
  ReverseRoute map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReverseRoute(
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      originEphemeralId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_ephemeral_id'],
      )!,
      previousPeerEphemeralId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}previous_peer_ephemeral_id'],
      )!,
      previousPeerHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_peer_hint'],
      ),
      learnedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learned_at_ms'],
      )!,
      learnedAtElapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learned_at_elapsed_ms'],
      ),
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
      observedForwardHopCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}observed_forward_hop_count'],
      )!,
      lastReachableAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reachable_at_ms'],
      ),
      consecutiveFailures: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_failures'],
      )!,
      qualityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quality_score'],
      ),
    );
  }

  @override
  $ReverseRoutesTable createAlias(String alias) {
    return $ReverseRoutesTable(attachedDatabase, alias);
  }
}

class ReverseRoute extends DataClass implements Insertable<ReverseRoute> {
  final String siteId;
  final String eventId;
  final int originEphemeralId;
  final int previousPeerEphemeralId;
  final String? previousPeerHint;
  final int learnedAtMs;
  final int? learnedAtElapsedMs;
  final int expiresAtMs;
  final int observedForwardHopCount;
  final int? lastReachableAtMs;
  final int consecutiveFailures;
  final double? qualityScore;
  const ReverseRoute({
    required this.siteId,
    required this.eventId,
    required this.originEphemeralId,
    required this.previousPeerEphemeralId,
    this.previousPeerHint,
    required this.learnedAtMs,
    this.learnedAtElapsedMs,
    required this.expiresAtMs,
    required this.observedForwardHopCount,
    this.lastReachableAtMs,
    required this.consecutiveFailures,
    this.qualityScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['site_id'] = Variable<String>(siteId);
    map['event_id'] = Variable<String>(eventId);
    map['origin_ephemeral_id'] = Variable<int>(originEphemeralId);
    map['previous_peer_ephemeral_id'] = Variable<int>(previousPeerEphemeralId);
    if (!nullToAbsent || previousPeerHint != null) {
      map['previous_peer_hint'] = Variable<String>(previousPeerHint);
    }
    map['learned_at_ms'] = Variable<int>(learnedAtMs);
    if (!nullToAbsent || learnedAtElapsedMs != null) {
      map['learned_at_elapsed_ms'] = Variable<int>(learnedAtElapsedMs);
    }
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    map['observed_forward_hop_count'] = Variable<int>(observedForwardHopCount);
    if (!nullToAbsent || lastReachableAtMs != null) {
      map['last_reachable_at_ms'] = Variable<int>(lastReachableAtMs);
    }
    map['consecutive_failures'] = Variable<int>(consecutiveFailures);
    if (!nullToAbsent || qualityScore != null) {
      map['quality_score'] = Variable<double>(qualityScore);
    }
    return map;
  }

  ReverseRoutesCompanion toCompanion(bool nullToAbsent) {
    return ReverseRoutesCompanion(
      siteId: Value(siteId),
      eventId: Value(eventId),
      originEphemeralId: Value(originEphemeralId),
      previousPeerEphemeralId: Value(previousPeerEphemeralId),
      previousPeerHint: previousPeerHint == null && nullToAbsent
          ? const Value.absent()
          : Value(previousPeerHint),
      learnedAtMs: Value(learnedAtMs),
      learnedAtElapsedMs: learnedAtElapsedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(learnedAtElapsedMs),
      expiresAtMs: Value(expiresAtMs),
      observedForwardHopCount: Value(observedForwardHopCount),
      lastReachableAtMs: lastReachableAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReachableAtMs),
      consecutiveFailures: Value(consecutiveFailures),
      qualityScore: qualityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(qualityScore),
    );
  }

  factory ReverseRoute.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReverseRoute(
      siteId: serializer.fromJson<String>(json['siteId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      originEphemeralId: serializer.fromJson<int>(json['originEphemeralId']),
      previousPeerEphemeralId: serializer.fromJson<int>(
        json['previousPeerEphemeralId'],
      ),
      previousPeerHint: serializer.fromJson<String?>(json['previousPeerHint']),
      learnedAtMs: serializer.fromJson<int>(json['learnedAtMs']),
      learnedAtElapsedMs: serializer.fromJson<int?>(json['learnedAtElapsedMs']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
      observedForwardHopCount: serializer.fromJson<int>(
        json['observedForwardHopCount'],
      ),
      lastReachableAtMs: serializer.fromJson<int?>(json['lastReachableAtMs']),
      consecutiveFailures: serializer.fromJson<int>(
        json['consecutiveFailures'],
      ),
      qualityScore: serializer.fromJson<double?>(json['qualityScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'siteId': serializer.toJson<String>(siteId),
      'eventId': serializer.toJson<String>(eventId),
      'originEphemeralId': serializer.toJson<int>(originEphemeralId),
      'previousPeerEphemeralId': serializer.toJson<int>(
        previousPeerEphemeralId,
      ),
      'previousPeerHint': serializer.toJson<String?>(previousPeerHint),
      'learnedAtMs': serializer.toJson<int>(learnedAtMs),
      'learnedAtElapsedMs': serializer.toJson<int?>(learnedAtElapsedMs),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
      'observedForwardHopCount': serializer.toJson<int>(
        observedForwardHopCount,
      ),
      'lastReachableAtMs': serializer.toJson<int?>(lastReachableAtMs),
      'consecutiveFailures': serializer.toJson<int>(consecutiveFailures),
      'qualityScore': serializer.toJson<double?>(qualityScore),
    };
  }

  ReverseRoute copyWith({
    String? siteId,
    String? eventId,
    int? originEphemeralId,
    int? previousPeerEphemeralId,
    Value<String?> previousPeerHint = const Value.absent(),
    int? learnedAtMs,
    Value<int?> learnedAtElapsedMs = const Value.absent(),
    int? expiresAtMs,
    int? observedForwardHopCount,
    Value<int?> lastReachableAtMs = const Value.absent(),
    int? consecutiveFailures,
    Value<double?> qualityScore = const Value.absent(),
  }) => ReverseRoute(
    siteId: siteId ?? this.siteId,
    eventId: eventId ?? this.eventId,
    originEphemeralId: originEphemeralId ?? this.originEphemeralId,
    previousPeerEphemeralId:
        previousPeerEphemeralId ?? this.previousPeerEphemeralId,
    previousPeerHint: previousPeerHint.present
        ? previousPeerHint.value
        : this.previousPeerHint,
    learnedAtMs: learnedAtMs ?? this.learnedAtMs,
    learnedAtElapsedMs: learnedAtElapsedMs.present
        ? learnedAtElapsedMs.value
        : this.learnedAtElapsedMs,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
    observedForwardHopCount:
        observedForwardHopCount ?? this.observedForwardHopCount,
    lastReachableAtMs: lastReachableAtMs.present
        ? lastReachableAtMs.value
        : this.lastReachableAtMs,
    consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    qualityScore: qualityScore.present ? qualityScore.value : this.qualityScore,
  );
  ReverseRoute copyWithCompanion(ReverseRoutesCompanion data) {
    return ReverseRoute(
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      originEphemeralId: data.originEphemeralId.present
          ? data.originEphemeralId.value
          : this.originEphemeralId,
      previousPeerEphemeralId: data.previousPeerEphemeralId.present
          ? data.previousPeerEphemeralId.value
          : this.previousPeerEphemeralId,
      previousPeerHint: data.previousPeerHint.present
          ? data.previousPeerHint.value
          : this.previousPeerHint,
      learnedAtMs: data.learnedAtMs.present
          ? data.learnedAtMs.value
          : this.learnedAtMs,
      learnedAtElapsedMs: data.learnedAtElapsedMs.present
          ? data.learnedAtElapsedMs.value
          : this.learnedAtElapsedMs,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
      observedForwardHopCount: data.observedForwardHopCount.present
          ? data.observedForwardHopCount.value
          : this.observedForwardHopCount,
      lastReachableAtMs: data.lastReachableAtMs.present
          ? data.lastReachableAtMs.value
          : this.lastReachableAtMs,
      consecutiveFailures: data.consecutiveFailures.present
          ? data.consecutiveFailures.value
          : this.consecutiveFailures,
      qualityScore: data.qualityScore.present
          ? data.qualityScore.value
          : this.qualityScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReverseRoute(')
          ..write('siteId: $siteId, ')
          ..write('eventId: $eventId, ')
          ..write('originEphemeralId: $originEphemeralId, ')
          ..write('previousPeerEphemeralId: $previousPeerEphemeralId, ')
          ..write('previousPeerHint: $previousPeerHint, ')
          ..write('learnedAtMs: $learnedAtMs, ')
          ..write('learnedAtElapsedMs: $learnedAtElapsedMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('observedForwardHopCount: $observedForwardHopCount, ')
          ..write('lastReachableAtMs: $lastReachableAtMs, ')
          ..write('consecutiveFailures: $consecutiveFailures, ')
          ..write('qualityScore: $qualityScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    siteId,
    eventId,
    originEphemeralId,
    previousPeerEphemeralId,
    previousPeerHint,
    learnedAtMs,
    learnedAtElapsedMs,
    expiresAtMs,
    observedForwardHopCount,
    lastReachableAtMs,
    consecutiveFailures,
    qualityScore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReverseRoute &&
          other.siteId == this.siteId &&
          other.eventId == this.eventId &&
          other.originEphemeralId == this.originEphemeralId &&
          other.previousPeerEphemeralId == this.previousPeerEphemeralId &&
          other.previousPeerHint == this.previousPeerHint &&
          other.learnedAtMs == this.learnedAtMs &&
          other.learnedAtElapsedMs == this.learnedAtElapsedMs &&
          other.expiresAtMs == this.expiresAtMs &&
          other.observedForwardHopCount == this.observedForwardHopCount &&
          other.lastReachableAtMs == this.lastReachableAtMs &&
          other.consecutiveFailures == this.consecutiveFailures &&
          other.qualityScore == this.qualityScore);
}

class ReverseRoutesCompanion extends UpdateCompanion<ReverseRoute> {
  final Value<String> siteId;
  final Value<String> eventId;
  final Value<int> originEphemeralId;
  final Value<int> previousPeerEphemeralId;
  final Value<String?> previousPeerHint;
  final Value<int> learnedAtMs;
  final Value<int?> learnedAtElapsedMs;
  final Value<int> expiresAtMs;
  final Value<int> observedForwardHopCount;
  final Value<int?> lastReachableAtMs;
  final Value<int> consecutiveFailures;
  final Value<double?> qualityScore;
  final Value<int> rowid;
  const ReverseRoutesCompanion({
    this.siteId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.originEphemeralId = const Value.absent(),
    this.previousPeerEphemeralId = const Value.absent(),
    this.previousPeerHint = const Value.absent(),
    this.learnedAtMs = const Value.absent(),
    this.learnedAtElapsedMs = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.observedForwardHopCount = const Value.absent(),
    this.lastReachableAtMs = const Value.absent(),
    this.consecutiveFailures = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReverseRoutesCompanion.insert({
    required String siteId,
    required String eventId,
    required int originEphemeralId,
    required int previousPeerEphemeralId,
    this.previousPeerHint = const Value.absent(),
    required int learnedAtMs,
    this.learnedAtElapsedMs = const Value.absent(),
    required int expiresAtMs,
    required int observedForwardHopCount,
    this.lastReachableAtMs = const Value.absent(),
    this.consecutiveFailures = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : siteId = Value(siteId),
       eventId = Value(eventId),
       originEphemeralId = Value(originEphemeralId),
       previousPeerEphemeralId = Value(previousPeerEphemeralId),
       learnedAtMs = Value(learnedAtMs),
       expiresAtMs = Value(expiresAtMs),
       observedForwardHopCount = Value(observedForwardHopCount);
  static Insertable<ReverseRoute> custom({
    Expression<String>? siteId,
    Expression<String>? eventId,
    Expression<int>? originEphemeralId,
    Expression<int>? previousPeerEphemeralId,
    Expression<String>? previousPeerHint,
    Expression<int>? learnedAtMs,
    Expression<int>? learnedAtElapsedMs,
    Expression<int>? expiresAtMs,
    Expression<int>? observedForwardHopCount,
    Expression<int>? lastReachableAtMs,
    Expression<int>? consecutiveFailures,
    Expression<double>? qualityScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (siteId != null) 'site_id': siteId,
      if (eventId != null) 'event_id': eventId,
      if (originEphemeralId != null) 'origin_ephemeral_id': originEphemeralId,
      if (previousPeerEphemeralId != null)
        'previous_peer_ephemeral_id': previousPeerEphemeralId,
      if (previousPeerHint != null) 'previous_peer_hint': previousPeerHint,
      if (learnedAtMs != null) 'learned_at_ms': learnedAtMs,
      if (learnedAtElapsedMs != null)
        'learned_at_elapsed_ms': learnedAtElapsedMs,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (observedForwardHopCount != null)
        'observed_forward_hop_count': observedForwardHopCount,
      if (lastReachableAtMs != null) 'last_reachable_at_ms': lastReachableAtMs,
      if (consecutiveFailures != null)
        'consecutive_failures': consecutiveFailures,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReverseRoutesCompanion copyWith({
    Value<String>? siteId,
    Value<String>? eventId,
    Value<int>? originEphemeralId,
    Value<int>? previousPeerEphemeralId,
    Value<String?>? previousPeerHint,
    Value<int>? learnedAtMs,
    Value<int?>? learnedAtElapsedMs,
    Value<int>? expiresAtMs,
    Value<int>? observedForwardHopCount,
    Value<int?>? lastReachableAtMs,
    Value<int>? consecutiveFailures,
    Value<double?>? qualityScore,
    Value<int>? rowid,
  }) {
    return ReverseRoutesCompanion(
      siteId: siteId ?? this.siteId,
      eventId: eventId ?? this.eventId,
      originEphemeralId: originEphemeralId ?? this.originEphemeralId,
      previousPeerEphemeralId:
          previousPeerEphemeralId ?? this.previousPeerEphemeralId,
      previousPeerHint: previousPeerHint ?? this.previousPeerHint,
      learnedAtMs: learnedAtMs ?? this.learnedAtMs,
      learnedAtElapsedMs: learnedAtElapsedMs ?? this.learnedAtElapsedMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      observedForwardHopCount:
          observedForwardHopCount ?? this.observedForwardHopCount,
      lastReachableAtMs: lastReachableAtMs ?? this.lastReachableAtMs,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      qualityScore: qualityScore ?? this.qualityScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (originEphemeralId.present) {
      map['origin_ephemeral_id'] = Variable<int>(originEphemeralId.value);
    }
    if (previousPeerEphemeralId.present) {
      map['previous_peer_ephemeral_id'] = Variable<int>(
        previousPeerEphemeralId.value,
      );
    }
    if (previousPeerHint.present) {
      map['previous_peer_hint'] = Variable<String>(previousPeerHint.value);
    }
    if (learnedAtMs.present) {
      map['learned_at_ms'] = Variable<int>(learnedAtMs.value);
    }
    if (learnedAtElapsedMs.present) {
      map['learned_at_elapsed_ms'] = Variable<int>(learnedAtElapsedMs.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (observedForwardHopCount.present) {
      map['observed_forward_hop_count'] = Variable<int>(
        observedForwardHopCount.value,
      );
    }
    if (lastReachableAtMs.present) {
      map['last_reachable_at_ms'] = Variable<int>(lastReachableAtMs.value);
    }
    if (consecutiveFailures.present) {
      map['consecutive_failures'] = Variable<int>(consecutiveFailures.value);
    }
    if (qualityScore.present) {
      map['quality_score'] = Variable<double>(qualityScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReverseRoutesCompanion(')
          ..write('siteId: $siteId, ')
          ..write('eventId: $eventId, ')
          ..write('originEphemeralId: $originEphemeralId, ')
          ..write('previousPeerEphemeralId: $previousPeerEphemeralId, ')
          ..write('previousPeerHint: $previousPeerHint, ')
          ..write('learnedAtMs: $learnedAtMs, ')
          ..write('learnedAtElapsedMs: $learnedAtElapsedMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('observedForwardHopCount: $observedForwardHopCount, ')
          ..write('lastReachableAtMs: $lastReachableAtMs, ')
          ..write('consecutiveFailures: $consecutiveFailures, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuthorityResponseOutboxTable extends AuthorityResponseOutbox
    with TableInfo<$AuthorityResponseOutboxTable, AuthorityResponseOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthorityResponseOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _responseIdMeta = const VerificationMeta(
    'responseId',
  );
  @override
  late final GeneratedColumn<String> responseId = GeneratedColumn<String>(
    'response_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToEventIdMeta = const VerificationMeta(
    'replyToEventId',
  );
  @override
  late final GeneratedColumn<String> replyToEventId = GeneratedColumn<String>(
    'reply_to_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationEphemeralIdMeta =
      const VerificationMeta('destinationEphemeralId');
  @override
  late final GeneratedColumn<int> destinationEphemeralId = GeneratedColumn<int>(
    'destination_ephemeral_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signedPayloadMeta = const VerificationMeta(
    'signedPayload',
  );
  @override
  late final GeneratedColumn<Uint8List> signedPayload =
      GeneratedColumn<Uint8List>(
        'signed_payload',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _meshObjectIdMeta = const VerificationMeta(
    'meshObjectId',
  );
  @override
  late final GeneratedColumn<int> meshObjectId = GeneratedColumn<int>(
    'mesh_object_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hopCountMeta = const VerificationMeta(
    'hopCount',
  );
  @override
  late final GeneratedColumn<int> hopCount = GeneratedColumn<int>(
    'hop_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeModeMeta = const VerificationMeta(
    'routeMode',
  );
  @override
  late final GeneratedColumn<String> routeMode = GeneratedColumn<String>(
    'route_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptedPeerIdsJsonMeta =
      const VerificationMeta('attemptedPeerIdsJson');
  @override
  late final GeneratedColumn<String> attemptedPeerIdsJson =
      GeneratedColumn<String>(
        'attempted_peer_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _nextAttemptAtMsMeta = const VerificationMeta(
    'nextAttemptAtMs',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAtMs = GeneratedColumn<int>(
    'next_attempt_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _traceIdMeta = const VerificationMeta(
    'traceId',
  );
  @override
  late final GeneratedColumn<Uint8List> traceId = GeneratedColumn<Uint8List>(
    'trace_id',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMsMeta = const VerificationMeta(
    'expiresAtMs',
  );
  @override
  late final GeneratedColumn<int> expiresAtMs = GeneratedColumn<int>(
    'expires_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    responseId,
    replyToEventId,
    destinationEphemeralId,
    signedPayload,
    meshObjectId,
    hopCount,
    state,
    routeMode,
    attempts,
    attemptedPeerIdsJson,
    nextAttemptAtMs,
    lastError,
    traceId,
    createdAtMs,
    expiresAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'authority_response_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuthorityResponseOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('response_id')) {
      context.handle(
        _responseIdMeta,
        responseId.isAcceptableOrUnknown(data['response_id']!, _responseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_responseIdMeta);
    }
    if (data.containsKey('reply_to_event_id')) {
      context.handle(
        _replyToEventIdMeta,
        replyToEventId.isAcceptableOrUnknown(
          data['reply_to_event_id']!,
          _replyToEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_replyToEventIdMeta);
    }
    if (data.containsKey('destination_ephemeral_id')) {
      context.handle(
        _destinationEphemeralIdMeta,
        destinationEphemeralId.isAcceptableOrUnknown(
          data['destination_ephemeral_id']!,
          _destinationEphemeralIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationEphemeralIdMeta);
    }
    if (data.containsKey('signed_payload')) {
      context.handle(
        _signedPayloadMeta,
        signedPayload.isAcceptableOrUnknown(
          data['signed_payload']!,
          _signedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signedPayloadMeta);
    }
    if (data.containsKey('mesh_object_id')) {
      context.handle(
        _meshObjectIdMeta,
        meshObjectId.isAcceptableOrUnknown(
          data['mesh_object_id']!,
          _meshObjectIdMeta,
        ),
      );
    }
    if (data.containsKey('hop_count')) {
      context.handle(
        _hopCountMeta,
        hopCount.isAcceptableOrUnknown(data['hop_count']!, _hopCountMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('route_mode')) {
      context.handle(
        _routeModeMeta,
        routeMode.isAcceptableOrUnknown(data['route_mode']!, _routeModeMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('attempted_peer_ids_json')) {
      context.handle(
        _attemptedPeerIdsJsonMeta,
        attemptedPeerIdsJson.isAcceptableOrUnknown(
          data['attempted_peer_ids_json']!,
          _attemptedPeerIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at_ms')) {
      context.handle(
        _nextAttemptAtMsMeta,
        nextAttemptAtMs.isAcceptableOrUnknown(
          data['next_attempt_at_ms']!,
          _nextAttemptAtMsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('trace_id')) {
      context.handle(
        _traceIdMeta,
        traceId.isAcceptableOrUnknown(data['trace_id']!, _traceIdMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('expires_at_ms')) {
      context.handle(
        _expiresAtMsMeta,
        expiresAtMs.isAcceptableOrUnknown(
          data['expires_at_ms']!,
          _expiresAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {responseId};
  @override
  AuthorityResponseOutboxData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuthorityResponseOutboxData(
      responseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_id'],
      )!,
      replyToEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_event_id'],
      )!,
      destinationEphemeralId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}destination_ephemeral_id'],
      )!,
      signedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}signed_payload'],
      )!,
      meshObjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mesh_object_id'],
      ),
      hopCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hop_count'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      routeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_mode'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      attemptedPeerIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempted_peer_ids_json'],
      )!,
      nextAttemptAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at_ms'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      traceId: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}trace_id'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
    );
  }

  @override
  $AuthorityResponseOutboxTable createAlias(String alias) {
    return $AuthorityResponseOutboxTable(attachedDatabase, alias);
  }
}

class AuthorityResponseOutboxData extends DataClass
    implements Insertable<AuthorityResponseOutboxData> {
  final String responseId;
  final String replyToEventId;
  final int destinationEphemeralId;
  final Uint8List signedPayload;
  final int? meshObjectId;
  final int hopCount;
  final String state;
  final String? routeMode;
  final int attempts;
  final String attemptedPeerIdsJson;
  final int? nextAttemptAtMs;
  final String? lastError;
  final Uint8List? traceId;
  final int createdAtMs;
  final int expiresAtMs;
  const AuthorityResponseOutboxData({
    required this.responseId,
    required this.replyToEventId,
    required this.destinationEphemeralId,
    required this.signedPayload,
    this.meshObjectId,
    required this.hopCount,
    required this.state,
    this.routeMode,
    required this.attempts,
    required this.attemptedPeerIdsJson,
    this.nextAttemptAtMs,
    this.lastError,
    this.traceId,
    required this.createdAtMs,
    required this.expiresAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['response_id'] = Variable<String>(responseId);
    map['reply_to_event_id'] = Variable<String>(replyToEventId);
    map['destination_ephemeral_id'] = Variable<int>(destinationEphemeralId);
    map['signed_payload'] = Variable<Uint8List>(signedPayload);
    if (!nullToAbsent || meshObjectId != null) {
      map['mesh_object_id'] = Variable<int>(meshObjectId);
    }
    map['hop_count'] = Variable<int>(hopCount);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || routeMode != null) {
      map['route_mode'] = Variable<String>(routeMode);
    }
    map['attempts'] = Variable<int>(attempts);
    map['attempted_peer_ids_json'] = Variable<String>(attemptedPeerIdsJson);
    if (!nullToAbsent || nextAttemptAtMs != null) {
      map['next_attempt_at_ms'] = Variable<int>(nextAttemptAtMs);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || traceId != null) {
      map['trace_id'] = Variable<Uint8List>(traceId);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    return map;
  }

  AuthorityResponseOutboxCompanion toCompanion(bool nullToAbsent) {
    return AuthorityResponseOutboxCompanion(
      responseId: Value(responseId),
      replyToEventId: Value(replyToEventId),
      destinationEphemeralId: Value(destinationEphemeralId),
      signedPayload: Value(signedPayload),
      meshObjectId: meshObjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(meshObjectId),
      hopCount: Value(hopCount),
      state: Value(state),
      routeMode: routeMode == null && nullToAbsent
          ? const Value.absent()
          : Value(routeMode),
      attempts: Value(attempts),
      attemptedPeerIdsJson: Value(attemptedPeerIdsJson),
      nextAttemptAtMs: nextAttemptAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAtMs),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      traceId: traceId == null && nullToAbsent
          ? const Value.absent()
          : Value(traceId),
      createdAtMs: Value(createdAtMs),
      expiresAtMs: Value(expiresAtMs),
    );
  }

  factory AuthorityResponseOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuthorityResponseOutboxData(
      responseId: serializer.fromJson<String>(json['responseId']),
      replyToEventId: serializer.fromJson<String>(json['replyToEventId']),
      destinationEphemeralId: serializer.fromJson<int>(
        json['destinationEphemeralId'],
      ),
      signedPayload: serializer.fromJson<Uint8List>(json['signedPayload']),
      meshObjectId: serializer.fromJson<int?>(json['meshObjectId']),
      hopCount: serializer.fromJson<int>(json['hopCount']),
      state: serializer.fromJson<String>(json['state']),
      routeMode: serializer.fromJson<String?>(json['routeMode']),
      attempts: serializer.fromJson<int>(json['attempts']),
      attemptedPeerIdsJson: serializer.fromJson<String>(
        json['attemptedPeerIdsJson'],
      ),
      nextAttemptAtMs: serializer.fromJson<int?>(json['nextAttemptAtMs']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      traceId: serializer.fromJson<Uint8List?>(json['traceId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'responseId': serializer.toJson<String>(responseId),
      'replyToEventId': serializer.toJson<String>(replyToEventId),
      'destinationEphemeralId': serializer.toJson<int>(destinationEphemeralId),
      'signedPayload': serializer.toJson<Uint8List>(signedPayload),
      'meshObjectId': serializer.toJson<int?>(meshObjectId),
      'hopCount': serializer.toJson<int>(hopCount),
      'state': serializer.toJson<String>(state),
      'routeMode': serializer.toJson<String?>(routeMode),
      'attempts': serializer.toJson<int>(attempts),
      'attemptedPeerIdsJson': serializer.toJson<String>(attemptedPeerIdsJson),
      'nextAttemptAtMs': serializer.toJson<int?>(nextAttemptAtMs),
      'lastError': serializer.toJson<String?>(lastError),
      'traceId': serializer.toJson<Uint8List?>(traceId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
    };
  }

  AuthorityResponseOutboxData copyWith({
    String? responseId,
    String? replyToEventId,
    int? destinationEphemeralId,
    Uint8List? signedPayload,
    Value<int?> meshObjectId = const Value.absent(),
    int? hopCount,
    String? state,
    Value<String?> routeMode = const Value.absent(),
    int? attempts,
    String? attemptedPeerIdsJson,
    Value<int?> nextAttemptAtMs = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<Uint8List?> traceId = const Value.absent(),
    int? createdAtMs,
    int? expiresAtMs,
  }) => AuthorityResponseOutboxData(
    responseId: responseId ?? this.responseId,
    replyToEventId: replyToEventId ?? this.replyToEventId,
    destinationEphemeralId:
        destinationEphemeralId ?? this.destinationEphemeralId,
    signedPayload: signedPayload ?? this.signedPayload,
    meshObjectId: meshObjectId.present ? meshObjectId.value : this.meshObjectId,
    hopCount: hopCount ?? this.hopCount,
    state: state ?? this.state,
    routeMode: routeMode.present ? routeMode.value : this.routeMode,
    attempts: attempts ?? this.attempts,
    attemptedPeerIdsJson: attemptedPeerIdsJson ?? this.attemptedPeerIdsJson,
    nextAttemptAtMs: nextAttemptAtMs.present
        ? nextAttemptAtMs.value
        : this.nextAttemptAtMs,
    lastError: lastError.present ? lastError.value : this.lastError,
    traceId: traceId.present ? traceId.value : this.traceId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
  );
  AuthorityResponseOutboxData copyWithCompanion(
    AuthorityResponseOutboxCompanion data,
  ) {
    return AuthorityResponseOutboxData(
      responseId: data.responseId.present
          ? data.responseId.value
          : this.responseId,
      replyToEventId: data.replyToEventId.present
          ? data.replyToEventId.value
          : this.replyToEventId,
      destinationEphemeralId: data.destinationEphemeralId.present
          ? data.destinationEphemeralId.value
          : this.destinationEphemeralId,
      signedPayload: data.signedPayload.present
          ? data.signedPayload.value
          : this.signedPayload,
      meshObjectId: data.meshObjectId.present
          ? data.meshObjectId.value
          : this.meshObjectId,
      hopCount: data.hopCount.present ? data.hopCount.value : this.hopCount,
      state: data.state.present ? data.state.value : this.state,
      routeMode: data.routeMode.present ? data.routeMode.value : this.routeMode,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      attemptedPeerIdsJson: data.attemptedPeerIdsJson.present
          ? data.attemptedPeerIdsJson.value
          : this.attemptedPeerIdsJson,
      nextAttemptAtMs: data.nextAttemptAtMs.present
          ? data.nextAttemptAtMs.value
          : this.nextAttemptAtMs,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      traceId: data.traceId.present ? data.traceId.value : this.traceId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuthorityResponseOutboxData(')
          ..write('responseId: $responseId, ')
          ..write('replyToEventId: $replyToEventId, ')
          ..write('destinationEphemeralId: $destinationEphemeralId, ')
          ..write('signedPayload: $signedPayload, ')
          ..write('meshObjectId: $meshObjectId, ')
          ..write('hopCount: $hopCount, ')
          ..write('state: $state, ')
          ..write('routeMode: $routeMode, ')
          ..write('attempts: $attempts, ')
          ..write('attemptedPeerIdsJson: $attemptedPeerIdsJson, ')
          ..write('nextAttemptAtMs: $nextAttemptAtMs, ')
          ..write('lastError: $lastError, ')
          ..write('traceId: $traceId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    responseId,
    replyToEventId,
    destinationEphemeralId,
    $driftBlobEquality.hash(signedPayload),
    meshObjectId,
    hopCount,
    state,
    routeMode,
    attempts,
    attemptedPeerIdsJson,
    nextAttemptAtMs,
    lastError,
    $driftBlobEquality.hash(traceId),
    createdAtMs,
    expiresAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthorityResponseOutboxData &&
          other.responseId == this.responseId &&
          other.replyToEventId == this.replyToEventId &&
          other.destinationEphemeralId == this.destinationEphemeralId &&
          $driftBlobEquality.equals(other.signedPayload, this.signedPayload) &&
          other.meshObjectId == this.meshObjectId &&
          other.hopCount == this.hopCount &&
          other.state == this.state &&
          other.routeMode == this.routeMode &&
          other.attempts == this.attempts &&
          other.attemptedPeerIdsJson == this.attemptedPeerIdsJson &&
          other.nextAttemptAtMs == this.nextAttemptAtMs &&
          other.lastError == this.lastError &&
          $driftBlobEquality.equals(other.traceId, this.traceId) &&
          other.createdAtMs == this.createdAtMs &&
          other.expiresAtMs == this.expiresAtMs);
}

class AuthorityResponseOutboxCompanion
    extends UpdateCompanion<AuthorityResponseOutboxData> {
  final Value<String> responseId;
  final Value<String> replyToEventId;
  final Value<int> destinationEphemeralId;
  final Value<Uint8List> signedPayload;
  final Value<int?> meshObjectId;
  final Value<int> hopCount;
  final Value<String> state;
  final Value<String?> routeMode;
  final Value<int> attempts;
  final Value<String> attemptedPeerIdsJson;
  final Value<int?> nextAttemptAtMs;
  final Value<String?> lastError;
  final Value<Uint8List?> traceId;
  final Value<int> createdAtMs;
  final Value<int> expiresAtMs;
  final Value<int> rowid;
  const AuthorityResponseOutboxCompanion({
    this.responseId = const Value.absent(),
    this.replyToEventId = const Value.absent(),
    this.destinationEphemeralId = const Value.absent(),
    this.signedPayload = const Value.absent(),
    this.meshObjectId = const Value.absent(),
    this.hopCount = const Value.absent(),
    this.state = const Value.absent(),
    this.routeMode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.attemptedPeerIdsJson = const Value.absent(),
    this.nextAttemptAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
    this.traceId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuthorityResponseOutboxCompanion.insert({
    required String responseId,
    required String replyToEventId,
    required int destinationEphemeralId,
    required Uint8List signedPayload,
    this.meshObjectId = const Value.absent(),
    this.hopCount = const Value.absent(),
    required String state,
    this.routeMode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.attemptedPeerIdsJson = const Value.absent(),
    this.nextAttemptAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
    this.traceId = const Value.absent(),
    required int createdAtMs,
    required int expiresAtMs,
    this.rowid = const Value.absent(),
  }) : responseId = Value(responseId),
       replyToEventId = Value(replyToEventId),
       destinationEphemeralId = Value(destinationEphemeralId),
       signedPayload = Value(signedPayload),
       state = Value(state),
       createdAtMs = Value(createdAtMs),
       expiresAtMs = Value(expiresAtMs);
  static Insertable<AuthorityResponseOutboxData> custom({
    Expression<String>? responseId,
    Expression<String>? replyToEventId,
    Expression<int>? destinationEphemeralId,
    Expression<Uint8List>? signedPayload,
    Expression<int>? meshObjectId,
    Expression<int>? hopCount,
    Expression<String>? state,
    Expression<String>? routeMode,
    Expression<int>? attempts,
    Expression<String>? attemptedPeerIdsJson,
    Expression<int>? nextAttemptAtMs,
    Expression<String>? lastError,
    Expression<Uint8List>? traceId,
    Expression<int>? createdAtMs,
    Expression<int>? expiresAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (responseId != null) 'response_id': responseId,
      if (replyToEventId != null) 'reply_to_event_id': replyToEventId,
      if (destinationEphemeralId != null)
        'destination_ephemeral_id': destinationEphemeralId,
      if (signedPayload != null) 'signed_payload': signedPayload,
      if (meshObjectId != null) 'mesh_object_id': meshObjectId,
      if (hopCount != null) 'hop_count': hopCount,
      if (state != null) 'state': state,
      if (routeMode != null) 'route_mode': routeMode,
      if (attempts != null) 'attempts': attempts,
      if (attemptedPeerIdsJson != null)
        'attempted_peer_ids_json': attemptedPeerIdsJson,
      if (nextAttemptAtMs != null) 'next_attempt_at_ms': nextAttemptAtMs,
      if (lastError != null) 'last_error': lastError,
      if (traceId != null) 'trace_id': traceId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuthorityResponseOutboxCompanion copyWith({
    Value<String>? responseId,
    Value<String>? replyToEventId,
    Value<int>? destinationEphemeralId,
    Value<Uint8List>? signedPayload,
    Value<int?>? meshObjectId,
    Value<int>? hopCount,
    Value<String>? state,
    Value<String?>? routeMode,
    Value<int>? attempts,
    Value<String>? attemptedPeerIdsJson,
    Value<int?>? nextAttemptAtMs,
    Value<String?>? lastError,
    Value<Uint8List?>? traceId,
    Value<int>? createdAtMs,
    Value<int>? expiresAtMs,
    Value<int>? rowid,
  }) {
    return AuthorityResponseOutboxCompanion(
      responseId: responseId ?? this.responseId,
      replyToEventId: replyToEventId ?? this.replyToEventId,
      destinationEphemeralId:
          destinationEphemeralId ?? this.destinationEphemeralId,
      signedPayload: signedPayload ?? this.signedPayload,
      meshObjectId: meshObjectId ?? this.meshObjectId,
      hopCount: hopCount ?? this.hopCount,
      state: state ?? this.state,
      routeMode: routeMode ?? this.routeMode,
      attempts: attempts ?? this.attempts,
      attemptedPeerIdsJson: attemptedPeerIdsJson ?? this.attemptedPeerIdsJson,
      nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
      lastError: lastError ?? this.lastError,
      traceId: traceId ?? this.traceId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (responseId.present) {
      map['response_id'] = Variable<String>(responseId.value);
    }
    if (replyToEventId.present) {
      map['reply_to_event_id'] = Variable<String>(replyToEventId.value);
    }
    if (destinationEphemeralId.present) {
      map['destination_ephemeral_id'] = Variable<int>(
        destinationEphemeralId.value,
      );
    }
    if (signedPayload.present) {
      map['signed_payload'] = Variable<Uint8List>(signedPayload.value);
    }
    if (meshObjectId.present) {
      map['mesh_object_id'] = Variable<int>(meshObjectId.value);
    }
    if (hopCount.present) {
      map['hop_count'] = Variable<int>(hopCount.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (routeMode.present) {
      map['route_mode'] = Variable<String>(routeMode.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (attemptedPeerIdsJson.present) {
      map['attempted_peer_ids_json'] = Variable<String>(
        attemptedPeerIdsJson.value,
      );
    }
    if (nextAttemptAtMs.present) {
      map['next_attempt_at_ms'] = Variable<int>(nextAttemptAtMs.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (traceId.present) {
      map['trace_id'] = Variable<Uint8List>(traceId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthorityResponseOutboxCompanion(')
          ..write('responseId: $responseId, ')
          ..write('replyToEventId: $replyToEventId, ')
          ..write('destinationEphemeralId: $destinationEphemeralId, ')
          ..write('signedPayload: $signedPayload, ')
          ..write('meshObjectId: $meshObjectId, ')
          ..write('hopCount: $hopCount, ')
          ..write('state: $state, ')
          ..write('routeMode: $routeMode, ')
          ..write('attempts: $attempts, ')
          ..write('attemptedPeerIdsJson: $attemptedPeerIdsJson, ')
          ..write('nextAttemptAtMs: $nextAttemptAtMs, ')
          ..write('lastError: $lastError, ')
          ..write('traceId: $traceId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuthorityInboxTable extends AuthorityInbox
    with TableInfo<$AuthorityInboxTable, AuthorityInboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthorityInboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _responseIdMeta = const VerificationMeta(
    'responseId',
  );
  @override
  late final GeneratedColumn<String> responseId = GeneratedColumn<String>(
    'response_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToEventIdMeta = const VerificationMeta(
    'replyToEventId',
  );
  @override
  late final GeneratedColumn<String> replyToEventId = GeneratedColumn<String>(
    'reply_to_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseTypeMeta = const VerificationMeta(
    'responseType',
  );
  @override
  late final GeneratedColumn<String> responseType = GeneratedColumn<String>(
    'response_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageTextMeta = const VerificationMeta(
    'messageText',
  );
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
    'message_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMsMeta = const VerificationMeta(
    'expiresAtMs',
  );
  @override
  late final GeneratedColumn<int> expiresAtMs = GeneratedColumn<int>(
    'expires_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMsMeta = const VerificationMeta(
    'receivedAtMs',
  );
  @override
  late final GeneratedColumn<int> receivedAtMs = GeneratedColumn<int>(
    'received_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTraceIdMeta = const VerificationMeta(
    'originalTraceId',
  );
  @override
  late final GeneratedColumn<Uint8List> originalTraceId =
      GeneratedColumn<Uint8List>(
        'original_trace_id',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    responseId,
    replyToEventId,
    siteId,
    responseType,
    messageText,
    createdAtMs,
    expiresAtMs,
    receivedAtMs,
    originalTraceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'authority_inbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuthorityInboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('response_id')) {
      context.handle(
        _responseIdMeta,
        responseId.isAcceptableOrUnknown(data['response_id']!, _responseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_responseIdMeta);
    }
    if (data.containsKey('reply_to_event_id')) {
      context.handle(
        _replyToEventIdMeta,
        replyToEventId.isAcceptableOrUnknown(
          data['reply_to_event_id']!,
          _replyToEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_replyToEventIdMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('response_type')) {
      context.handle(
        _responseTypeMeta,
        responseType.isAcceptableOrUnknown(
          data['response_type']!,
          _responseTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseTypeMeta);
    }
    if (data.containsKey('message_text')) {
      context.handle(
        _messageTextMeta,
        messageText.isAcceptableOrUnknown(
          data['message_text']!,
          _messageTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageTextMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('expires_at_ms')) {
      context.handle(
        _expiresAtMsMeta,
        expiresAtMs.isAcceptableOrUnknown(
          data['expires_at_ms']!,
          _expiresAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMsMeta);
    }
    if (data.containsKey('received_at_ms')) {
      context.handle(
        _receivedAtMsMeta,
        receivedAtMs.isAcceptableOrUnknown(
          data['received_at_ms']!,
          _receivedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMsMeta);
    }
    if (data.containsKey('original_trace_id')) {
      context.handle(
        _originalTraceIdMeta,
        originalTraceId.isAcceptableOrUnknown(
          data['original_trace_id']!,
          _originalTraceIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {responseId};
  @override
  AuthorityInboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuthorityInboxData(
      responseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_id'],
      )!,
      replyToEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_event_id'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      responseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_type'],
      )!,
      messageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_text'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      expiresAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_ms'],
      )!,
      receivedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at_ms'],
      )!,
      originalTraceId: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}original_trace_id'],
      ),
    );
  }

  @override
  $AuthorityInboxTable createAlias(String alias) {
    return $AuthorityInboxTable(attachedDatabase, alias);
  }
}

class AuthorityInboxData extends DataClass
    implements Insertable<AuthorityInboxData> {
  final String responseId;
  final String replyToEventId;
  final String siteId;
  final String responseType;
  final String messageText;
  final int createdAtMs;
  final int expiresAtMs;
  final int receivedAtMs;
  final Uint8List? originalTraceId;
  const AuthorityInboxData({
    required this.responseId,
    required this.replyToEventId,
    required this.siteId,
    required this.responseType,
    required this.messageText,
    required this.createdAtMs,
    required this.expiresAtMs,
    required this.receivedAtMs,
    this.originalTraceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['response_id'] = Variable<String>(responseId);
    map['reply_to_event_id'] = Variable<String>(replyToEventId);
    map['site_id'] = Variable<String>(siteId);
    map['response_type'] = Variable<String>(responseType);
    map['message_text'] = Variable<String>(messageText);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['expires_at_ms'] = Variable<int>(expiresAtMs);
    map['received_at_ms'] = Variable<int>(receivedAtMs);
    if (!nullToAbsent || originalTraceId != null) {
      map['original_trace_id'] = Variable<Uint8List>(originalTraceId);
    }
    return map;
  }

  AuthorityInboxCompanion toCompanion(bool nullToAbsent) {
    return AuthorityInboxCompanion(
      responseId: Value(responseId),
      replyToEventId: Value(replyToEventId),
      siteId: Value(siteId),
      responseType: Value(responseType),
      messageText: Value(messageText),
      createdAtMs: Value(createdAtMs),
      expiresAtMs: Value(expiresAtMs),
      receivedAtMs: Value(receivedAtMs),
      originalTraceId: originalTraceId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTraceId),
    );
  }

  factory AuthorityInboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuthorityInboxData(
      responseId: serializer.fromJson<String>(json['responseId']),
      replyToEventId: serializer.fromJson<String>(json['replyToEventId']),
      siteId: serializer.fromJson<String>(json['siteId']),
      responseType: serializer.fromJson<String>(json['responseType']),
      messageText: serializer.fromJson<String>(json['messageText']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      expiresAtMs: serializer.fromJson<int>(json['expiresAtMs']),
      receivedAtMs: serializer.fromJson<int>(json['receivedAtMs']),
      originalTraceId: serializer.fromJson<Uint8List?>(json['originalTraceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'responseId': serializer.toJson<String>(responseId),
      'replyToEventId': serializer.toJson<String>(replyToEventId),
      'siteId': serializer.toJson<String>(siteId),
      'responseType': serializer.toJson<String>(responseType),
      'messageText': serializer.toJson<String>(messageText),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'expiresAtMs': serializer.toJson<int>(expiresAtMs),
      'receivedAtMs': serializer.toJson<int>(receivedAtMs),
      'originalTraceId': serializer.toJson<Uint8List?>(originalTraceId),
    };
  }

  AuthorityInboxData copyWith({
    String? responseId,
    String? replyToEventId,
    String? siteId,
    String? responseType,
    String? messageText,
    int? createdAtMs,
    int? expiresAtMs,
    int? receivedAtMs,
    Value<Uint8List?> originalTraceId = const Value.absent(),
  }) => AuthorityInboxData(
    responseId: responseId ?? this.responseId,
    replyToEventId: replyToEventId ?? this.replyToEventId,
    siteId: siteId ?? this.siteId,
    responseType: responseType ?? this.responseType,
    messageText: messageText ?? this.messageText,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    expiresAtMs: expiresAtMs ?? this.expiresAtMs,
    receivedAtMs: receivedAtMs ?? this.receivedAtMs,
    originalTraceId: originalTraceId.present
        ? originalTraceId.value
        : this.originalTraceId,
  );
  AuthorityInboxData copyWithCompanion(AuthorityInboxCompanion data) {
    return AuthorityInboxData(
      responseId: data.responseId.present
          ? data.responseId.value
          : this.responseId,
      replyToEventId: data.replyToEventId.present
          ? data.replyToEventId.value
          : this.replyToEventId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      responseType: data.responseType.present
          ? data.responseType.value
          : this.responseType,
      messageText: data.messageText.present
          ? data.messageText.value
          : this.messageText,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      expiresAtMs: data.expiresAtMs.present
          ? data.expiresAtMs.value
          : this.expiresAtMs,
      receivedAtMs: data.receivedAtMs.present
          ? data.receivedAtMs.value
          : this.receivedAtMs,
      originalTraceId: data.originalTraceId.present
          ? data.originalTraceId.value
          : this.originalTraceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuthorityInboxData(')
          ..write('responseId: $responseId, ')
          ..write('replyToEventId: $replyToEventId, ')
          ..write('siteId: $siteId, ')
          ..write('responseType: $responseType, ')
          ..write('messageText: $messageText, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('receivedAtMs: $receivedAtMs, ')
          ..write('originalTraceId: $originalTraceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    responseId,
    replyToEventId,
    siteId,
    responseType,
    messageText,
    createdAtMs,
    expiresAtMs,
    receivedAtMs,
    $driftBlobEquality.hash(originalTraceId),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthorityInboxData &&
          other.responseId == this.responseId &&
          other.replyToEventId == this.replyToEventId &&
          other.siteId == this.siteId &&
          other.responseType == this.responseType &&
          other.messageText == this.messageText &&
          other.createdAtMs == this.createdAtMs &&
          other.expiresAtMs == this.expiresAtMs &&
          other.receivedAtMs == this.receivedAtMs &&
          $driftBlobEquality.equals(
            other.originalTraceId,
            this.originalTraceId,
          ));
}

class AuthorityInboxCompanion extends UpdateCompanion<AuthorityInboxData> {
  final Value<String> responseId;
  final Value<String> replyToEventId;
  final Value<String> siteId;
  final Value<String> responseType;
  final Value<String> messageText;
  final Value<int> createdAtMs;
  final Value<int> expiresAtMs;
  final Value<int> receivedAtMs;
  final Value<Uint8List?> originalTraceId;
  final Value<int> rowid;
  const AuthorityInboxCompanion({
    this.responseId = const Value.absent(),
    this.replyToEventId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.responseType = const Value.absent(),
    this.messageText = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.expiresAtMs = const Value.absent(),
    this.receivedAtMs = const Value.absent(),
    this.originalTraceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuthorityInboxCompanion.insert({
    required String responseId,
    required String replyToEventId,
    required String siteId,
    required String responseType,
    required String messageText,
    required int createdAtMs,
    required int expiresAtMs,
    required int receivedAtMs,
    this.originalTraceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : responseId = Value(responseId),
       replyToEventId = Value(replyToEventId),
       siteId = Value(siteId),
       responseType = Value(responseType),
       messageText = Value(messageText),
       createdAtMs = Value(createdAtMs),
       expiresAtMs = Value(expiresAtMs),
       receivedAtMs = Value(receivedAtMs);
  static Insertable<AuthorityInboxData> custom({
    Expression<String>? responseId,
    Expression<String>? replyToEventId,
    Expression<String>? siteId,
    Expression<String>? responseType,
    Expression<String>? messageText,
    Expression<int>? createdAtMs,
    Expression<int>? expiresAtMs,
    Expression<int>? receivedAtMs,
    Expression<Uint8List>? originalTraceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (responseId != null) 'response_id': responseId,
      if (replyToEventId != null) 'reply_to_event_id': replyToEventId,
      if (siteId != null) 'site_id': siteId,
      if (responseType != null) 'response_type': responseType,
      if (messageText != null) 'message_text': messageText,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (expiresAtMs != null) 'expires_at_ms': expiresAtMs,
      if (receivedAtMs != null) 'received_at_ms': receivedAtMs,
      if (originalTraceId != null) 'original_trace_id': originalTraceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuthorityInboxCompanion copyWith({
    Value<String>? responseId,
    Value<String>? replyToEventId,
    Value<String>? siteId,
    Value<String>? responseType,
    Value<String>? messageText,
    Value<int>? createdAtMs,
    Value<int>? expiresAtMs,
    Value<int>? receivedAtMs,
    Value<Uint8List?>? originalTraceId,
    Value<int>? rowid,
  }) {
    return AuthorityInboxCompanion(
      responseId: responseId ?? this.responseId,
      replyToEventId: replyToEventId ?? this.replyToEventId,
      siteId: siteId ?? this.siteId,
      responseType: responseType ?? this.responseType,
      messageText: messageText ?? this.messageText,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      receivedAtMs: receivedAtMs ?? this.receivedAtMs,
      originalTraceId: originalTraceId ?? this.originalTraceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (responseId.present) {
      map['response_id'] = Variable<String>(responseId.value);
    }
    if (replyToEventId.present) {
      map['reply_to_event_id'] = Variable<String>(replyToEventId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (responseType.present) {
      map['response_type'] = Variable<String>(responseType.value);
    }
    if (messageText.present) {
      map['message_text'] = Variable<String>(messageText.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (expiresAtMs.present) {
      map['expires_at_ms'] = Variable<int>(expiresAtMs.value);
    }
    if (receivedAtMs.present) {
      map['received_at_ms'] = Variable<int>(receivedAtMs.value);
    }
    if (originalTraceId.present) {
      map['original_trace_id'] = Variable<Uint8List>(originalTraceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthorityInboxCompanion(')
          ..write('responseId: $responseId, ')
          ..write('replyToEventId: $replyToEventId, ')
          ..write('siteId: $siteId, ')
          ..write('responseType: $responseType, ')
          ..write('messageText: $messageText, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('expiresAtMs: $expiresAtMs, ')
          ..write('receivedAtMs: $receivedAtMs, ')
          ..write('originalTraceId: $originalTraceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResponseReceiptsTable extends ResponseReceipts
    with TableInfo<$ResponseReceiptsTable, ResponseReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResponseReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseIdMeta = const VerificationMeta(
    'responseId',
  );
  @override
  late final GeneratedColumn<String> responseId = GeneratedColumn<String>(
    'response_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToEventIdMeta = const VerificationMeta(
    'replyToEventId',
  );
  @override
  late final GeneratedColumn<String> replyToEventId = GeneratedColumn<String>(
    'reply_to_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderEphemeralIdMeta = const VerificationMeta(
    'senderEphemeralId',
  );
  @override
  late final GeneratedColumn<int> senderEphemeralId = GeneratedColumn<int>(
    'sender_ephemeral_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('READY'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    receiptId,
    responseId,
    replyToEventId,
    senderEphemeralId,
    createdAtMs,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'response_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResponseReceipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('response_id')) {
      context.handle(
        _responseIdMeta,
        responseId.isAcceptableOrUnknown(data['response_id']!, _responseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_responseIdMeta);
    }
    if (data.containsKey('reply_to_event_id')) {
      context.handle(
        _replyToEventIdMeta,
        replyToEventId.isAcceptableOrUnknown(
          data['reply_to_event_id']!,
          _replyToEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_replyToEventIdMeta);
    }
    if (data.containsKey('sender_ephemeral_id')) {
      context.handle(
        _senderEphemeralIdMeta,
        senderEphemeralId.isAcceptableOrUnknown(
          data['sender_ephemeral_id']!,
          _senderEphemeralIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderEphemeralIdMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {receiptId};
  @override
  ResponseReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResponseReceipt(
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      responseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_id'],
      )!,
      replyToEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_event_id'],
      )!,
      senderEphemeralId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sender_ephemeral_id'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $ResponseReceiptsTable createAlias(String alias) {
    return $ResponseReceiptsTable(attachedDatabase, alias);
  }
}

class ResponseReceipt extends DataClass implements Insertable<ResponseReceipt> {
  final String receiptId;
  final String responseId;
  final String replyToEventId;
  final int senderEphemeralId;
  final int createdAtMs;
  final String state;
  const ResponseReceipt({
    required this.receiptId,
    required this.responseId,
    required this.replyToEventId,
    required this.senderEphemeralId,
    required this.createdAtMs,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['receipt_id'] = Variable<String>(receiptId);
    map['response_id'] = Variable<String>(responseId);
    map['reply_to_event_id'] = Variable<String>(replyToEventId);
    map['sender_ephemeral_id'] = Variable<int>(senderEphemeralId);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['state'] = Variable<String>(state);
    return map;
  }

  ResponseReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ResponseReceiptsCompanion(
      receiptId: Value(receiptId),
      responseId: Value(responseId),
      replyToEventId: Value(replyToEventId),
      senderEphemeralId: Value(senderEphemeralId),
      createdAtMs: Value(createdAtMs),
      state: Value(state),
    );
  }

  factory ResponseReceipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResponseReceipt(
      receiptId: serializer.fromJson<String>(json['receiptId']),
      responseId: serializer.fromJson<String>(json['responseId']),
      replyToEventId: serializer.fromJson<String>(json['replyToEventId']),
      senderEphemeralId: serializer.fromJson<int>(json['senderEphemeralId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'receiptId': serializer.toJson<String>(receiptId),
      'responseId': serializer.toJson<String>(responseId),
      'replyToEventId': serializer.toJson<String>(replyToEventId),
      'senderEphemeralId': serializer.toJson<int>(senderEphemeralId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'state': serializer.toJson<String>(state),
    };
  }

  ResponseReceipt copyWith({
    String? receiptId,
    String? responseId,
    String? replyToEventId,
    int? senderEphemeralId,
    int? createdAtMs,
    String? state,
  }) => ResponseReceipt(
    receiptId: receiptId ?? this.receiptId,
    responseId: responseId ?? this.responseId,
    replyToEventId: replyToEventId ?? this.replyToEventId,
    senderEphemeralId: senderEphemeralId ?? this.senderEphemeralId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    state: state ?? this.state,
  );
  ResponseReceipt copyWithCompanion(ResponseReceiptsCompanion data) {
    return ResponseReceipt(
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      responseId: data.responseId.present
          ? data.responseId.value
          : this.responseId,
      replyToEventId: data.replyToEventId.present
          ? data.replyToEventId.value
          : this.replyToEventId,
      senderEphemeralId: data.senderEphemeralId.present
          ? data.senderEphemeralId.value
          : this.senderEphemeralId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResponseReceipt(')
          ..write('receiptId: $receiptId, ')
          ..write('responseId: $responseId, ')
          ..write('replyToEventId: $replyToEventId, ')
          ..write('senderEphemeralId: $senderEphemeralId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    receiptId,
    responseId,
    replyToEventId,
    senderEphemeralId,
    createdAtMs,
    state,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResponseReceipt &&
          other.receiptId == this.receiptId &&
          other.responseId == this.responseId &&
          other.replyToEventId == this.replyToEventId &&
          other.senderEphemeralId == this.senderEphemeralId &&
          other.createdAtMs == this.createdAtMs &&
          other.state == this.state);
}

class ResponseReceiptsCompanion extends UpdateCompanion<ResponseReceipt> {
  final Value<String> receiptId;
  final Value<String> responseId;
  final Value<String> replyToEventId;
  final Value<int> senderEphemeralId;
  final Value<int> createdAtMs;
  final Value<String> state;
  final Value<int> rowid;
  const ResponseReceiptsCompanion({
    this.receiptId = const Value.absent(),
    this.responseId = const Value.absent(),
    this.replyToEventId = const Value.absent(),
    this.senderEphemeralId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResponseReceiptsCompanion.insert({
    required String receiptId,
    required String responseId,
    required String replyToEventId,
    required int senderEphemeralId,
    required int createdAtMs,
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : receiptId = Value(receiptId),
       responseId = Value(responseId),
       replyToEventId = Value(replyToEventId),
       senderEphemeralId = Value(senderEphemeralId),
       createdAtMs = Value(createdAtMs);
  static Insertable<ResponseReceipt> custom({
    Expression<String>? receiptId,
    Expression<String>? responseId,
    Expression<String>? replyToEventId,
    Expression<int>? senderEphemeralId,
    Expression<int>? createdAtMs,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (receiptId != null) 'receipt_id': receiptId,
      if (responseId != null) 'response_id': responseId,
      if (replyToEventId != null) 'reply_to_event_id': replyToEventId,
      if (senderEphemeralId != null) 'sender_ephemeral_id': senderEphemeralId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResponseReceiptsCompanion copyWith({
    Value<String>? receiptId,
    Value<String>? responseId,
    Value<String>? replyToEventId,
    Value<int>? senderEphemeralId,
    Value<int>? createdAtMs,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return ResponseReceiptsCompanion(
      receiptId: receiptId ?? this.receiptId,
      responseId: responseId ?? this.responseId,
      replyToEventId: replyToEventId ?? this.replyToEventId,
      senderEphemeralId: senderEphemeralId ?? this.senderEphemeralId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (responseId.present) {
      map['response_id'] = Variable<String>(responseId.value);
    }
    if (replyToEventId.present) {
      map['reply_to_event_id'] = Variable<String>(replyToEventId.value);
    }
    if (senderEphemeralId.present) {
      map['sender_ephemeral_id'] = Variable<int>(senderEphemeralId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResponseReceiptsCompanion(')
          ..write('receiptId: $receiptId, ')
          ..write('responseId: $responseId, ')
          ..write('replyToEventId: $replyToEventId, ')
          ..write('senderEphemeralId: $senderEphemeralId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MeshDatabase extends GeneratedDatabase {
  _$MeshDatabase(QueryExecutor e) : super(e);
  $MeshDatabaseManager get managers => $MeshDatabaseManager(this);
  late final $OutboxEventsTable outboxEvents = $OutboxEventsTable(this);
  late final $InboxEventsTable inboxEvents = $InboxEventsTable(this);
  late final $SiteManifestsTable siteManifests = $SiteManifestsTable(this);
  late final $ReverseRoutesTable reverseRoutes = $ReverseRoutesTable(this);
  late final $AuthorityResponseOutboxTable authorityResponseOutbox =
      $AuthorityResponseOutboxTable(this);
  late final $AuthorityInboxTable authorityInbox = $AuthorityInboxTable(this);
  late final $ResponseReceiptsTable responseReceipts = $ResponseReceiptsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxEvents,
    inboxEvents,
    siteManifests,
    reverseRoutes,
    authorityResponseOutbox,
    authorityInbox,
    responseReceipts,
  ];
}

typedef $$OutboxEventsTableCreateCompanionBuilder =
    OutboxEventsCompanion Function({
      required String eventId,
      Value<int?> objectId,
      required String siteId,
      required String roomId,
      required String payloadType,
      Value<String?> inputMode,
      Value<String?> rawText,
      Value<String?> transcript,
      Value<String?> triageJson,
      Value<String?> voicePath,
      required String priority,
      Value<Uint8List?> payload,
      Value<String> state,
      required int createdAtMs,
      required int updatedAtMs,
      required int expiresAtMs,
      Value<int> rowid,
    });
typedef $$OutboxEventsTableUpdateCompanionBuilder =
    OutboxEventsCompanion Function({
      Value<String> eventId,
      Value<int?> objectId,
      Value<String> siteId,
      Value<String> roomId,
      Value<String> payloadType,
      Value<String?> inputMode,
      Value<String?> rawText,
      Value<String?> transcript,
      Value<String?> triageJson,
      Value<String?> voicePath,
      Value<String> priority,
      Value<Uint8List?> payload,
      Value<String> state,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> expiresAtMs,
      Value<int> rowid,
    });

class $$OutboxEventsTableFilterComposer
    extends Composer<_$MeshDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get objectId => $composableBuilder(
    column: $table.objectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triageJson => $composableBuilder(
    column: $table.triageJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voicePath => $composableBuilder(
    column: $table.voicePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEventsTableOrderingComposer
    extends Composer<_$MeshDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get objectId => $composableBuilder(
    column: $table.objectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triageJson => $composableBuilder(
    column: $table.triageJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voicePath => $composableBuilder(
    column: $table.voicePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEventsTableAnnotationComposer
    extends Composer<_$MeshDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<int> get objectId =>
      $composableBuilder(column: $table.objectId, builder: (column) => column);

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputMode =>
      $composableBuilder(column: $table.inputMode, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => column,
  );

  GeneratedColumn<String> get triageJson => $composableBuilder(
    column: $table.triageJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voicePath =>
      $composableBuilder(column: $table.voicePath, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );
}

class $$OutboxEventsTableTableManager
    extends
        RootTableManager<
          _$MeshDatabase,
          $OutboxEventsTable,
          OutboxEvent,
          $$OutboxEventsTableFilterComposer,
          $$OutboxEventsTableOrderingComposer,
          $$OutboxEventsTableAnnotationComposer,
          $$OutboxEventsTableCreateCompanionBuilder,
          $$OutboxEventsTableUpdateCompanionBuilder,
          (
            OutboxEvent,
            BaseReferences<_$MeshDatabase, $OutboxEventsTable, OutboxEvent>,
          ),
          OutboxEvent,
          PrefetchHooks Function()
        > {
  $$OutboxEventsTableTableManager(_$MeshDatabase db, $OutboxEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<int?> objectId = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> payloadType = const Value.absent(),
                Value<String?> inputMode = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                Value<String?> triageJson = const Value.absent(),
                Value<String?> voicePath = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<Uint8List?> payload = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEventsCompanion(
                eventId: eventId,
                objectId: objectId,
                siteId: siteId,
                roomId: roomId,
                payloadType: payloadType,
                inputMode: inputMode,
                rawText: rawText,
                transcript: transcript,
                triageJson: triageJson,
                voicePath: voicePath,
                priority: priority,
                payload: payload,
                state: state,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                expiresAtMs: expiresAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                Value<int?> objectId = const Value.absent(),
                required String siteId,
                required String roomId,
                required String payloadType,
                Value<String?> inputMode = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                Value<String?> triageJson = const Value.absent(),
                Value<String?> voicePath = const Value.absent(),
                required String priority,
                Value<Uint8List?> payload = const Value.absent(),
                Value<String> state = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                required int expiresAtMs,
                Value<int> rowid = const Value.absent(),
              }) => OutboxEventsCompanion.insert(
                eventId: eventId,
                objectId: objectId,
                siteId: siteId,
                roomId: roomId,
                payloadType: payloadType,
                inputMode: inputMode,
                rawText: rawText,
                transcript: transcript,
                triageJson: triageJson,
                voicePath: voicePath,
                priority: priority,
                payload: payload,
                state: state,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                expiresAtMs: expiresAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeshDatabase,
      $OutboxEventsTable,
      OutboxEvent,
      $$OutboxEventsTableFilterComposer,
      $$OutboxEventsTableOrderingComposer,
      $$OutboxEventsTableAnnotationComposer,
      $$OutboxEventsTableCreateCompanionBuilder,
      $$OutboxEventsTableUpdateCompanionBuilder,
      (
        OutboxEvent,
        BaseReferences<_$MeshDatabase, $OutboxEventsTable, OutboxEvent>,
      ),
      OutboxEvent,
      PrefetchHooks Function()
    >;
typedef $$InboxEventsTableCreateCompanionBuilder =
    InboxEventsCompanion Function({
      Value<int> objectId,
      required String eventId,
      required String siteId,
      required String roomId,
      required String payloadType,
      required Uint8List payload,
      required String peerId,
      required int receivedAtMs,
    });
typedef $$InboxEventsTableUpdateCompanionBuilder =
    InboxEventsCompanion Function({
      Value<int> objectId,
      Value<String> eventId,
      Value<String> siteId,
      Value<String> roomId,
      Value<String> payloadType,
      Value<Uint8List> payload,
      Value<String> peerId,
      Value<int> receivedAtMs,
    });

class $$InboxEventsTableFilterComposer
    extends Composer<_$MeshDatabase, $InboxEventsTable> {
  $$InboxEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get objectId => $composableBuilder(
    column: $table.objectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InboxEventsTableOrderingComposer
    extends Composer<_$MeshDatabase, $InboxEventsTable> {
  $$InboxEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get objectId => $composableBuilder(
    column: $table.objectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InboxEventsTableAnnotationComposer
    extends Composer<_$MeshDatabase, $InboxEventsTable> {
  $$InboxEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get objectId =>
      $composableBuilder(column: $table.objectId, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => column,
  );
}

class $$InboxEventsTableTableManager
    extends
        RootTableManager<
          _$MeshDatabase,
          $InboxEventsTable,
          InboxEvent,
          $$InboxEventsTableFilterComposer,
          $$InboxEventsTableOrderingComposer,
          $$InboxEventsTableAnnotationComposer,
          $$InboxEventsTableCreateCompanionBuilder,
          $$InboxEventsTableUpdateCompanionBuilder,
          (
            InboxEvent,
            BaseReferences<_$MeshDatabase, $InboxEventsTable, InboxEvent>,
          ),
          InboxEvent,
          PrefetchHooks Function()
        > {
  $$InboxEventsTableTableManager(_$MeshDatabase db, $InboxEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InboxEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InboxEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InboxEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> objectId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> payloadType = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<String> peerId = const Value.absent(),
                Value<int> receivedAtMs = const Value.absent(),
              }) => InboxEventsCompanion(
                objectId: objectId,
                eventId: eventId,
                siteId: siteId,
                roomId: roomId,
                payloadType: payloadType,
                payload: payload,
                peerId: peerId,
                receivedAtMs: receivedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> objectId = const Value.absent(),
                required String eventId,
                required String siteId,
                required String roomId,
                required String payloadType,
                required Uint8List payload,
                required String peerId,
                required int receivedAtMs,
              }) => InboxEventsCompanion.insert(
                objectId: objectId,
                eventId: eventId,
                siteId: siteId,
                roomId: roomId,
                payloadType: payloadType,
                payload: payload,
                peerId: peerId,
                receivedAtMs: receivedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InboxEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeshDatabase,
      $InboxEventsTable,
      InboxEvent,
      $$InboxEventsTableFilterComposer,
      $$InboxEventsTableOrderingComposer,
      $$InboxEventsTableAnnotationComposer,
      $$InboxEventsTableCreateCompanionBuilder,
      $$InboxEventsTableUpdateCompanionBuilder,
      (
        InboxEvent,
        BaseReferences<_$MeshDatabase, $InboxEventsTable, InboxEvent>,
      ),
      InboxEvent,
      PrefetchHooks Function()
    >;
typedef $$SiteManifestsTableCreateCompanionBuilder =
    SiteManifestsCompanion Function({
      required String siteId,
      required String siteName,
      required String meshCode,
      Value<String?> gatewayHint,
      Value<String?> authorityKeyId,
      Value<String?> authorityPublicKeyJwk,
      required int validFromMs,
      required int validUntilMs,
      required String roomsJson,
      required int joinedAtMs,
      Value<int> rowid,
    });
typedef $$SiteManifestsTableUpdateCompanionBuilder =
    SiteManifestsCompanion Function({
      Value<String> siteId,
      Value<String> siteName,
      Value<String> meshCode,
      Value<String?> gatewayHint,
      Value<String?> authorityKeyId,
      Value<String?> authorityPublicKeyJwk,
      Value<int> validFromMs,
      Value<int> validUntilMs,
      Value<String> roomsJson,
      Value<int> joinedAtMs,
      Value<int> rowid,
    });

class $$SiteManifestsTableFilterComposer
    extends Composer<_$MeshDatabase, $SiteManifestsTable> {
  $$SiteManifestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meshCode => $composableBuilder(
    column: $table.meshCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gatewayHint => $composableBuilder(
    column: $table.gatewayHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorityKeyId => $composableBuilder(
    column: $table.authorityKeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorityPublicKeyJwk => $composableBuilder(
    column: $table.authorityPublicKeyJwk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get validFromMs => $composableBuilder(
    column: $table.validFromMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get validUntilMs => $composableBuilder(
    column: $table.validUntilMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomsJson => $composableBuilder(
    column: $table.roomsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get joinedAtMs => $composableBuilder(
    column: $table.joinedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SiteManifestsTableOrderingComposer
    extends Composer<_$MeshDatabase, $SiteManifestsTable> {
  $$SiteManifestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meshCode => $composableBuilder(
    column: $table.meshCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gatewayHint => $composableBuilder(
    column: $table.gatewayHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorityKeyId => $composableBuilder(
    column: $table.authorityKeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorityPublicKeyJwk => $composableBuilder(
    column: $table.authorityPublicKeyJwk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get validFromMs => $composableBuilder(
    column: $table.validFromMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get validUntilMs => $composableBuilder(
    column: $table.validUntilMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomsJson => $composableBuilder(
    column: $table.roomsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get joinedAtMs => $composableBuilder(
    column: $table.joinedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SiteManifestsTableAnnotationComposer
    extends Composer<_$MeshDatabase, $SiteManifestsTable> {
  $$SiteManifestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get siteName =>
      $composableBuilder(column: $table.siteName, builder: (column) => column);

  GeneratedColumn<String> get meshCode =>
      $composableBuilder(column: $table.meshCode, builder: (column) => column);

  GeneratedColumn<String> get gatewayHint => $composableBuilder(
    column: $table.gatewayHint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorityKeyId => $composableBuilder(
    column: $table.authorityKeyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorityPublicKeyJwk => $composableBuilder(
    column: $table.authorityPublicKeyJwk,
    builder: (column) => column,
  );

  GeneratedColumn<int> get validFromMs => $composableBuilder(
    column: $table.validFromMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get validUntilMs => $composableBuilder(
    column: $table.validUntilMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roomsJson =>
      $composableBuilder(column: $table.roomsJson, builder: (column) => column);

  GeneratedColumn<int> get joinedAtMs => $composableBuilder(
    column: $table.joinedAtMs,
    builder: (column) => column,
  );
}

class $$SiteManifestsTableTableManager
    extends
        RootTableManager<
          _$MeshDatabase,
          $SiteManifestsTable,
          SiteManifest,
          $$SiteManifestsTableFilterComposer,
          $$SiteManifestsTableOrderingComposer,
          $$SiteManifestsTableAnnotationComposer,
          $$SiteManifestsTableCreateCompanionBuilder,
          $$SiteManifestsTableUpdateCompanionBuilder,
          (
            SiteManifest,
            BaseReferences<_$MeshDatabase, $SiteManifestsTable, SiteManifest>,
          ),
          SiteManifest,
          PrefetchHooks Function()
        > {
  $$SiteManifestsTableTableManager(_$MeshDatabase db, $SiteManifestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SiteManifestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SiteManifestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SiteManifestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> siteId = const Value.absent(),
                Value<String> siteName = const Value.absent(),
                Value<String> meshCode = const Value.absent(),
                Value<String?> gatewayHint = const Value.absent(),
                Value<String?> authorityKeyId = const Value.absent(),
                Value<String?> authorityPublicKeyJwk = const Value.absent(),
                Value<int> validFromMs = const Value.absent(),
                Value<int> validUntilMs = const Value.absent(),
                Value<String> roomsJson = const Value.absent(),
                Value<int> joinedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SiteManifestsCompanion(
                siteId: siteId,
                siteName: siteName,
                meshCode: meshCode,
                gatewayHint: gatewayHint,
                authorityKeyId: authorityKeyId,
                authorityPublicKeyJwk: authorityPublicKeyJwk,
                validFromMs: validFromMs,
                validUntilMs: validUntilMs,
                roomsJson: roomsJson,
                joinedAtMs: joinedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String siteId,
                required String siteName,
                required String meshCode,
                Value<String?> gatewayHint = const Value.absent(),
                Value<String?> authorityKeyId = const Value.absent(),
                Value<String?> authorityPublicKeyJwk = const Value.absent(),
                required int validFromMs,
                required int validUntilMs,
                required String roomsJson,
                required int joinedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => SiteManifestsCompanion.insert(
                siteId: siteId,
                siteName: siteName,
                meshCode: meshCode,
                gatewayHint: gatewayHint,
                authorityKeyId: authorityKeyId,
                authorityPublicKeyJwk: authorityPublicKeyJwk,
                validFromMs: validFromMs,
                validUntilMs: validUntilMs,
                roomsJson: roomsJson,
                joinedAtMs: joinedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SiteManifestsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeshDatabase,
      $SiteManifestsTable,
      SiteManifest,
      $$SiteManifestsTableFilterComposer,
      $$SiteManifestsTableOrderingComposer,
      $$SiteManifestsTableAnnotationComposer,
      $$SiteManifestsTableCreateCompanionBuilder,
      $$SiteManifestsTableUpdateCompanionBuilder,
      (
        SiteManifest,
        BaseReferences<_$MeshDatabase, $SiteManifestsTable, SiteManifest>,
      ),
      SiteManifest,
      PrefetchHooks Function()
    >;
typedef $$ReverseRoutesTableCreateCompanionBuilder =
    ReverseRoutesCompanion Function({
      required String siteId,
      required String eventId,
      required int originEphemeralId,
      required int previousPeerEphemeralId,
      Value<String?> previousPeerHint,
      required int learnedAtMs,
      Value<int?> learnedAtElapsedMs,
      required int expiresAtMs,
      required int observedForwardHopCount,
      Value<int?> lastReachableAtMs,
      Value<int> consecutiveFailures,
      Value<double?> qualityScore,
      Value<int> rowid,
    });
typedef $$ReverseRoutesTableUpdateCompanionBuilder =
    ReverseRoutesCompanion Function({
      Value<String> siteId,
      Value<String> eventId,
      Value<int> originEphemeralId,
      Value<int> previousPeerEphemeralId,
      Value<String?> previousPeerHint,
      Value<int> learnedAtMs,
      Value<int?> learnedAtElapsedMs,
      Value<int> expiresAtMs,
      Value<int> observedForwardHopCount,
      Value<int?> lastReachableAtMs,
      Value<int> consecutiveFailures,
      Value<double?> qualityScore,
      Value<int> rowid,
    });

class $$ReverseRoutesTableFilterComposer
    extends Composer<_$MeshDatabase, $ReverseRoutesTable> {
  $$ReverseRoutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originEphemeralId => $composableBuilder(
    column: $table.originEphemeralId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previousPeerEphemeralId => $composableBuilder(
    column: $table.previousPeerEphemeralId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousPeerHint => $composableBuilder(
    column: $table.previousPeerHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnedAtMs => $composableBuilder(
    column: $table.learnedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnedAtElapsedMs => $composableBuilder(
    column: $table.learnedAtElapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get observedForwardHopCount => $composableBuilder(
    column: $table.observedForwardHopCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReachableAtMs => $composableBuilder(
    column: $table.lastReachableAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReverseRoutesTableOrderingComposer
    extends Composer<_$MeshDatabase, $ReverseRoutesTable> {
  $$ReverseRoutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originEphemeralId => $composableBuilder(
    column: $table.originEphemeralId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previousPeerEphemeralId => $composableBuilder(
    column: $table.previousPeerEphemeralId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousPeerHint => $composableBuilder(
    column: $table.previousPeerHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnedAtMs => $composableBuilder(
    column: $table.learnedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnedAtElapsedMs => $composableBuilder(
    column: $table.learnedAtElapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observedForwardHopCount => $composableBuilder(
    column: $table.observedForwardHopCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReachableAtMs => $composableBuilder(
    column: $table.lastReachableAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReverseRoutesTableAnnotationComposer
    extends Composer<_$MeshDatabase, $ReverseRoutesTable> {
  $$ReverseRoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<int> get originEphemeralId => $composableBuilder(
    column: $table.originEphemeralId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get previousPeerEphemeralId => $composableBuilder(
    column: $table.previousPeerEphemeralId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousPeerHint => $composableBuilder(
    column: $table.previousPeerHint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnedAtMs => $composableBuilder(
    column: $table.learnedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnedAtElapsedMs => $composableBuilder(
    column: $table.learnedAtElapsedMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get observedForwardHopCount => $composableBuilder(
    column: $table.observedForwardHopCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReachableAtMs => $composableBuilder(
    column: $table.lastReachableAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => column,
  );

  GeneratedColumn<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => column,
  );
}

class $$ReverseRoutesTableTableManager
    extends
        RootTableManager<
          _$MeshDatabase,
          $ReverseRoutesTable,
          ReverseRoute,
          $$ReverseRoutesTableFilterComposer,
          $$ReverseRoutesTableOrderingComposer,
          $$ReverseRoutesTableAnnotationComposer,
          $$ReverseRoutesTableCreateCompanionBuilder,
          $$ReverseRoutesTableUpdateCompanionBuilder,
          (
            ReverseRoute,
            BaseReferences<_$MeshDatabase, $ReverseRoutesTable, ReverseRoute>,
          ),
          ReverseRoute,
          PrefetchHooks Function()
        > {
  $$ReverseRoutesTableTableManager(_$MeshDatabase db, $ReverseRoutesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReverseRoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReverseRoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReverseRoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> siteId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<int> originEphemeralId = const Value.absent(),
                Value<int> previousPeerEphemeralId = const Value.absent(),
                Value<String?> previousPeerHint = const Value.absent(),
                Value<int> learnedAtMs = const Value.absent(),
                Value<int?> learnedAtElapsedMs = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<int> observedForwardHopCount = const Value.absent(),
                Value<int?> lastReachableAtMs = const Value.absent(),
                Value<int> consecutiveFailures = const Value.absent(),
                Value<double?> qualityScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReverseRoutesCompanion(
                siteId: siteId,
                eventId: eventId,
                originEphemeralId: originEphemeralId,
                previousPeerEphemeralId: previousPeerEphemeralId,
                previousPeerHint: previousPeerHint,
                learnedAtMs: learnedAtMs,
                learnedAtElapsedMs: learnedAtElapsedMs,
                expiresAtMs: expiresAtMs,
                observedForwardHopCount: observedForwardHopCount,
                lastReachableAtMs: lastReachableAtMs,
                consecutiveFailures: consecutiveFailures,
                qualityScore: qualityScore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String siteId,
                required String eventId,
                required int originEphemeralId,
                required int previousPeerEphemeralId,
                Value<String?> previousPeerHint = const Value.absent(),
                required int learnedAtMs,
                Value<int?> learnedAtElapsedMs = const Value.absent(),
                required int expiresAtMs,
                required int observedForwardHopCount,
                Value<int?> lastReachableAtMs = const Value.absent(),
                Value<int> consecutiveFailures = const Value.absent(),
                Value<double?> qualityScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReverseRoutesCompanion.insert(
                siteId: siteId,
                eventId: eventId,
                originEphemeralId: originEphemeralId,
                previousPeerEphemeralId: previousPeerEphemeralId,
                previousPeerHint: previousPeerHint,
                learnedAtMs: learnedAtMs,
                learnedAtElapsedMs: learnedAtElapsedMs,
                expiresAtMs: expiresAtMs,
                observedForwardHopCount: observedForwardHopCount,
                lastReachableAtMs: lastReachableAtMs,
                consecutiveFailures: consecutiveFailures,
                qualityScore: qualityScore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReverseRoutesTableProcessedTableManager =
    ProcessedTableManager<
      _$MeshDatabase,
      $ReverseRoutesTable,
      ReverseRoute,
      $$ReverseRoutesTableFilterComposer,
      $$ReverseRoutesTableOrderingComposer,
      $$ReverseRoutesTableAnnotationComposer,
      $$ReverseRoutesTableCreateCompanionBuilder,
      $$ReverseRoutesTableUpdateCompanionBuilder,
      (
        ReverseRoute,
        BaseReferences<_$MeshDatabase, $ReverseRoutesTable, ReverseRoute>,
      ),
      ReverseRoute,
      PrefetchHooks Function()
    >;
typedef $$AuthorityResponseOutboxTableCreateCompanionBuilder =
    AuthorityResponseOutboxCompanion Function({
      required String responseId,
      required String replyToEventId,
      required int destinationEphemeralId,
      required Uint8List signedPayload,
      Value<int?> meshObjectId,
      Value<int> hopCount,
      required String state,
      Value<String?> routeMode,
      Value<int> attempts,
      Value<String> attemptedPeerIdsJson,
      Value<int?> nextAttemptAtMs,
      Value<String?> lastError,
      Value<Uint8List?> traceId,
      required int createdAtMs,
      required int expiresAtMs,
      Value<int> rowid,
    });
typedef $$AuthorityResponseOutboxTableUpdateCompanionBuilder =
    AuthorityResponseOutboxCompanion Function({
      Value<String> responseId,
      Value<String> replyToEventId,
      Value<int> destinationEphemeralId,
      Value<Uint8List> signedPayload,
      Value<int?> meshObjectId,
      Value<int> hopCount,
      Value<String> state,
      Value<String?> routeMode,
      Value<int> attempts,
      Value<String> attemptedPeerIdsJson,
      Value<int?> nextAttemptAtMs,
      Value<String?> lastError,
      Value<Uint8List?> traceId,
      Value<int> createdAtMs,
      Value<int> expiresAtMs,
      Value<int> rowid,
    });

class $$AuthorityResponseOutboxTableFilterComposer
    extends Composer<_$MeshDatabase, $AuthorityResponseOutboxTable> {
  $$AuthorityResponseOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get destinationEphemeralId => $composableBuilder(
    column: $table.destinationEphemeralId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get signedPayload => $composableBuilder(
    column: $table.signedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get meshObjectId => $composableBuilder(
    column: $table.meshObjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeMode => $composableBuilder(
    column: $table.routeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attemptedPeerIdsJson => $composableBuilder(
    column: $table.attemptedPeerIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get traceId => $composableBuilder(
    column: $table.traceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuthorityResponseOutboxTableOrderingComposer
    extends Composer<_$MeshDatabase, $AuthorityResponseOutboxTable> {
  $$AuthorityResponseOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get destinationEphemeralId => $composableBuilder(
    column: $table.destinationEphemeralId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get signedPayload => $composableBuilder(
    column: $table.signedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get meshObjectId => $composableBuilder(
    column: $table.meshObjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hopCount => $composableBuilder(
    column: $table.hopCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeMode => $composableBuilder(
    column: $table.routeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attemptedPeerIdsJson => $composableBuilder(
    column: $table.attemptedPeerIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get traceId => $composableBuilder(
    column: $table.traceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuthorityResponseOutboxTableAnnotationComposer
    extends Composer<_$MeshDatabase, $AuthorityResponseOutboxTable> {
  $$AuthorityResponseOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get destinationEphemeralId => $composableBuilder(
    column: $table.destinationEphemeralId,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get signedPayload => $composableBuilder(
    column: $table.signedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<int> get meshObjectId => $composableBuilder(
    column: $table.meshObjectId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hopCount =>
      $composableBuilder(column: $table.hopCount, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get routeMode =>
      $composableBuilder(column: $table.routeMode, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get attemptedPeerIdsJson => $composableBuilder(
    column: $table.attemptedPeerIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<Uint8List> get traceId =>
      $composableBuilder(column: $table.traceId, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );
}

class $$AuthorityResponseOutboxTableTableManager
    extends
        RootTableManager<
          _$MeshDatabase,
          $AuthorityResponseOutboxTable,
          AuthorityResponseOutboxData,
          $$AuthorityResponseOutboxTableFilterComposer,
          $$AuthorityResponseOutboxTableOrderingComposer,
          $$AuthorityResponseOutboxTableAnnotationComposer,
          $$AuthorityResponseOutboxTableCreateCompanionBuilder,
          $$AuthorityResponseOutboxTableUpdateCompanionBuilder,
          (
            AuthorityResponseOutboxData,
            BaseReferences<
              _$MeshDatabase,
              $AuthorityResponseOutboxTable,
              AuthorityResponseOutboxData
            >,
          ),
          AuthorityResponseOutboxData,
          PrefetchHooks Function()
        > {
  $$AuthorityResponseOutboxTableTableManager(
    _$MeshDatabase db,
    $AuthorityResponseOutboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuthorityResponseOutboxTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AuthorityResponseOutboxTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AuthorityResponseOutboxTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> responseId = const Value.absent(),
                Value<String> replyToEventId = const Value.absent(),
                Value<int> destinationEphemeralId = const Value.absent(),
                Value<Uint8List> signedPayload = const Value.absent(),
                Value<int?> meshObjectId = const Value.absent(),
                Value<int> hopCount = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> routeMode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> attemptedPeerIdsJson = const Value.absent(),
                Value<int?> nextAttemptAtMs = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<Uint8List?> traceId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuthorityResponseOutboxCompanion(
                responseId: responseId,
                replyToEventId: replyToEventId,
                destinationEphemeralId: destinationEphemeralId,
                signedPayload: signedPayload,
                meshObjectId: meshObjectId,
                hopCount: hopCount,
                state: state,
                routeMode: routeMode,
                attempts: attempts,
                attemptedPeerIdsJson: attemptedPeerIdsJson,
                nextAttemptAtMs: nextAttemptAtMs,
                lastError: lastError,
                traceId: traceId,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String responseId,
                required String replyToEventId,
                required int destinationEphemeralId,
                required Uint8List signedPayload,
                Value<int?> meshObjectId = const Value.absent(),
                Value<int> hopCount = const Value.absent(),
                required String state,
                Value<String?> routeMode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> attemptedPeerIdsJson = const Value.absent(),
                Value<int?> nextAttemptAtMs = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<Uint8List?> traceId = const Value.absent(),
                required int createdAtMs,
                required int expiresAtMs,
                Value<int> rowid = const Value.absent(),
              }) => AuthorityResponseOutboxCompanion.insert(
                responseId: responseId,
                replyToEventId: replyToEventId,
                destinationEphemeralId: destinationEphemeralId,
                signedPayload: signedPayload,
                meshObjectId: meshObjectId,
                hopCount: hopCount,
                state: state,
                routeMode: routeMode,
                attempts: attempts,
                attemptedPeerIdsJson: attemptedPeerIdsJson,
                nextAttemptAtMs: nextAttemptAtMs,
                lastError: lastError,
                traceId: traceId,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuthorityResponseOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$MeshDatabase,
      $AuthorityResponseOutboxTable,
      AuthorityResponseOutboxData,
      $$AuthorityResponseOutboxTableFilterComposer,
      $$AuthorityResponseOutboxTableOrderingComposer,
      $$AuthorityResponseOutboxTableAnnotationComposer,
      $$AuthorityResponseOutboxTableCreateCompanionBuilder,
      $$AuthorityResponseOutboxTableUpdateCompanionBuilder,
      (
        AuthorityResponseOutboxData,
        BaseReferences<
          _$MeshDatabase,
          $AuthorityResponseOutboxTable,
          AuthorityResponseOutboxData
        >,
      ),
      AuthorityResponseOutboxData,
      PrefetchHooks Function()
    >;
typedef $$AuthorityInboxTableCreateCompanionBuilder =
    AuthorityInboxCompanion Function({
      required String responseId,
      required String replyToEventId,
      required String siteId,
      required String responseType,
      required String messageText,
      required int createdAtMs,
      required int expiresAtMs,
      required int receivedAtMs,
      Value<Uint8List?> originalTraceId,
      Value<int> rowid,
    });
typedef $$AuthorityInboxTableUpdateCompanionBuilder =
    AuthorityInboxCompanion Function({
      Value<String> responseId,
      Value<String> replyToEventId,
      Value<String> siteId,
      Value<String> responseType,
      Value<String> messageText,
      Value<int> createdAtMs,
      Value<int> expiresAtMs,
      Value<int> receivedAtMs,
      Value<Uint8List?> originalTraceId,
      Value<int> rowid,
    });

class $$AuthorityInboxTableFilterComposer
    extends Composer<_$MeshDatabase, $AuthorityInboxTable> {
  $$AuthorityInboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseType => $composableBuilder(
    column: $table.responseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get originalTraceId => $composableBuilder(
    column: $table.originalTraceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuthorityInboxTableOrderingComposer
    extends Composer<_$MeshDatabase, $AuthorityInboxTable> {
  $$AuthorityInboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseType => $composableBuilder(
    column: $table.responseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get originalTraceId => $composableBuilder(
    column: $table.originalTraceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuthorityInboxTableAnnotationComposer
    extends Composer<_$MeshDatabase, $AuthorityInboxTable> {
  $$AuthorityInboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get responseType => $composableBuilder(
    column: $table.responseType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMs => $composableBuilder(
    column: $table.expiresAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedAtMs => $composableBuilder(
    column: $table.receivedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get originalTraceId => $composableBuilder(
    column: $table.originalTraceId,
    builder: (column) => column,
  );
}

class $$AuthorityInboxTableTableManager
    extends
        RootTableManager<
          _$MeshDatabase,
          $AuthorityInboxTable,
          AuthorityInboxData,
          $$AuthorityInboxTableFilterComposer,
          $$AuthorityInboxTableOrderingComposer,
          $$AuthorityInboxTableAnnotationComposer,
          $$AuthorityInboxTableCreateCompanionBuilder,
          $$AuthorityInboxTableUpdateCompanionBuilder,
          (
            AuthorityInboxData,
            BaseReferences<
              _$MeshDatabase,
              $AuthorityInboxTable,
              AuthorityInboxData
            >,
          ),
          AuthorityInboxData,
          PrefetchHooks Function()
        > {
  $$AuthorityInboxTableTableManager(
    _$MeshDatabase db,
    $AuthorityInboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuthorityInboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuthorityInboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuthorityInboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> responseId = const Value.absent(),
                Value<String> replyToEventId = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> responseType = const Value.absent(),
                Value<String> messageText = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> expiresAtMs = const Value.absent(),
                Value<int> receivedAtMs = const Value.absent(),
                Value<Uint8List?> originalTraceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuthorityInboxCompanion(
                responseId: responseId,
                replyToEventId: replyToEventId,
                siteId: siteId,
                responseType: responseType,
                messageText: messageText,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                receivedAtMs: receivedAtMs,
                originalTraceId: originalTraceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String responseId,
                required String replyToEventId,
                required String siteId,
                required String responseType,
                required String messageText,
                required int createdAtMs,
                required int expiresAtMs,
                required int receivedAtMs,
                Value<Uint8List?> originalTraceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuthorityInboxCompanion.insert(
                responseId: responseId,
                replyToEventId: replyToEventId,
                siteId: siteId,
                responseType: responseType,
                messageText: messageText,
                createdAtMs: createdAtMs,
                expiresAtMs: expiresAtMs,
                receivedAtMs: receivedAtMs,
                originalTraceId: originalTraceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuthorityInboxTableProcessedTableManager =
    ProcessedTableManager<
      _$MeshDatabase,
      $AuthorityInboxTable,
      AuthorityInboxData,
      $$AuthorityInboxTableFilterComposer,
      $$AuthorityInboxTableOrderingComposer,
      $$AuthorityInboxTableAnnotationComposer,
      $$AuthorityInboxTableCreateCompanionBuilder,
      $$AuthorityInboxTableUpdateCompanionBuilder,
      (
        AuthorityInboxData,
        BaseReferences<
          _$MeshDatabase,
          $AuthorityInboxTable,
          AuthorityInboxData
        >,
      ),
      AuthorityInboxData,
      PrefetchHooks Function()
    >;
typedef $$ResponseReceiptsTableCreateCompanionBuilder =
    ResponseReceiptsCompanion Function({
      required String receiptId,
      required String responseId,
      required String replyToEventId,
      required int senderEphemeralId,
      required int createdAtMs,
      Value<String> state,
      Value<int> rowid,
    });
typedef $$ResponseReceiptsTableUpdateCompanionBuilder =
    ResponseReceiptsCompanion Function({
      Value<String> receiptId,
      Value<String> responseId,
      Value<String> replyToEventId,
      Value<int> senderEphemeralId,
      Value<int> createdAtMs,
      Value<String> state,
      Value<int> rowid,
    });

class $$ResponseReceiptsTableFilterComposer
    extends Composer<_$MeshDatabase, $ResponseReceiptsTable> {
  $$ResponseReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get senderEphemeralId => $composableBuilder(
    column: $table.senderEphemeralId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ResponseReceiptsTableOrderingComposer
    extends Composer<_$MeshDatabase, $ResponseReceiptsTable> {
  $$ResponseReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get senderEphemeralId => $composableBuilder(
    column: $table.senderEphemeralId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ResponseReceiptsTableAnnotationComposer
    extends Composer<_$MeshDatabase, $ResponseReceiptsTable> {
  $$ResponseReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get responseId => $composableBuilder(
    column: $table.responseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToEventId => $composableBuilder(
    column: $table.replyToEventId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get senderEphemeralId => $composableBuilder(
    column: $table.senderEphemeralId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$ResponseReceiptsTableTableManager
    extends
        RootTableManager<
          _$MeshDatabase,
          $ResponseReceiptsTable,
          ResponseReceipt,
          $$ResponseReceiptsTableFilterComposer,
          $$ResponseReceiptsTableOrderingComposer,
          $$ResponseReceiptsTableAnnotationComposer,
          $$ResponseReceiptsTableCreateCompanionBuilder,
          $$ResponseReceiptsTableUpdateCompanionBuilder,
          (
            ResponseReceipt,
            BaseReferences<
              _$MeshDatabase,
              $ResponseReceiptsTable,
              ResponseReceipt
            >,
          ),
          ResponseReceipt,
          PrefetchHooks Function()
        > {
  $$ResponseReceiptsTableTableManager(
    _$MeshDatabase db,
    $ResponseReceiptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResponseReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResponseReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResponseReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> receiptId = const Value.absent(),
                Value<String> responseId = const Value.absent(),
                Value<String> replyToEventId = const Value.absent(),
                Value<int> senderEphemeralId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResponseReceiptsCompanion(
                receiptId: receiptId,
                responseId: responseId,
                replyToEventId: replyToEventId,
                senderEphemeralId: senderEphemeralId,
                createdAtMs: createdAtMs,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String receiptId,
                required String responseId,
                required String replyToEventId,
                required int senderEphemeralId,
                required int createdAtMs,
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResponseReceiptsCompanion.insert(
                receiptId: receiptId,
                responseId: responseId,
                replyToEventId: replyToEventId,
                senderEphemeralId: senderEphemeralId,
                createdAtMs: createdAtMs,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ResponseReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeshDatabase,
      $ResponseReceiptsTable,
      ResponseReceipt,
      $$ResponseReceiptsTableFilterComposer,
      $$ResponseReceiptsTableOrderingComposer,
      $$ResponseReceiptsTableAnnotationComposer,
      $$ResponseReceiptsTableCreateCompanionBuilder,
      $$ResponseReceiptsTableUpdateCompanionBuilder,
      (
        ResponseReceipt,
        BaseReferences<_$MeshDatabase, $ResponseReceiptsTable, ResponseReceipt>,
      ),
      ResponseReceipt,
      PrefetchHooks Function()
    >;

class $MeshDatabaseManager {
  final _$MeshDatabase _db;
  $MeshDatabaseManager(this._db);
  $$OutboxEventsTableTableManager get outboxEvents =>
      $$OutboxEventsTableTableManager(_db, _db.outboxEvents);
  $$InboxEventsTableTableManager get inboxEvents =>
      $$InboxEventsTableTableManager(_db, _db.inboxEvents);
  $$SiteManifestsTableTableManager get siteManifests =>
      $$SiteManifestsTableTableManager(_db, _db.siteManifests);
  $$ReverseRoutesTableTableManager get reverseRoutes =>
      $$ReverseRoutesTableTableManager(_db, _db.reverseRoutes);
  $$AuthorityResponseOutboxTableTableManager get authorityResponseOutbox =>
      $$AuthorityResponseOutboxTableTableManager(
        _db,
        _db.authorityResponseOutbox,
      );
  $$AuthorityInboxTableTableManager get authorityInbox =>
      $$AuthorityInboxTableTableManager(_db, _db.authorityInbox);
  $$ResponseReceiptsTableTableManager get responseReceipts =>
      $$ResponseReceiptsTableTableManager(_db, _db.responseReceipts);
}
