// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_walk_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalWalkSessionCollection on Isar {
  IsarCollection<LocalWalkSession> get localWalkSessions => this.collection();
}

const LocalWalkSessionSchema = CollectionSchema(
  name: r'LocalWalkSession',
  id: 580398286641278448,
  properties: {
    r'cadence': PropertySchema(
      id: 0,
      name: r'cadence',
      type: IsarType.long,
    ),
    r'dateTime': PropertySchema(
      id: 1,
      name: r'dateTime',
      type: IsarType.string,
    ),
    r'distanceKm': PropertySchema(
      id: 2,
      name: r'distanceKm',
      type: IsarType.double,
    ),
    r'durationSeconds': PropertySchema(
      id: 3,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'elevationGainMetres': PropertySchema(
      id: 4,
      name: r'elevationGainMetres',
      type: IsarType.double,
    ),
    r'isStepEstimated': PropertySchema(
      id: 5,
      name: r'isStepEstimated',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 6,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'loopCount': PropertySchema(
      id: 7,
      name: r'loopCount',
      type: IsarType.long,
    ),
    r'loopsJson': PropertySchema(
      id: 8,
      name: r'loopsJson',
      type: IsarType.string,
    ),
    r'sessionId': PropertySchema(
      id: 9,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'steps': PropertySchema(
      id: 10,
      name: r'steps',
      type: IsarType.long,
    ),
    r'trailLatList': PropertySchema(
      id: 11,
      name: r'trailLatList',
      type: IsarType.doubleList,
    ),
    r'trailLngList': PropertySchema(
      id: 12,
      name: r'trailLngList',
      type: IsarType.doubleList,
    )
  },
  estimateSize: _localWalkSessionEstimateSize,
  serialize: _localWalkSessionSerialize,
  deserialize: _localWalkSessionDeserialize,
  deserializeProp: _localWalkSessionDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionId': IndexSchema(
      id: 6949518585047923839,
      name: r'sessionId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localWalkSessionGetId,
  getLinks: _localWalkSessionGetLinks,
  attach: _localWalkSessionAttach,
  version: '3.1.0+1',
);

int _localWalkSessionEstimateSize(
  LocalWalkSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateTime.length * 3;
  bytesCount += 3 + object.loopsJson.length * 3;
  bytesCount += 3 + object.sessionId.length * 3;
  bytesCount += 3 + object.trailLatList.length * 8;
  bytesCount += 3 + object.trailLngList.length * 8;
  return bytesCount;
}

void _localWalkSessionSerialize(
  LocalWalkSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.cadence);
  writer.writeString(offsets[1], object.dateTime);
  writer.writeDouble(offsets[2], object.distanceKm);
  writer.writeLong(offsets[3], object.durationSeconds);
  writer.writeDouble(offsets[4], object.elevationGainMetres);
  writer.writeBool(offsets[5], object.isStepEstimated);
  writer.writeBool(offsets[6], object.isSynced);
  writer.writeLong(offsets[7], object.loopCount);
  writer.writeString(offsets[8], object.loopsJson);
  writer.writeString(offsets[9], object.sessionId);
  writer.writeLong(offsets[10], object.steps);
  writer.writeDoubleList(offsets[11], object.trailLatList);
  writer.writeDoubleList(offsets[12], object.trailLngList);
}

LocalWalkSession _localWalkSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalWalkSession();
  object.cadence = reader.readLong(offsets[0]);
  object.dateTime = reader.readString(offsets[1]);
  object.distanceKm = reader.readDouble(offsets[2]);
  object.durationSeconds = reader.readLong(offsets[3]);
  object.elevationGainMetres = reader.readDouble(offsets[4]);
  object.id = id;
  object.isStepEstimated = reader.readBool(offsets[5]);
  object.isSynced = reader.readBool(offsets[6]);
  object.loopCount = reader.readLong(offsets[7]);
  object.loopsJson = reader.readString(offsets[8]);
  object.sessionId = reader.readString(offsets[9]);
  object.steps = reader.readLong(offsets[10]);
  object.trailLatList = reader.readDoubleList(offsets[11]) ?? [];
  object.trailLngList = reader.readDoubleList(offsets[12]) ?? [];
  return object;
}

P _localWalkSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 12:
      return (reader.readDoubleList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localWalkSessionGetId(LocalWalkSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localWalkSessionGetLinks(LocalWalkSession object) {
  return [];
}

void _localWalkSessionAttach(
    IsarCollection<dynamic> col, Id id, LocalWalkSession object) {
  object.id = id;
}

extension LocalWalkSessionByIndex on IsarCollection<LocalWalkSession> {
  Future<LocalWalkSession?> getBySessionId(String sessionId) {
    return getByIndex(r'sessionId', [sessionId]);
  }

  LocalWalkSession? getBySessionIdSync(String sessionId) {
    return getByIndexSync(r'sessionId', [sessionId]);
  }

  Future<bool> deleteBySessionId(String sessionId) {
    return deleteByIndex(r'sessionId', [sessionId]);
  }

  bool deleteBySessionIdSync(String sessionId) {
    return deleteByIndexSync(r'sessionId', [sessionId]);
  }

  Future<List<LocalWalkSession?>> getAllBySessionId(
      List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'sessionId', values);
  }

  List<LocalWalkSession?> getAllBySessionIdSync(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'sessionId', values);
  }

  Future<int> deleteAllBySessionId(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'sessionId', values);
  }

  int deleteAllBySessionIdSync(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sessionId', values);
  }

  Future<Id> putBySessionId(LocalWalkSession object) {
    return putByIndex(r'sessionId', object);
  }

  Id putBySessionIdSync(LocalWalkSession object, {bool saveLinks = true}) {
    return putByIndexSync(r'sessionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySessionId(List<LocalWalkSession> objects) {
    return putAllByIndex(r'sessionId', objects);
  }

  List<Id> putAllBySessionIdSync(List<LocalWalkSession> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'sessionId', objects, saveLinks: saveLinks);
  }
}

