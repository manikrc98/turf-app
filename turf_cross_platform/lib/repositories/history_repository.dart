import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/walk_session_summary.dart';

class HistoryRepository {
  Future<File> _getFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final docsFile = File('${docsDir.path}/walk_history.json');

    if (!await docsFile.exists()) {
      try {
        final supportDir = await getApplicationSupportDirectory();
        final supportFile = File('${supportDir.path}/walk_history.json');
        if (await supportFile.exists()) {
          await supportFile.copy(docsFile.path);
        }
      } catch (e) {
        print("Migration of walk_history.json failed: $e");
      }
    }

    return docsFile;
  }

  /// Get walk sessions list from local storage, in reverse chronological order
  Future<List<WalkSessionSummary>> getHistory() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final history = jsonList.map((item) => WalkSessionSummary.fromJson(item)).toList();
      
      // Return reversed list to match Kotlin's historyList.reversed()
      return history.reversed.toList();
    } catch (e) {
      print("Error reading walk history: $e");
      return [];
    }
  }

  /// Add a new walk session to history
  Future<void> addSession(WalkSessionSummary session) async {
    try {
      final file = await _getFile();
      
      // Read current history in chronological order (unreversed)
      List<WalkSessionSummary> currentHistory = [];
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        currentHistory = jsonList.map((item) => WalkSessionSummary.fromJson(item)).toList();
      }
      
      // Append the new session
      currentHistory.add(session);
      
      // Write back to storage
      final jsonEncoder = const JsonEncoder.withIndent('  ');
      final serializedList = currentHistory.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncoder.convert(serializedList));
    } catch (e) {
      print("Error writing walk session: $e");
    }
  }

  /// Clear session history
  Future<void> clearHistory() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error clearing walk history: $e");
    }
  }
}
