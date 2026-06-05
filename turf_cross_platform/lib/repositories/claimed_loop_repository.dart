import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/claimed_loop.dart';

class ClaimedLoopRepository {
  Future<File> _getFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final docsFile = File('${docsDir.path}/claimed_loops.json');

    if (!await docsFile.exists()) {
      try {
        final supportDir = await getApplicationSupportDirectory();
        final supportFile = File('${supportDir.path}/claimed_loops.json');
        if (await supportFile.exists()) {
          await supportFile.copy(docsFile.path);
        }
      } catch (e) {
        print("Migration of claimed_loops.json failed: $e");
      }
    }

    return docsFile;
  }

  /// Helper to get Date string formatted as yyyy-MM-dd
  static String getDateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String getTodayDateString() => getDateString(DateTime.now());
  static String getYesterdayDateString() => getDateString(DateTime.now().subtract(const Duration(days: 1)));

  /// Get claimed loops, automatically applying streak-checking and pruning
  Future<List<ClaimedLoop>> getClaimedLoops() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<ClaimedLoop> list = jsonList.map((item) => ClaimedLoop.fromJson(item)).toList();

      final today = getTodayDateString();
      final yesterday = getYesterdayDateString();
      bool changed = false;
      final List<ClaimedLoop> prunedList = [];

      for (var loop in list) {
        if (loop.lastCoveredDate == today) {
          prunedList.add(loop);
        } else if (loop.lastCoveredDate == yesterday) {
          if (loop.coveredCountToday > 0) {
            // New day has started, reset covered count today
            prunedList.add(loop.copyWith(coveredCountToday: 0));
            changed = true;
          } else {
            prunedList.add(loop);
          }
        } else {
          // Expired claim (lost streak!) - do not add to prunedList
          changed = true;
        }
      }

      if (changed) {
        await saveClaimedLoops(prunedList);
      }

      return prunedList;
    } catch (e) {
      print("Error reading claimed loops: $e");
      return [];
    }
  }

  /// Write claimed loops directly to storage
  Future<void> saveClaimedLoops(List<ClaimedLoop> loops) async {
    try {
      final file = await _getFile();
      final jsonEncoder = const JsonEncoder.withIndent('  ');
      final serializedList = loops.map((l) => l.toJson()).toList();
      await file.writeAsString(jsonEncoder.convert(serializedList));
    } catch (e) {
      print("Error saving claimed loops: $e");
    }
  }

  /// Add or update a claimed loop in local storage
  Future<void> addOrUpdateClaimedLoop(ClaimedLoop loop) async {
    try {
      final current = await getClaimedLoops();
      final index = current.indexWhere((l) => l.id == loop.id);
      if (index != -1) {
        current[index] = loop;
      } else {
        current.add(loop);
      }
      await saveClaimedLoops(current);
    } catch (e) {
      print("Error adding/updating claimed loop: $e");
    }
  }

  /// Remove a claimed loop from local storage (abandon claim)
  Future<void> deleteClaim(String loopId) async {
    try {
      final current = await getClaimedLoops();
      final updated = current.where((l) => l.id != loopId).toList();
      await saveClaimedLoops(updated);
    } catch (e) {
      print("Error deleting claim: $e");
    }
  }
}
