import 'dart:convert';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/claimed_loop.dart';
import '../models/local_claimed_loop.dart';
import 'isar_service.dart';

class ClaimedLoopRepository {
  
  /// Helper to get Date string formatted as yyyy-MM-dd
  static String getDateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String getTodayDateString() => getDateString(DateTime.now());
  static String getYesterdayDateString() => getDateString(DateTime.now().subtract(const Duration(days: 1)));

  /// Converts an Isar LocalClaimedLoop to UI model ClaimedLoop
  ClaimedLoop _toClaimedLoop(LocalClaimedLoop local) {
    final List<LatLng> points = [];
    final int len = local.latList.length;
    for (int i = 0; i < len; i++) {
      points.add(LatLng(local.latList[i], local.lngList[i]));
    }
    return ClaimedLoop(
      id: local.loopId,
      name: local.name,
      points: points,
      streakCount: local.streakCount,
      lastCoveredDate: local.lastCoveredDate,
      coveredCountToday: local.coveredCountToday,
      ownerId: local.ownerId,
      ownerName: local.ownerName,
      isMyClaim: local.isMyClaim,
    );
  }

  /// Converts a UI ClaimedLoop to Isar LocalClaimedLoop
  LocalClaimedLoop _toLocal(ClaimedLoop loop) {
    final local = LocalClaimedLoop()
      ..loopId = loop.id
      ..name = loop.name
      ..latList = loop.points.map((p) => p.latitude).toList()
      ..lngList = loop.points.map((p) => p.longitude).toList()
      ..streakCount = loop.streakCount
      ..lastCoveredDate = loop.lastCoveredDate
      ..coveredCountToday = loop.coveredCountToday
      ..ownerId = loop.ownerId.isEmpty ? 'local_user' : loop.ownerId
      ..ownerName = loop.ownerName.isEmpty ? 'Me' : loop.ownerName
      ..isMyClaim = loop.isMyClaim;
    return local;
  }

  /// Migrate old JSON data to Isar if it exists
  Future<void> _migrateJsonToIsar(Isar isar) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final docsFile = File('${docsDir.path}/claimed_loops.json');
      
      if (await docsFile.exists()) {
        final jsonStr = await docsFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        final List<ClaimedLoop> oldLoops = jsonList.map((item) => ClaimedLoop.fromJson(item)).toList();
        
        final List<LocalClaimedLoop> localLoops = oldLoops.map((l) => _toLocal(l)).toList();
        
        await isar.writeTxn(() async {
          await isar.localClaimedLoops.putAll(localLoops);
        });
        
        // Rename or delete JSON file to prevent re-migration
        await docsFile.delete();
        print("Successfully migrated ${localLoops.length} claimed loops from JSON to Isar.");
      }
    } catch (e) {
      print("JSON to Isar migration failed for claimed loops: $e");
    }
  }

  /// Get claimed loops, automatically checking streaks and pruning expired ones
  Future<List<ClaimedLoop>> getClaimedLoops() async {
    try {
      final isar = await IsarService.getDB();
      await _migrateJsonToIsar(isar);

      final localList = await isar.localClaimedLoops.where().findAll();
      final List<ClaimedLoop> list = localList.map((l) => _toClaimedLoop(l)).toList();

      final today = getTodayDateString();
      bool changed = false;
      final List<ClaimedLoop> prunedList = [];
      final List<LocalClaimedLoop> localUpdates = [];
      final List<int> localDeletes = [];

      for (int i = 0; i < list.length; i++) {
        final loop = list[i];
        final localItem = localList[i];
        
        if (loop.lastCoveredDate != today && loop.coveredCountToday > 0) {
          // Reset daily count for the new day
          final updated = loop.copyWith(coveredCountToday: 0);
          prunedList.add(updated);
          localUpdates.add(_toLocal(updated)..id = localItem.id);
          changed = true;
        } else {
          prunedList.add(loop);
        }
      }

      if (changed) {
        await isar.writeTxn(() async {
          if (localUpdates.isNotEmpty) {
            await isar.localClaimedLoops.putAll(localUpdates);
          }
          if (localDeletes.isNotEmpty) {
            for (var id in localDeletes) {
              await isar.localClaimedLoops.delete(id);
            }
          }
        });
      }

      return prunedList;
    } catch (e) {
      print("Error reading claimed loops from Isar: $e");
      return [];
    }
  }

  /// Save or batch-update a list of claimed loops in Isar
  Future<void> saveClaimedLoops(List<ClaimedLoop> loops) async {
    try {
      final isar = await IsarService.getDB();
      
      await isar.writeTxn(() async {
        // Clear existing and replace
        await isar.localClaimedLoops.clear();
        final localList = loops.map((l) => _toLocal(l)).toList();
        await isar.localClaimedLoops.putAll(localList);
      });
    } catch (e) {
      print("Error saving claimed loops to Isar: $e");
    }
  }

  /// Add or update a single claimed loop in local Isar database
  Future<void> addOrUpdateClaimedLoop(ClaimedLoop loop) async {
    try {
      final isar = await IsarService.getDB();
      
      // Check if loop already exists by loopId
      final existing = await isar.localClaimedLoops.filter().loopIdEqualTo(loop.id).findFirst();
      
      final localItem = _toLocal(loop);
      if (existing != null) {
        localItem.id = existing.id; // Retain Isar primary key to perform update
      }
      
      await isar.writeTxn(() async {
        await isar.localClaimedLoops.put(localItem);
      });
    } catch (e) {
      print("Error adding/updating claimed loop in Isar: $e");
    }
  }

  /// Remove a claimed loop from Isar (abandon claim)
  Future<void> deleteClaim(String loopId) async {
    try {
      final isar = await IsarService.getDB();
      final existing = await isar.localClaimedLoops.filter().loopIdEqualTo(loopId).findFirst();
      if (existing != null) {
        await isar.writeTxn(() async {
          await isar.localClaimedLoops.delete(existing.id);
        });
      }
    } catch (e) {
      print("Error deleting claim in Isar: $e");
    }
  }
}
