import 'dart:convert';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/walk_session_summary.dart';
import '../models/local_walk_session.dart';
import '../models/turf_loop.dart';
import 'isar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryRepository {
  
  /// Converts an Isar LocalWalkSession to UI model WalkSessionSummary
  WalkSessionSummary _toSummary(LocalWalkSession local) {
    List<TurfLoop> sessionLoops = [];
    if (local.loopsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(local.loopsJson);
        sessionLoops = decoded.map((l) => TurfLoop.fromJson(l)).toList();
      } catch (e) {
        print("Failed to decode loopsJson from Isar session: $e");
      }
    }

    final List<LatLng> trail = [];
    for (int i = 0; i < local.trailLatList.length; i++) {
      trail.add(LatLng(local.trailLatList[i], local.trailLngList[i]));
    }

    return WalkSessionSummary(
      id: local.sessionId,
      dateTime: local.dateTime,
      steps: local.steps,
      isStepEstimated: local.isStepEstimated,
      distanceKm: local.distanceKm,
      loopCount: local.loopCount,
      durationSeconds: local.durationSeconds,
      loops: sessionLoops,
      cadence: local.cadence,
      elevationGainMetres: local.elevationGainMetres,
      trailPoints: trail,
    );
  }

  /// Converts a UI WalkSessionSummary to Isar LocalWalkSession
  LocalWalkSession _toLocal(WalkSessionSummary summary, String userId) {
    final local = LocalWalkSession()
      ..sessionId = summary.id
      ..userId = userId
      ..dateTime = summary.dateTime
      ..steps = summary.steps
      ..isStepEstimated = summary.isStepEstimated
      ..distanceKm = summary.distanceKm
      ..loopCount = summary.loopCount
      ..durationSeconds = summary.durationSeconds
      ..cadence = summary.cadence
      ..elevationGainMetres = summary.elevationGainMetres
      ..trailLatList = summary.trailPoints.map((p) => p.latitude).toList()
      ..trailLngList = summary.trailPoints.map((p) => p.longitude).toList()
      ..loopsJson = jsonEncode(summary.loops.map((l) => l.toJson()).toList())
      ..isSynced = false;
    return local;
  }

  /// Migrate old JSON data to Isar if it exists
  Future<void> _migrateJsonToIsar(Isar isar, String currentUserId) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final docsFile = File('${docsDir.path}/walk_history.json');
      
      if (await docsFile.exists()) {
        final jsonStr = await docsFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        final List<WalkSessionSummary> oldHistory = jsonList.map((item) => WalkSessionSummary.fromJson(item)).toList();
        
        final List<LocalWalkSession> localHistory = oldHistory.map((s) => _toLocal(s, currentUserId)).toList();
        
        await isar.writeTxn(() async {
          await isar.localWalkSessions.putAll(localHistory);
        });
        
        // Rename or delete JSON file to prevent re-migration
        await docsFile.delete();
        print("Successfully migrated ${localHistory.length} walk sessions from JSON to Isar.");
      }
    } catch (e) {
      print("JSON to Isar migration failed for walk history: $e");
    }
  }

  /// Get walk sessions list from local storage, in reverse chronological order
  Future<List<WalkSessionSummary>> getHistory(String currentUserId) async {
    try {
      final isar = await IsarService.getDB();
      await _migrateJsonToIsar(isar, currentUserId);

      // Query sessions from database filtered by user ID
      final localSessions = await isar.localWalkSessions
          .filter()
          .userIdEqualTo(currentUserId)
          .findAll();
      final history = localSessions.map((s) => _toSummary(s)).toList();
      
      // Return reversed list to match Kotlin's historyList.reversed() (reverse chronological)
      return history.reversed.toList();
    } catch (e) {
      print("Error reading walk history from Isar: $e");
      return [];
    }
  }

  /// Add a new walk session to history
  Future<void> addSession(WalkSessionSummary session, String currentUserId) async {
    try {
      final isar = await IsarService.getDB();
      
      final localSession = _toLocal(session, currentUserId);
      await isar.writeTxn(() async {
        await isar.localWalkSessions.put(localSession);
      });
    } catch (e) {
      print("Error writing walk session to Isar: $e");
    }
  }

  /// Clear session history
  Future<void> clearHistory(String currentUserId) async {
    try {
      final isar = await IsarService.getDB();
      await isar.writeTxn(() async {
        await isar.localWalkSessions.filter().userIdEqualTo(currentUserId).deleteAll();
      });

      // Clear remote walk sessions in Supabase for the current user
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null && user.id == currentUserId) {
          await client.from('walk_sessions').delete().eq('user_id', user.id);
        }
      } catch (e) {
        print("Failed to clear remote walk history from Supabase: $e");
      }
    } catch (e) {
      print("Error clearing walk history in Isar: $e");
    }
  }

  /// Delete a single walk session from history
  Future<void> deleteSession(String sessionId) async {
    try {
      final isar = await IsarService.getDB();
      final existing = await isar.localWalkSessions.filter().sessionIdEqualTo(sessionId).findFirst();
      if (existing != null) {
        await isar.writeTxn(() async {
          await isar.localWalkSessions.delete(existing.id);
        });
      }

      // Try deleting from remote Supabase if online
      try {
        final client = Supabase.instance.client;
        if (client.auth.currentSession != null) {
          await client.from('walk_sessions').delete().eq('id', sessionId);
        }
      } catch (e) {
        print("Failed to delete walk session from Supabase: $e");
      }
    } catch (e) {
      print("Error deleting walk session in Isar: $e");
    }
  }
}
