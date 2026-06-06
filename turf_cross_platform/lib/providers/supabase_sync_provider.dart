import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/claimed_loop.dart';
import '../models/walk_session_summary.dart';
import '../repositories/claimed_loop_repository.dart';
import '../repositories/isar_service.dart';

class SupabaseSyncProvider extends ChangeNotifier {
  final ClaimedLoopRepository _claimedLoopRepo = ClaimedLoopRepository();
  
  bool _initialized = false;
  bool _isSyncing = false;
  String? _currentUserId;
  String? _currentUsername;

  bool get initialized => _initialized;
  bool get isSyncing => _isSyncing;
  String? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUsername;

  /// Initialize Supabase authentication anonymously and fetch profile details
  Future<void> initializeAndAuth() async {
    if (_initialized) return;

    try {
      _isSyncing = true;
      notifyListeners();

      // Safe check if Supabase is initialized
      SupabaseClient client;
      try {
        client = Supabase.instance.client;
      } catch (e) {
        print("Supabase is not initialized. Operating in offline-first local mode. $e");
        _initialized = false;
        _isSyncing = false;
        notifyListeners();
        return;
      }

      var session = client.auth.currentSession;
      
      if (session == null) {
        // Sign in anonymously
        final response = await client.auth.signInAnonymously();
        session = response.session;
      }

      if (session != null && session.user != null) {
        _currentUserId = session.user.id;
        
        // Ensure profile exists in profiles table
        final profileRes = await client
            .from('profiles')
            .select('username')
            .eq('id', _currentUserId!)
            .maybeSingle();

        if (profileRes == null) {
          // Generate a random username
          final randNum = Random().nextInt(9000) + 1000;
          final genUsername = "Turfer_$randNum";

          await client.from('profiles').insert({
            'id': _currentUserId,
            'username': genUsername,
          });
          _currentUsername = genUsername;
        } else {
          _currentUsername = profileRes['username'] as String?;
        }
      }

      _initialized = true;
      _isSyncing = false;
      notifyListeners();

      // Pull latest claims from Supabase
      await pullClaims();
    } catch (e) {
      print("Supabase Initialize & Auth error: $e");
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Pull all claims globally and save them to local Isar DB
  Future<void> pullClaims() async {
    if (_currentUserId == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final client = Supabase.instance.client;
      // Fetch claims joined with profiles (owner details) and loops (geometries)
      final List<dynamic> claimsData = await client
          .from('claims')
          .select('*, loops(*), profiles(username)');

      final List<ClaimedLoop> globalClaimsList = [];

      for (var row in claimsData) {
        final loopData = row['loops'];
        final profileData = row['profiles'];
        
        if (loopData == null) continue;

        // Parse points from PostGIS Polygon string e.g. "POLYGON((lng1 lat1, lng2 lat2, ...))"
        final String? geomWkt = loopData['geom'] as String?;
        if (geomWkt == null) continue;

        final List<LatLng> points = parseWktPolygon(geomWkt);
        if (points.isEmpty) continue;

        final String loopId = row['loop_id'] as String;
        final String name = loopData['name'] as String;
        final int streak = row['streak_count'] as int;
        final String lastCovered = row['last_covered_date'] as String;
        final int coveredToday = row['covered_count_today'] as int;
        
        final String ownerId = row['user_id'] as String;
        final String ownerName = (profileData != null) ? profileData['username'] as String : "Player";
        final bool isMyClaim = ownerId == _currentUserId;

        globalClaimsList.add(
          ClaimedLoop(
            id: loopId,
            name: name,
            points: points,
            streakCount: streak,
            lastCoveredDate: lastCovered,
            coveredCountToday: coveredToday,
            ownerId: ownerId,
            ownerName: ownerName,
            isMyClaim: isMyClaim,
          ),
        );
      }

      // Save to local Isar DB
      await _claimedLoopRepo.saveClaimedLoops(globalClaimsList);

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      print("Supabase pullClaims error: $e");
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Attempt to upload a loop capture/claim to the backend
  Future<Map<String, dynamic>?> attemptClaimLoop(List<LatLng> points, String defaultName) async {
    if (_currentUserId == null) return null;

    try {
      final wktPolygon = toWktPolygon(points);
      final client = Supabase.instance.client;

      final res = await client.rpc('claim_loop_attempt', params: {
        'p_user_id': _currentUserId,
        'p_trail_coords': wktPolygon,
        'p_default_name': defaultName,
      });

      if (res != null && res['success'] == true) {
        // Pull latest updates to refresh the map and cache
        await pullClaims();
        return res as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Supabase claim attempt failed: $e");
      return null;
    }
  }

  /// Upload completed walk sessions to Supabase history
  Future<void> syncCompletedWalk(WalkSessionSummary summary) async {
    if (_currentUserId == null) return;

    try {
      final client = Supabase.instance.client;

      // Extract geometry as LineString WKT if coordinates are present
      String? geomWkt;
      if (summary.loops.isNotEmpty) {
        // Using loops centroid or all loops path combined
        final List<LatLng> allPts = summary.loops.expand((l) => l.points).toList();
        if (allPts.isNotEmpty) {
          geomWkt = toWktLineString(allPts);
        }
      }

      await client.from('walk_sessions').insert({
        'user_id': _currentUserId,
        'steps': summary.steps,
        'distance_km': summary.distanceKm,
        'duration_seconds': summary.durationSeconds,
        'cadence': summary.cadence,
        'elevation_gain_metres': summary.elevationGainMetres,
        'geom': geomWkt,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Supabase walk session sync failed: $e");
    }
  }

  // WKT Geospatial Helpers

  /// Converts a List of LatLng to WKT POLYGON representation
  static String toWktPolygon(List<LatLng> points) {
    if (points.isEmpty) return '';
    final coords = points.map((p) => '${p.longitude} ${p.latitude}').join(', ');
    final first = '${points.first.longitude} ${points.first.latitude}';
    return 'POLYGON(($coords, $first))'; // PostGIS requires closed loops
  }

  /// Converts a List of LatLng to WKT LINESTRING representation
  static String toWktLineString(List<LatLng> points) {
    if (points.isEmpty) return '';
    return 'LINESTRING(${points.map((p) => '${p.longitude} ${p.latitude}').join(', ')})';
  }

  /// Parses a WKT POLYGON string into List<LatLng>
  static List<LatLng> parseWktPolygon(String wkt) {
    try {
      // e.g. "POLYGON((lng1 lat1, lng2 lat2, ...))"
      String clean = wkt.toUpperCase().replaceFirst("POLYGON", "").trim();
      // Remove double parentheses
      clean = clean.replaceAll("((", "").replaceAll("))", "").replaceAll("(", "").replaceAll(")", "");
      
      final List<String> coordStrings = clean.split(",");
      final List<LatLng> points = [];
      
      for (var coordStr in coordStrings) {
        final parts = coordStr.trim().split(" ");
        if (parts.length >= 2) {
          final double lng = double.parse(parts[0]);
          final double lat = double.parse(parts[1]);
          points.add(LatLng(lat, lng));
        }
      }
      
      return points;
    } catch (e) {
      print("Failed parsing WKT polygon: $e");
      return [];
    }
  }
}
