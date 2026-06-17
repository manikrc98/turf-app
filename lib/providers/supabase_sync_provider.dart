import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:isar/isar.dart';

import '../constants/auth_constants.dart';
import '../models/claimed_loop.dart';
import '../models/walk_session_summary.dart';
import '../models/local_walk_session.dart';
import '../models/local_claimed_loop.dart';
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

  /// Returns true if the user is authenticated via a Google account (has email or google provider identity)
  bool get isGoogleUser {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return false;
      
      final providers = user.appMetadata['providers'] as List<dynamic>? ?? [];
      if (providers.contains('google')) return true;
      if (user.email != null && user.email!.isNotEmpty) return true;
    } catch (_) {}
    return false;
  }

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
        _initialized = true;
        _isSyncing = false;
        notifyListeners();
        return;
      }

      var session = client.auth.currentSession;
      
      // If no session exists, sign in anonymously to establish guest mode
      if (session == null) {
        try {
          final res = await client.auth.signInAnonymously();
          session = res.session;
        } catch (e) {
          print("Failed to sign in anonymously: $e");
        }
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
          final String genUsername = "User_${_currentUserId!.substring(0, 5)}";
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

      // Pull latest claims and history from Supabase if online
      if (_currentUserId != null) {
        await pullClaims();
        await pullHistory();
        await syncUnsyncedWalkSessions();
        await syncUnsyncedClaims();
      }
    } catch (e) {
      print("Supabase Initialize & Auth error: $e");
      _initialized = true;
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Pull all claims globally or within a radius of the specified center and save them to local Isar DB
  Future<void> pullClaims({LatLng? center}) async {
    if (_currentUserId == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final client = Supabase.instance.client;
      List<dynamic> claimsData = [];

      LatLng? syncCenter = center;
      if (syncCenter == null) {
        try {
          final pos = await Geolocator.getLastKnownPosition();
          if (pos != null) {
            syncCenter = LatLng(pos.latitude, pos.longitude);
          }
        } catch (e) {
          print("Could not get last known position for sync: $e");
        }
      }

      if (syncCenter != null) {
        // Fetch loops within 10km (10000m) radius using optimized PostGIS RPC
        final res = await client.rpc('get_loops_in_radius', params: {
          'p_lat': syncCenter.latitude,
          'p_lng': syncCenter.longitude,
          'p_radius_meters': 10000.0,
        });
        if (res != null) {
          claimsData = res as List<dynamic>;
        }
      } else {
        // Fallback global fetch if no location context is available
        claimsData = await client
            .from('claims')
            .select('*, loops(*), profiles(username)');
      }

      final List<ClaimedLoop> globalClaimsList = [];

      for (var row in claimsData) {
        final Map<String, dynamic> claimRow = (row is Map && row.containsKey('data'))
            ? row['data'] as Map<String, dynamic>
            : row as Map<String, dynamic>;

        final loopData = claimRow['loops'];
        final profileData = claimRow['profiles'];
        
        if (loopData == null) continue;

        // Parse points from PostGIS Polygon (can be returned as WKT String or GeoJSON Map)
        final dynamic geomData = loopData['geom'];
        if (geomData == null) continue;

        final List<LatLng> points = parseGeometry(geomData);
        if (points.isEmpty) continue;

        final String loopId = claimRow['loop_id'] as String;
        final String name = loopData['name'] as String;
        final int streak = (claimRow['streak_count'] as int?) ?? 0;
        final String lastCovered = (claimRow['last_covered_date'] as String?) ?? '';
        final int coveredToday = (claimRow['covered_count_today'] as int?) ?? 0;
        
        final String ownerId = (claimRow['user_id'] as String?) ?? "";
        final String ownerName = (profileData != null) ? profileData['username'] as String : "Unclaimed";
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
      await _claimedLoopRepo.saveClaimedLoops(globalClaimsList, _currentUserId!);

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      print("Supabase pullClaims error: $e");
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Pull all walk sessions from Supabase and save them to local Isar DB
  Future<void> pullHistory() async {
    if (_currentUserId == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final client = Supabase.instance.client;
      final response = await client
          .from('walk_sessions')
          .select('*')
          .order('created_at', ascending: true);

      final List<LocalWalkSession> localSessions = [];

      for (var row in response) {
        final String sessionId = row['id'] as String;
        final int steps = (row['steps'] as int?) ?? 0;
        final double distanceKm = (row['distance_km'] as num?)?.toDouble() ?? 0.0;
        final int durationSeconds = (row['duration_seconds'] as int?) ?? 0;
        final int cadence = (row['cadence'] as int?) ?? 0;
        final double elevationGainMetres = (row['elevation_gain_metres'] as num?)?.toDouble() ?? 0.0;
        final String createdAt = row['created_at'] as String;
        final dynamic geomData = row['geom'];

        final List<LatLng> points = parseGeometry(geomData);
        final List<double> trailLatList = points.map((p) => p.latitude).toList();
        final List<double> trailLngList = points.map((p) => p.longitude).toList();
        final int loopCount = (row['loop_count'] as int?) ?? 0;
        final String loopsJson = row['loops_json'] as String? ?? "";

        final local = LocalWalkSession()
          ..sessionId = sessionId
          ..userId = _currentUserId!
          ..dateTime = formatDateTimeString(createdAt)
          ..steps = steps
          ..isStepEstimated = false
          ..distanceKm = distanceKm
          ..loopCount = loopCount
          ..durationSeconds = durationSeconds
          ..cadence = cadence
          ..elevationGainMetres = elevationGainMetres
          ..trailLatList = trailLatList
          ..trailLngList = trailLngList
          ..loopsJson = loopsJson
          ..isSynced = true;

        localSessions.add(local);
      }

      // Save to local Isar DB
      final isar = await IsarService.getDB();
      await isar.writeTxn(() async {
        // Query unsynced walk sessions for this user to preserve them
        final unsynced = await isar.localWalkSessions
            .filter()
            .userIdEqualTo(_currentUserId!)
            .isSyncedEqualTo(false)
            .findAll();

        // Clear existing local walk sessions for this user (except active walk)
        final activeWalk = await isar.localWalkSessions.get(99999);
        await isar.localWalkSessions.filter().userIdEqualTo(_currentUserId!).deleteAll();
        
        if (activeWalk != null) {
          await isar.localWalkSessions.put(activeWalk);
        }
        if (unsynced.isNotEmpty) {
          await isar.localWalkSessions.putAll(unsynced);
        }
        if (localSessions.isNotEmpty) {
          await isar.localWalkSessions.putAll(localSessions);
        }
      });

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      print("Supabase pullHistory error: $e");
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
        LatLng? centroid;
        if (points.isNotEmpty) {
          double sumLat = 0;
          double sumLng = 0;
          for (var pt in points) {
            sumLat += pt.latitude;
            sumLng += pt.longitude;
          }
          centroid = LatLng(sumLat / points.length, sumLng / points.length);
        }

        // Pull latest updates to refresh the map and cache around the claimed loop
        await pullClaims(center: centroid);
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
        'loop_count': summary.loopCount,
        'loops_json': jsonEncode(summary.loops.map((l) => l.toJson()).toList()),
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

  /// Parses a geometry object (WKT String or GeoJSON Map) into List<LatLng>
  static List<LatLng> parseGeometry(dynamic geom) {
    if (geom == null) return [];
    if (geom is String) {
      if (geom.toUpperCase().startsWith("LINESTRING")) {
        return parseWktLineString(geom);
      }
      return parseWktPolygon(geom);
    }
    if (geom is Map) {
      try {
        final type = geom['type'] as String?;
        if (type == 'Polygon') {
          final coords = geom['coordinates'] as List<dynamic>?;
          if (coords != null && coords.isNotEmpty) {
            final ring = coords[0] as List<dynamic>;
            final List<LatLng> points = [];
            for (var pt in ring) {
              if (pt is List<dynamic> && pt.length >= 2) {
                final double lng = (pt[0] as num).toDouble();
                final double lat = (pt[1] as num).toDouble();
                points.add(LatLng(lat, lng));
              }
            }
            return points;
          }
        } else if (type == 'LineString') {
          final coords = geom['coordinates'] as List<dynamic>?;
          if (coords != null) {
            final List<LatLng> points = [];
            for (var pt in coords) {
              if (pt is List<dynamic> && pt.length >= 2) {
                final double lng = (pt[0] as num).toDouble();
                final double lat = (pt[1] as num).toDouble();
                points.add(LatLng(lat, lng));
              }
            }
            return points;
          }
        }
      } catch (e) {
        print("Failed parsing GeoJSON geometry: $e");
      }
    }
    return [];
  }

  /// Parses a WKT LINESTRING string into List<LatLng>
  static List<LatLng> parseWktLineString(String wkt) {
    try {
      // e.g. "LINESTRING(lng1 lat1, lng2 lat2, ...)"
      String clean = wkt.toUpperCase().replaceFirst("LINESTRING", "").trim();
      clean = clean.replaceAll("(", "").replaceAll(")", "");
      
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
      print("Failed parsing WKT linestring: $e");
      return [];
    }
  }

  /// Format an ISO date-time string (or fallback) to user-friendly walk session display string.
  static String formatDateTimeString(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final mStr = months[parsed.month - 1];
      final dStr = parsed.day.toString().padLeft(2, '0');
      final yStr = parsed.year.toString();
      final hStr = parsed.hour.toString().padLeft(2, '0');
      final minStr = parsed.minute.toString().padLeft(2, '0');
      return '$mStr $dStr, $yStr $hStr:$minStr';
    } catch (_) {
      return dateStr;
    }
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


  /// Sign in with Google ID and link previous anonymous data if present
  Future<bool> signInWithGoogle() async {
    try {
      _isSyncing = true;
      notifyListeners();

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: AuthConstants.googleIosClientId.contains('YOUR_GOOGLE_IOS_CLIENT_ID')
            ? null
            : AuthConstants.googleIosClientId,
        serverClientId: AuthConstants.googleWebClientId.contains('YOUR_GOOGLE_WEB_CLIENT_ID')
            ? null
            : AuthConstants.googleWebClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final client = Supabase.instance.client;
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final session = response.session;
      if (session != null && session.user != null) {
        final oldUserId = _currentUserId;
        _currentUserId = session.user.id;
        
        final String displayName = googleUser.displayName ?? "Turfer";
        final String? avatarUrl = googleUser.photoUrl;

        // Ensure profile exists in profiles table
        final profileRes = await client
            .from('profiles')
            .select('username')
            .eq('id', _currentUserId!)
            .maybeSingle();

        if (profileRes == null) {
          await client.from('profiles').insert({
            'id': _currentUserId,
            'username': displayName,
            'avatar_url': avatarUrl,
          });
          _currentUsername = displayName;
        } else {
          _currentUsername = profileRes['username'] as String?;
        }

        // If transitioning from an anonymous guest session, merge the data!
        if (oldUserId != null && oldUserId != _currentUserId) {
          await linkAnonymousData(oldUserId);
        }
      }

      _initialized = true;
      _isSyncing = false;
      notifyListeners();

      await pullClaims();
      await pullHistory();
      await syncUnsyncedWalkSessions();
      return true;
    } catch (e) {
      print("Google sign in failed: $e");
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Trigger anonymous data linking RPC and migrate local Isar cache
  Future<void> linkAnonymousData(String oldUserId) async {
    try {
      final client = Supabase.instance.client;
      await client.rpc('link_anonymous_data', params: {
        'p_old_user_id': oldUserId,
      });
      print("Successfully linked anonymous user data to new account.");

      // Migrate local Isar records from oldUserId to _currentUserId
      if (_currentUserId != null) {
        final isar = await IsarService.getDB();
        await isar.writeTxn(() async {
          // Migrate walk sessions
          final localWalks = await isar.localWalkSessions.filter().userIdEqualTo(oldUserId).findAll();
          for (var walk in localWalks) {
            walk.userId = _currentUserId!;
          }
          if (localWalks.isNotEmpty) {
            await isar.localWalkSessions.putAll(localWalks);
          }

          // Migrate claimed loops
          final localClaims = await isar.localClaimedLoops.filter().userIdEqualTo(oldUserId).findAll();
          for (var claim in localClaims) {
            claim.userId = _currentUserId!;
          }
          if (localClaims.isNotEmpty) {
            await isar.localClaimedLoops.putAll(localClaims);
          }
        });
        print("Successfully migrated local Isar cached data to new user ID.");
      }
    } catch (e) {
      print("Failed to link anonymous data: $e");
    }
  }

  /// Sign out, clear local cache, and restore anonymous Guest Mode
  Future<void> signOut() async {
    try {
      _isSyncing = true;
      notifyListeners();

      final client = Supabase.instance.client;
      await client.auth.signOut();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      // Clear local claims from Isar for the current user
      if (_currentUserId != null) {
        await _claimedLoopRepo.saveClaimedLoops([], _currentUserId!);
      }

      // Clear local walk sessions from Isar for the current user
      final isar = await IsarService.getDB();
      await isar.writeTxn(() async {
        if (_currentUserId != null) {
          await isar.localWalkSessions.filter().userIdEqualTo(_currentUserId!).deleteAll();
        }
      });

      _currentUserId = null;
      _currentUsername = null;
      _initialized = false;
      _isSyncing = false;
      notifyListeners();

      // Log back in anonymously to restore guest mode
      await initializeAndAuth();
    } catch (e) {
      print("Sign out failed: $e");
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Upload offline sessions saved in Isar to Supabase
  Future<void> syncUnsyncedWalkSessions() async {
    if (_currentUserId == null) return;
    try {
      final isar = await IsarService.getDB();
      final unsynced = await isar.localWalkSessions
          .filter()
          .userIdEqualTo(_currentUserId!)
          .isSyncedEqualTo(false)
          .findAll();
      
      if (unsynced.isEmpty) return;
      
      final client = Supabase.instance.client;
      for (var session in unsynced) {
        if (session.id == 99999) continue; // Skip active session record
        
        // Extract geometry WKT if coordinates are present
        String? geomWkt;
        if (session.trailLatList.isNotEmpty) {
          final List<LatLng> pts = [];
          for (int i = 0; i < session.trailLatList.length; i++) {
            pts.add(LatLng(session.trailLatList[i], session.trailLngList[i]));
          }
          geomWkt = toWktLineString(pts);
        }

        await client.from('walk_sessions').insert({
          'user_id': _currentUserId,
          'steps': session.steps,
          'distance_km': session.distanceKm,
          'duration_seconds': session.durationSeconds,
          'cadence': session.cadence,
          'elevation_gain_metres': session.elevationGainMetres,
          'geom': geomWkt,
          'loop_count': session.loopCount,
          'loops_json': session.loopsJson,
          'created_at': session.dateTime,
        });

        // Mark as synced
        session.isSynced = true;
      }

      await isar.writeTxn(() async {
        await isar.localWalkSessions.putAll(unsynced);
      });
      print("Synced ${unsynced.length} offline walk sessions to Supabase.");
    } catch (e) {
      print("Failed to sync unsynced sessions: $e");
    }
  }

  /// Sync offline-captured claims outbox to Supabase
  Future<void> syncUnsyncedClaims() async {
    if (_currentUserId == null) return;
    try {
      final isar = await IsarService.getDB();
      final unsynced = await isar.localClaimedLoops
          .filter()
          .userIdEqualTo(_currentUserId!)
          .isSyncedEqualTo(false)
          .findAll();

      if (unsynced.isEmpty) return;

      final client = Supabase.instance.client;
      for (var claim in unsynced) {
        final List<LatLng> points = [];
        for (int i = 0; i < claim.latList.length; i++) {
          points.add(LatLng(claim.latList[i], claim.lngList[i]));
        }
        final wktPolygon = toWktPolygon(points);

        final res = await client.rpc('claim_loop_attempt', params: {
          'p_user_id': _currentUserId,
          'p_trail_coords': wktPolygon,
          'p_default_name': claim.name,
        });

        if (res != null && res['success'] == true) {
          claim.isSynced = true;
          if (res['loop_id'] != null) {
            claim.loopId = res['loop_id'] as String;
          }
        }
      }

      await isar.writeTxn(() async {
        await isar.localClaimedLoops.putAll(unsynced);
      });
      print("Synced ${unsynced.length} offline claims to Supabase.");
    } catch (e) {
      print("Failed to sync offline claims: $e");
    }
  }
}
