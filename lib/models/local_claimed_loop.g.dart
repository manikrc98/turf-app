// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_claimed_loop.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalClaimedLoopCollection on Isar {
  IsarCollection<LocalClaimedLoop> get localClaimedLoops => this.collection();
}

const LocalClaimedLoopSchema = CollectionSchema(
  name: r'LocalClaimedLoop',
  id: -4395100441551274553,
  properties: {
    r'coveredCountToday': PropertySchema(
      id: 0,
      name: r'coveredCountToday',
      type: IsarType.long,
    ),
    r'isMyClaim': PropertySchema(
      id: 1,
      name: r'isMyClaim',
      type: IsarType.bool,
    ),
    r'lastCoveredDate': PropertySchema(
      id: 2,
      name: r'lastCoveredDate',
      type: IsarType.string,
    ),
    r'latList': PropertySchema(
      id: 3,
      name: r'latList',
      type: IsarType.doubleList,
    ),
    r'lngList': PropertySchema(
      id: 4,
      name: r'lngList',
      type: IsarType.doubleList,
    ),
    r'loopId': PropertySchema(
      id: 5,
      name: r'loopId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'ownerId': PropertySchema(
      id: 7,
      name: r'ownerId',
      type: IsarType.string,
    ),
    r'ownerName': PropertySchema(
      id: 8,
      name: r'ownerName',
      type: IsarType.string,
    ),
    r'streakCount': PropertySchema(
      id: 9,
      name: r'streakCount',
      type: IsarType.long,
    )
  },
  estimateSize: _localClaimedLoopEstimateSize,
  serialize: _localClaimedLoopSerialize,
  deserialize: _localClaimedLoopDeserialize,
  deserializeProp: _localClaimedLoopDeserializeProp,
  idName: r'id',
  indexes: {
    r'loopId': IndexSchema(
      id: -8165056483123995620,
      name: r'loopId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'loopId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localClaimedLoopGetId,
  getLinks: _localClaimedLoopGetLinks,
  attach: _localClaimedLoopAttach,
  version: '3.1.0+1',
);

int _localClaimedLoopEstimateSize(
  LocalClaimedLoop object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.lastCoveredDate.length * 3;
  bytesCount += 3 + object.latList.length * 8;
  bytesCount += 3 + object.lngList.length * 8;
  bytesCount += 3 + object.loopId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.ownerId.length * 3;
  bytesCount += 3 + object.ownerName.length * 3;
  return bytesCount;
}

void _localClaimedLoopSerialize(
  LocalClaimedLoop object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.coveredCountToday);
  writer.writeBool(offsets[1], object.isMyClaim);
  writer.writeString(offsets[2], object.lastCoveredDate);
  writer.writeDoubleList(offsets[3], object.latList);
  writer.writeDoubleList(offsets[4], object.lngList);
  writer.writeString(offsets[5], object.loopId);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.ownerId);
  writer.writeString(offsets[8], object.ownerName);
  writer.writeLong(offsets[9], object.streakCount);
}

LocalClaimedLoop _localClaimedLoopDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalClaimedLoop();
  object.coveredCountToday = reader.readLong(offsets[0]);
  object.id = id;
  object.isMyClaim = reader.readBool(offsets[1]);
  object.lastCoveredDate = reader.readString(offsets[2]);
  object.latList = reader.readDoubleList(offsets[3]) ?? [];
  object.lngList = reader.readDoubleList(offsets[4]) ?? [];
  object.loopId = reader.readString(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.ownerId = reader.readString(offsets[7]);
  object.ownerName = reader.readString(offsets[8]);
  object.streakCount = reader.readLong(offsets[9]);
  return object;
}

P _localClaimedLoopDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 4:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localClaimedLoopGetId(LocalClaimedLoop object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localClaimedLoopGetLinks(LocalClaimedLoop object) {
  return [];
}

void _localClaimedLoopAttach(
    IsarCollection<dynamic> col, Id id, LocalClaimedLoop object) {
  object.id = id;
}

extension LocalClaimedLoopByIndex on IsarCollection<LocalClaimedLoop> {
  Future<LocalClaimedLoop?> getByLoopId(String loopId) {
    return getByIndex(r'loopId', [loopId]);
  }

  LocalClaimedLoop? getByLoopIdSync(String loopId) {
    return getByIndexSync(r'loopId', [loopId]);
  }

  Future<bool> deleteByLoopId(String loopId) {
    return deleteByIndex(r'loopId', [loopId]);
  }

  bool deleteByLoopIdSync(String loopId) {
    return deleteByIndexSync(r'loopId', [loopId]);
  }

  Future<List<LocalClaimedLoop?>> getAllByLoopId(List<String> loopIdValues) {
    final values = loopIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'loopId', values);
  }

  List<LocalClaimedLoop?> getAllByLoopIdSync(List<String> loopIdValues) {
    final values = loopIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'loopId', values);
  }

  Future<int> deleteAllByLoopId(List<String> loopIdValues) {
    final values = loopIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'loopId', values);
  }

  int deleteAllByLoopIdSync(List<String> loopIdValues) {
    final values = loopIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'loopId', values);
  }

  Future<Id> putByLoopId(LocalClaimedLoop object) {
    return putByIndex(r'loopId', object);
  }

  Id putByLoopIdSync(LocalClaimedLoop object, {bool saveLinks = true}) {
    return putByIndexSync(r'loopId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByLoopId(List<LocalClaimedLoop> objects) {
    return putAllByIndex(r'loopId', objects);
  }

  List<Id> putAllByLoopIdSync(List<LocalClaimedLoop> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'loopId', objects, saveLinks: saveLinks);
  }
}

