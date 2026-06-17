import 'package:isar/isar.dart';

part 'local_claimed_loop.g.dart';

@collection
class LocalClaimedLoop {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String loopId;

  late String userId;
  late bool isSynced;
  
  late String name;
  
  late List<double> latList;
  late List<double> lngList;
  
  late int streakCount;
  late String lastCoveredDate;
  late int coveredCountToday;
  
  late String ownerId;
  late String ownerName;
  late bool isMyClaim;
}
