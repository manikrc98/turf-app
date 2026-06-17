import 'package:isar/isar.dart';

part 'local_walk_session.g.dart';

@collection
class LocalWalkSession {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String sessionId;

  late String userId;
  
  late String dateTime;
  late int steps;
  late bool isStepEstimated;
  late double distanceKm;
  late int loopCount;
  late int durationSeconds;
  late int cadence;
  late double elevationGainMetres;
  
  late List<double> trailLatList;
  late List<double> trailLngList;
  
  late String loopsJson; // JSON serialized string of captured TurfLoops
  
  late bool isSynced; // Offline-first queue state indicator
}