extension LocalClaimedLoopQueryWhereSort
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QWhere> {
  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalClaimedLoopQueryWhere
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QWhereClause> {
  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterWhereClause>
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

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterWhereClause> idBetween(
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

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterWhereClause>
      loopIdEqualTo(String loopId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'loopId',
        value: [loopId],
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterWhereClause>
      loopIdNotEqualTo(String loopId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loopId',
              lower: [],
              upper: [loopId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loopId',
              lower: [loopId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loopId',
              lower: [loopId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'loopId',
              lower: [],
              upper: [loopId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalClaimedLoopQueryFilter
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QFilterCondition> {
  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      coveredCountTodayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coveredCountToday',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      coveredCountTodayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coveredCountToday',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      coveredCountTodayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coveredCountToday',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      coveredCountTodayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coveredCountToday',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
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

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
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

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
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

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      isMyClaimEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMyClaim',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastCoveredDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastCoveredDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastCoveredDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastCoveredDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastCoveredDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastCoveredDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastCoveredDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastCoveredDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastCoveredDate',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lastCoveredDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastCoveredDate',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latList',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'latList',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'latList',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'latList',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'latList',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'latList',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      latListLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'latList',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lngList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lngList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lngList',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lngList',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lngList',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lngList',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lngList',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lngList',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lngList',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      lngListLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lngList',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loopId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loopId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loopId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loopId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'loopId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'loopId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'loopId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'loopId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loopId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      loopIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'loopId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      ownerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      streakCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'streakCount',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      streakCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'streakCount',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      streakCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'streakCount',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterFilterCondition>
      streakCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'streakCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LocalClaimedLoopQueryObject
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QFilterCondition> {}

extension LocalClaimedLoopQueryLinks
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QFilterCondition> {}

extension LocalClaimedLoopQuerySortBy
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QSortBy> {
  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByCoveredCountToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coveredCountToday', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByCoveredCountTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coveredCountToday', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByIsMyClaim() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMyClaim', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByIsMyClaimDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMyClaim', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByLastCoveredDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCoveredDate', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByLastCoveredDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCoveredDate', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByLoopId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopId', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByLoopIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopId', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByOwnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByOwnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByStreakCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakCount', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      sortByStreakCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakCount', Sort.desc);
    });
  }
}

extension LocalClaimedLoopQuerySortThenBy
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QSortThenBy> {
  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByCoveredCountToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coveredCountToday', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByCoveredCountTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coveredCountToday', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByIsMyClaim() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMyClaim', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByIsMyClaimDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMyClaim', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByLastCoveredDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCoveredDate', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByLastCoveredDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCoveredDate', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByLoopId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopId', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByLoopIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopId', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByOwnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByOwnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.desc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByStreakCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakCount', Sort.asc);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QAfterSortBy>
      thenByStreakCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakCount', Sort.desc);
    });
  }
}

extension LocalClaimedLoopQueryWhereDistinct
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct> {
  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct>
      distinctByCoveredCountToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coveredCountToday');
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct>
      distinctByIsMyClaim() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMyClaim');
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct>
      distinctByLastCoveredDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCoveredDate',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct>
      distinctByLatList() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latList');
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct>
      distinctByLngList() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lngList');
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct> distinctByLoopId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loopId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct> distinctByOwnerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct>
      distinctByOwnerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QDistinct>
      distinctByStreakCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'streakCount');
    });
  }
}

extension LocalClaimedLoopQueryProperty
    on QueryBuilder<LocalClaimedLoop, LocalClaimedLoop, QQueryProperty> {
  QueryBuilder<LocalClaimedLoop, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalClaimedLoop, int, QQueryOperations>
      coveredCountTodayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coveredCountToday');
    });
  }

  QueryBuilder<LocalClaimedLoop, bool, QQueryOperations> isMyClaimProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMyClaim');
    });
  }

  QueryBuilder<LocalClaimedLoop, String, QQueryOperations>
      lastCoveredDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCoveredDate');
    });
  }

  QueryBuilder<LocalClaimedLoop, List<double>, QQueryOperations>
      latListProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latList');
    });
  }

  QueryBuilder<LocalClaimedLoop, List<double>, QQueryOperations>
      lngListProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lngList');
    });
  }

  QueryBuilder<LocalClaimedLoop, String, QQueryOperations> loopIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loopId');
    });
  }

  QueryBuilder<LocalClaimedLoop, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<LocalClaimedLoop, String, QQueryOperations> ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<LocalClaimedLoop, String, QQueryOperations> ownerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerName');
    });
  }

  QueryBuilder<LocalClaimedLoop, int, QQueryOperations> streakCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'streakCount');
    });
  }
}