extension LocalWalkSessionQueryWhereSort
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QWhere> {
  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalWalkSessionQueryWhere
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QWhereClause> {
  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterWhereClause>
      sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterWhereClause>
      sessionIdNotEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalWalkSessionQueryFilter
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QFilterCondition> {
  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      cadenceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cadence',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      cadenceGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cadence',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      cadenceLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cadence',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      cadenceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cadence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateTime',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      dateTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateTime',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      distanceKmEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'distanceKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      distanceKmGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'distanceKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      distanceKmLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'distanceKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      distanceKmBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'distanceKm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      durationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      durationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      durationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      durationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      elevationGainMetresEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'elevationGainMetres',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      elevationGainMetresGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'elevationGainMetres',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      elevationGainMetresLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'elevationGainMetres',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      elevationGainMetresBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'elevationGainMetres',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      isStepEstimatedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isStepEstimated',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loopCount',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loopCount',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loopCount',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loopCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loopsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loopsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loopsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loopsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'loopsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'loopsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'loopsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'loopsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loopsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      loopsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'loopsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      stepsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      stepsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      stepsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      stepsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'steps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trailLatList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trailLatList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trailLatList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trailLatList',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLatList',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLatList',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLatList',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLatList',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLatList',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLatListLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLatList',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trailLngList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trailLngList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trailLngList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trailLngList',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLngList',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLngList',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLngList',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLngList',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLngList',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterFilterCondition>
      trailLngListLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trailLngList',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension LocalWalkSessionQueryObject
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QFilterCondition> {}

extension LocalWalkSessionQueryLinks
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QFilterCondition> {}

extension LocalWalkSessionQuerySortBy
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QSortBy> {
  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByCadence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cadence', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByCadenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cadence', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByDistanceKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByElevationGainMetres() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevationGainMetres', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByElevationGainMetresDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevationGainMetres', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByIsStepEstimated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStepEstimated', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByIsStepEstimatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStepEstimated', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByLoopCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopCount', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByLoopCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopCount', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByLoopsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopsJson', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByLoopsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopsJson', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy> sortBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      sortByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }
}

extension LocalWalkSessionQuerySortThenBy
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QSortThenBy> {
  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByCadence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cadence', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByCadenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cadence', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByDistanceKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByElevationGainMetres() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevationGainMetres', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByElevationGainMetresDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevationGainMetres', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByIsStepEstimated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStepEstimated', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByIsStepEstimatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStepEstimated', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByLoopCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopCount', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByLoopCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopCount', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByLoopsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopsJson', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByLoopsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopsJson', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy> thenBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QAfterSortBy>
      thenByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }
}

extension LocalWalkSessionQueryWhereDistinct
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct> {
  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByCadence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cadence');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByDateTime({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateTime', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distanceKm');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByElevationGainMetres() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'elevationGainMetres');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByIsStepEstimated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isStepEstimated');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByLoopCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loopCount');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByLoopsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loopsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctBySessionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'steps');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByTrailLatList() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trailLatList');
    });
  }

  QueryBuilder<LocalWalkSession, LocalWalkSession, QDistinct>
      distinctByTrailLngList() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trailLngList');
    });
  }
}

extension LocalWalkSessionQueryProperty
    on QueryBuilder<LocalWalkSession, LocalWalkSession, QQueryProperty> {
  QueryBuilder<LocalWalkSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalWalkSession, int, QQueryOperations> cadenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cadence');
    });
  }

  QueryBuilder<LocalWalkSession, String, QQueryOperations> dateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateTime');
    });
  }

  QueryBuilder<LocalWalkSession, double, QQueryOperations>
      distanceKmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distanceKm');
    });
  }

  QueryBuilder<LocalWalkSession, int, QQueryOperations>
      durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<LocalWalkSession, double, QQueryOperations>
      elevationGainMetresProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'elevationGainMetres');
    });
  }

  QueryBuilder<LocalWalkSession, bool, QQueryOperations>
      isStepEstimatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isStepEstimated');
    });
  }

  QueryBuilder<LocalWalkSession, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<LocalWalkSession, int, QQueryOperations> loopCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loopCount');
    });
  }

  QueryBuilder<LocalWalkSession, String, QQueryOperations> loopsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loopsJson');
    });
  }

  QueryBuilder<LocalWalkSession, String, QQueryOperations> sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<LocalWalkSession, int, QQueryOperations> stepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'steps');
    });
  }

  QueryBuilder<LocalWalkSession, List<double>, QQueryOperations>
      trailLatListProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trailLatList');
    });
  }

  QueryBuilder<LocalWalkSession, List<double>, QQueryOperations>
      trailLngListProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trailLngList');
    });
  }
}
