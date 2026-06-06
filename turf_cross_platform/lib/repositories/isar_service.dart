import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_claimed_loop.dart';
import '../models/local_walk_session.dart';

class IsarService {
  static Isar? _isar;

  /// Open Isar Database instance once and cache it
  static Future<Isar> getDB() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [LocalClaimedLoopSchema, LocalWalkSessionSchema],
      directory: dir.path,
    );
    return _isar!;
  }
}
