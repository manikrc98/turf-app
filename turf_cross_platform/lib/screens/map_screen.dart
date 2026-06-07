import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/tracking_metrics_provider.dart';
import '../providers/location_tracking_provider.dart';
import '../providers/supabase_sync_provider.dart';
import '../models/session_status.dart';
import '../models/turf_loop.dart';
import '../models/claimed_loop.dart';
import '../models/local_walk_session.dart';
import '../repositories/isar_service.dart';
import 'history_bottom_sheet.dart';
import 'summary_bottom_sheet.dart';
import 'marker_generator.dart';
import 'package:isar/isar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  bool _permissionsGranted = false;
  bool _permissionDeniedPermanently = false;

  // Custom marker descriptors cached to prevent re-renders
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _dotIcon;
  double _currentZoom = 17.0;

  // Bottom Sheet height tracker for repositioning the FAB dynamically
  double _bottomSheetHeight = 140.0;
  final double _bottomSheetPeekHeight = 140.0;
  final double _bottomSheetMaxHeight = 350.0;

  // Stream Subscriptions
  StreamSubscription<TurfLoop>? _loopCapturedSubscription;
  StreamSubscription<ClaimedLoop>? _claimedLoopCoveredSubscription;
  StreamSubscription<Position>? _realtimeLocationSubscription;
  StreamSubscription<CompassEvent>? _realtimeCompassSubscription;

  // Real-time location and heading variables
  LatLng? _currentLocation;
  double _currentHeading = 0.0;
  bool _shouldFollowCamera = true;
  bool _isProgrammaticMovement = false;

  // Marker caching to avoid UI freezes during map rebuilds
  String _lastCacheStateKey = "";
  final Map<String, BitmapDescriptor> _cardMarkerCache = {};
  final Map<String, BitmapDescriptor> _textMarkerCache = {};

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInit();
  }

  Future<void> _checkPermissionsAndInit() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() {
        _permissionsGranted = true;
        _permissionDeniedPermanently = false;
      });
      _initAssets();
      _setupEventsListener();
      _startRealtimeTracking();
      _centerOnLastKnownLocation();
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionsGranted = false;
        _permissionDeniedPermanently = true;
      });
    } else {
      setState(() {
        _permissionsGranted = false;
      });
    }
  }

  Future<void> _initAssets() async {
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final userIcon = await MarkerGenerator.createUserPositionMarker(pixelRatio);
    final dotIcon = await MarkerGenerator.createDotMarker(pixelRatio);
    
    setState(() {
      _userIcon = userIcon;
      _dotIcon = dotIcon;
    });
  }

  void _setupEventsListener() {
    final provider = Provider.of<LocationTrackingProvider>(context, listen: false);

    // Listen for new loops captured (prompt user to name them)
    _loopCapturedSubscription = provider.loopCapturedEvents.listen((loop) {
      _showClaimLoopDialog(loop);
    });

    // Listen for streak updates on claimed loops and sync to Supabase
    _claimedLoopCoveredSubscription = provider.claimedLoopCoveredEvents.listen((claim) async {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Claimed Loop '${claim.name}' covered! 🔥 Streak: ${claim.streakCount} days (Covered ${claim.coveredCountToday} times today)",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);
      if (syncProvider.currentUserId != null) {
        await syncProvider.attemptClaimLoop(claim.points, claim.name);
        await provider.loadClaimedLoops();
      }
    });
  }

  Future<void> _centerOnLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        final controller = await _mapController.future;
        controller.moveCamera(
          CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 17.0),
        );
      } else {
        final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final controller = await _mapController.future;
        controller.moveCamera(
          CameraUpdate.newLatLngZoom(LatLng(currentPosition.latitude, currentPosition.longitude), 17.0),
        );
      }
    } catch (e) {
      print("Could not acquire initial camera location: $e");
    }
  }

  void _startRealtimeTracking() {
    _realtimeLocationSubscription?.cancel();
    _realtimeLocationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (mounted) {
        final newLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLatLng;
        });

        final provider = Provider.of<TrackingMetricsProvider>(context, listen: false);
        if (_shouldFollowCamera && provider.sessionStatus == SessionStatus.active) {
          _isProgrammaticMovement = true;
          _mapController.future.then((controller) {
            controller.animateCamera(CameraUpdate.newLatLng(newLatLng));
          });
        }
      }
    });

    _realtimeCompassSubscription?.cancel();
    _realtimeCompassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        final double? heading = event.heading;
        if (heading != null) {
          double normHeading = heading;
          if (normHeading < 0) normHeading += 360.0;
          setState(() {
            _currentHeading = normHeading;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _loopCapturedSubscription?.cancel();
    _claimedLoopCoveredSubscription?.cancel();
    _realtimeLocationSubscription?.cancel();
    _realtimeCompassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsGranted) {
      return _buildPermissionDeniedUI();
    }

    final trackingProvider = Provider.of<LocationTrackingProvider>(context);

    // Handle asynchronous pre-caching of loop markers when the database state changes
    final cacheKey = _getCacheStateKey(trackingProvider);
    if (cacheKey != _lastCacheStateKey) {
      _lastCacheStateKey = cacheKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preCacheMarkers(trackingProvider);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      drawer: _buildNavigationDrawer(trackingProvider),
      body: Stack(
        children: [
          // 1. Google Map View
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(0.0, 0.0),
              zoom: 17.0,
            ),
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            polylines: _buildPolylines(trackingProvider),
            polygons: _buildPolygons(trackingProvider),
            markers: _buildMarkersSync(trackingProvider),
            onMapCreated: (GoogleMapController controller) async {
              _mapController.complete(controller);
              // Load dark map style JSON from assets
              try {
                final styleStr = await rootBundle.loadString('assets/map_style.json');
                controller.setMapStyle(styleStr);
              } catch (e) {
                print("Error loading map style assets: $e");
              }
            },
            onCameraMoveStarted: () {
              if (!_isProgrammaticMovement) {
                _shouldFollowCamera = false;
              }
              _isProgrammaticMovement = false;
            },
            onCameraMove: (CameraPosition position) {
              _currentZoom = position.zoom;
            },
            onCameraIdle: () {
              // Trigger repaint when camera movement stops to apply zoom visibility filters
              setState(() {});
            },
          ),

          // 2. Map HUD Buttons (Drawer trigger)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.0,
            left: 16.0,
            child: Builder(
              builder: (context) => FloatingActionButton(
                backgroundColor: const Color(0xFF1E293B),
                mini: true,
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Icon(Icons.menu_rounded, color: Colors.white),
              ),
            ),
          ),

          // 3. Status chips (Paused walk / Weak GPS signal)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16.0,
            right: 16.0,
            child: Selector<TrackingMetricsProvider, SessionStatus>(
              selector: (_, p) => p.sessionStatus,
              builder: (context, status, _) {
                final isWeak = trackingProvider.gpsSignalWeak;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (status == SessionStatus.paused)
                      _buildStatusChip("WALK PAUSED", const Color(0xFFFF9800)),
                    if (isWeak && status == SessionStatus.active)
                      const SizedBox(height: 8),
                    if (isWeak && status == SessionStatus.active)
                      _buildStatusChip("WEAK GPS SIGNAL", const Color(0xFFF44336)),
                  ],
                );
              },
            ),
          ),

          // 4. Recenter FAB (Moves up dynamically when the bottom sheet is dragged open)
          Selector<TrackingMetricsProvider, SessionStatus>(
            selector: (_, p) => p.sessionStatus,
            builder: (context, status, _) {
              return Positioned(
                bottom: (status == SessionStatus.idle 
                    ? (95.0 + MediaQuery.of(context).padding.bottom) 
                    : _bottomSheetHeight) + 16.0,
                right: 16.0,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF2196F3),
                  onPressed: () async {
                    _shouldFollowCamera = true;
                    if (_currentLocation != null) {
                      _isProgrammaticMovement = true;
                      final controller = await _mapController.future;
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation!, 17.0),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location_rounded, color: Colors.white),
                ),
              );
            },
          ),

          // 5. Sliding Bottom Sheet
          _buildSlidingPanel(trackingProvider),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                "Permissions Required",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "TURF requires background location access to map your paths, calculate elevation, and count your steps.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _permissionDeniedPermanently
                    ? () => Geolocator.openAppSettings()
                    : _checkPermissionsAndInit,
                child: Text(_permissionDeniedPermanently ? "Open Settings" : "Grant Permissions"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 24 + MediaQuery.of(context).padding.top, 16, 20),
      color: const Color(0xFF0F172A),
      width: double.infinity,
      child: Consumer<SupabaseSyncProvider>(
        builder: (context, syncProv, _) {
          final bool isLoggedIn = syncProv.currentUserId != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF1E293B),
                    backgroundImage: isLoggedIn && syncProv.currentUsername != null
                        ? NetworkImage('https://api.dicebear.com/7.x/bottts/png?seed=${syncProv.currentUsername}')
                        : null,
                    child: !isLoggedIn
                        ? const Icon(Icons.account_circle, size: 56, color: Colors.white30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? (syncProv.currentUsername ?? "User") : "Guest Mode",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isLoggedIn ? "Signed in 🏆" : "Offline-first play",
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (syncProv.isSyncing)
                const SizedBox(
                  height: 36,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2196F3))),
                )
              else if (!isLoggedIn)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
                        label: const Text("Sign In with Google", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: () async {
                          final success = await syncProv.signInWithGoogle();
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Google Sign-In failed or cancelled.")),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 14),
                  label: const Text("Sign Out", style: TextStyle(fontSize: 11)),
                  onPressed: () => syncProv.signOut(),
                ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildNavigationDrawer(LocationTrackingProvider provider) {
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: Column(
        children: [
          _buildDrawerHeader(),
          ListTile(
            leading: const Icon(Icons.map_rounded, color: Colors.white70),
            title: const Text("Track Walk", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Colors.white70),
            title: const Text("Walk History", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              HistoryBottomSheet.show(context, () {
                setState(() {}); // Redraw map overlays when sheet closes
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            title: const Text("Version History", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showVersionHistoryDialog();
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.stars_rounded, color: Colors.amber),
            title: const Text("Claimed Loops", style: TextStyle(color: Colors.white)),
            iconColor: Colors.white70,
            collapsedIconColor: Colors.white54,
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              if (provider.cachedClaimedLoops.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("No claimed loops yet", style: TextStyle(color: Colors.white30, fontSize: 13)),
                )
              else
                ...provider.cachedClaimedLoops.map((claim) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(claim.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    subtitle: Text(claim.isMyClaim ? "Owned by me" : "Claimed by: ${claim.ownerName}", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 16),
                    onTap: () async {
                      Navigator.pop(context); // Close drawer
                      final centroid = _getCentroid(claim.points);
                      final controller = await _mapController.future;
                      _shouldFollowCamera = false;
                      _isProgrammaticMovement = true;
                      await controller.animateCamera(CameraUpdate.newLatLngZoom(centroid, 17.0));
                      _showClaimedLoopDetailDialog(claim);
                    },
                  );
                }).toList(),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _showVersionHistoryDialog();
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "TURF v1.6.0 (v6)",
                style: TextStyle(color: Colors.white30, fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCacheStateKey(LocationTrackingProvider provider) {
    final claimedPart = provider.cachedClaimedLoops
        .map((c) => "${c.id}_${c.streakCount}_${c.coveredCountToday}")
        .join(",");
    final capturedPart = provider.capturedLoops
        .map((l) => "${l.id}_${l.name ?? ''}")
        .join(",");
    return "$claimedPart|$capturedPart";
  }

  Future<void> _preCacheMarkers(LocationTrackingProvider provider) async {
    if (!mounted) return;
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    bool cacheUpdated = false;

    // Pre-cache claimed loops in provider.cachedClaimedLoops
    for (var claim in provider.cachedClaimedLoops) {
      final cacheKey = "${claim.id}_${claim.streakCount}_${claim.coveredCountToday}";
      if (!_cardMarkerCache.containsKey(cacheKey)) {
        try {
          final descriptor = await MarkerGenerator.createCardMarker(
            claim.name,
            claim.streakCount,
            claim.coveredCountToday,
            pixelRatio,
          );
          _cardMarkerCache[cacheKey] = descriptor;
          cacheUpdated = true;
        } catch (e) {
          print("Error pre-caching card marker for ${claim.name}: $e");
        }
      }
    }

    // Pre-cache active captured loops if they are renamed but not claimed yet
    for (var loop in provider.capturedLoops) {
      if (loop.name != null && loop.name!.isNotEmpty) {
        if (!_textMarkerCache.containsKey(loop.name!)) {
          try {
            final descriptor = await MarkerGenerator.createTextMarker(loop.name!, pixelRatio);
            _textMarkerCache[loop.name!] = descriptor;
            cacheUpdated = true;
          } catch (e) {
            print("Error pre-caching text marker for ${loop.name}: $e");
          }
        }
      }
    }

    if (cacheUpdated && mounted) {
      setState(() {});
    }
  }

  /// Construct live tracking markers synchronously using cached assets
  Set<Marker> _buildMarkersSync(LocationTrackingProvider provider) {
    final Set<Marker> markers = {};

    // 1. User Position marker
    final userPosition = _currentLocation ?? provider.trailPoints.lastOrNull;
    if (userPosition != null && _userIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("user_position"),
          position: userPosition,
          icon: _userIcon!,
          anchor: const Offset(0.5, 0.5),
          rotation: _currentHeading,
          flat: true,
          zIndex: 10,
        ),
      );
    }

    // 2. Claimed loop label statistics cards
    final zoomInEnough = _currentZoom >= 15.5;
    for (var loop in provider.capturedLoops) {
      final claimedIndex = provider.cachedClaimedLoops.indexWhere((c) => c.id == loop.id);
      if (claimedIndex != -1) {
        final claim = provider.cachedClaimedLoops[claimedIndex];
        final center = _getMarkerNorthOffset(loop.points);
        
        final cacheKey = "${claim.id}_${claim.streakCount}_${claim.coveredCountToday}";
        final cachedIcon = _cardMarkerCache[cacheKey];
        
        final icon = zoomInEnough
            ? (cachedIcon ?? _dotIcon) // Fallback to dot
            : _dotIcon;

        if (icon != null) {
          markers.add(
            Marker(
              markerId: MarkerId("captured_${loop.id}"),
              position: center,
              icon: icon,
              anchor: const Offset(0.5, 0.5),
              flat: true,
              onTap: () => _showClaimedLoopDetailDialog(claim),
            ),
          );
        }
      } else if (loop.name != null && loop.name!.isNotEmpty) {
        // Captured loop with custom name
        final center = _getCentroid(loop.points);
        if (zoomInEnough) {
          final cachedIcon = _textMarkerCache[loop.name!];
          final icon = cachedIcon ?? _dotIcon; // Fallback to dot
          if (icon != null) {
            markers.add(
              Marker(
                markerId: MarkerId("captured_${loop.id}"),
                position: center,
                icon: icon,
                anchor: const Offset(0.5, 0.5),
                flat: true,
                onTap: () => _showClaimLoopDialog(loop),
              ),
            );
          }
        }
      }
    }

    // 3. Historical claimed loop cards
    for (var claim in provider.cachedClaimedLoops) {
      if (provider.capturedLoops.any((l) => l.id == claim.id)) continue;

      final center = _getMarkerNorthOffset(claim.points);
      
      final cacheKey = "${claim.id}_${claim.streakCount}_${claim.coveredCountToday}";
      final cachedIcon = _cardMarkerCache[cacheKey];
      
      final icon = zoomInEnough
          ? (cachedIcon ?? _dotIcon) // Fallback to dot
          : _dotIcon;

      if (icon != null) {
        markers.add(
          Marker(
            markerId: MarkerId("claim_${claim.id}"),
            position: center,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            onTap: () => _showClaimedLoopDetailDialog(claim),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(LocationTrackingProvider provider) {
    final Set<Polyline> polylines = {};
    if (provider.trailPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId("active_trail"),
          points: provider.trailPoints,
          color: provider.activeTrailColor ?? const Color(0xFFE53935), // Red
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    return polylines;
  }

  Set<Polygon> _buildPolygons(LocationTrackingProvider provider) {
    final Set<Polygon> polygons = {};

    // Render active captured loops
    for (var loop in provider.capturedLoops) {
      final claimedIndex = provider.cachedClaimedLoops.indexWhere((c) => c.id == loop.id);
      Color color = const Color(0xFF4CAF50); // Unclaimed green
      if (claimedIndex != -1) {
        color = provider.cachedClaimedLoops[claimedIndex].getDynamicColor();
      }

      polygons.add(
        Polygon(
          polygonId: PolygonId("captured_poly_${loop.id}"),
          points: loop.points,
          fillColor: color.withOpacity(0.3),
          strokeColor: color.withOpacity(0.8),
          strokeWidth: 3,
          consumeTapEvents: true,
          onTap: () {
            if (claimedIndex != -1) {
              _showClaimedLoopDetailDialog(provider.cachedClaimedLoops[claimedIndex]);
            } else {
              _showClaimLoopDialog(loop);
            }
          },
        ),
      );
    }

    // Render historical claimed loop areas
    for (var claim in provider.cachedClaimedLoops) {
      if (provider.capturedLoops.any((l) => l.id == claim.id)) continue;

      final color = claim.getDynamicColor();
      polygons.add(
        Polygon(
          polygonId: PolygonId("claim_poly_${claim.id}"),
          points: claim.points,
          fillColor: color.withOpacity(0.3),
          strokeColor: color.withOpacity(0.8),
          strokeWidth: 3,
          consumeTapEvents: true,
          onTap: () => _showClaimedLoopDetailDialog(claim),
        ),
      );
    }

    return polygons;
  }

  Widget _buildSlidingPanel(LocationTrackingProvider locationProvider) {
    return Consumer<TrackingMetricsProvider>(
      builder: (context, metricsProvider, child) {
        final minutes = metricsProvider.durationSeconds ~/ 60;
        final seconds = metricsProvider.durationSeconds % 60;
        final durationStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
        final bool isIdle = metricsProvider.sessionStatus == SessionStatus.idle;

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragUpdate: isIdle
                ? null
                : (details) {
                    setState(() {
                      _bottomSheetHeight = (_bottomSheetHeight - details.delta.dy).clamp(_bottomSheetPeekHeight, _bottomSheetMaxHeight);
                    });
                  },
            child: Container(
              height: isIdle ? null : _bottomSheetHeight,
              padding: EdgeInsets.fromLTRB(
                20.0,
                12.0,
                20.0,
                MediaQuery.of(context).padding.bottom + 14.0,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B), // Premium Slate Dark
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isIdle) ...[
                      // Drag Notch (only visible when panel is expandable)
                      Center(
                        child: Container(
                          width: 36.0,
                          height: 4.0,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                    // Session Status Specific buttons
                    if (isIdle)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => locationProvider.startWalk(),
                          child: const Text("START WALK 🚶‍♂️", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      )
                    else ...[
                      // Metrics display row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricWidget("Steps", "${metricsProvider.steps}${metricsProvider.isStepEstimated ? ' (est)' : ''}"),
                          _buildMetricWidget("Distance", "${metricsProvider.distanceKm.toStringAsFixed(2)} km"),
                          _buildMetricWidget("Loops", "${metricsProvider.loopCount}"),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Extra Metrics row visible when sheet is expanded
                      if (_bottomSheetHeight > 220) ...[
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricWidget("Time", durationStr),
                            _buildMetricWidget("Cadence", "${metricsProvider.cadence} SPM"),
                            _buildMetricWidget("Elevation", "${metricsProvider.elevationGainMetres.toStringAsFixed(1)} m"),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Active control action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: metricsProvider.sessionStatus == SessionStatus.active ? Colors.grey[700] : const Color(0xFF2196F3),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                if (metricsProvider.sessionStatus == SessionStatus.active) {
                                  locationProvider.pauseWalk();
                                } else {
                                  locationProvider.resumeWalk();
                                }
                              },
                              child: Text(
                                metricsProvider.sessionStatus == SessionStatus.active ? "Pause" : "Resume",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                final controller = await _mapController.future;

                                // 1. Recenter/zoom to fit trail points bounds or user location before snapshot
                                if (locationProvider.trailPoints.isNotEmpty) {
                                  _isProgrammaticMovement = true;
                                  try {
                                    if (locationProvider.trailPoints.length == 1) {
                                      await controller.moveCamera(
                                        CameraUpdate.newLatLngZoom(locationProvider.trailPoints.first, 17.0),
                                      );
                                    } else {
                                      final bounds = _getBounds(locationProvider.trailPoints);
                                      await controller.moveCamera(
                                        CameraUpdate.newLatLngBounds(bounds, 50.0),
                                      );
                                    }
                                  } catch (e) {
                                    print("Camera bounds movement failed: $e");
                                    try {
                                      await controller.moveCamera(
                                        CameraUpdate.newLatLngZoom(locationProvider.trailPoints.last, 17.0),
                                      );
                                    } catch (_) {}
                                  }
                                }

                                // 2. Wait 300ms for map tiles to redraw (matching native Android's delay)
                                await Future.delayed(const Duration(milliseconds: 300));

                                // 3. Take snapshot
                                Uint8List? snapshotBytes;
                                try {
                                  snapshotBytes = await controller.takeSnapshot();
                                } catch (e) {
                                  print("Failed to take map snapshot: $e");
                                }

                                // 4. End the walk session
                                final summary = await locationProvider.endWalk();

                                // 5. Show summary bottom sheet
                                if (summary != null) {
                                  final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);
                                  if (syncProvider.currentUserId != null) {
                                    // Upload to Supabase and mark as synced locally
                                    await syncProvider.syncCompletedWalk(summary);
                                    try {
                                      final isar = await IsarService.getDB();
                                      final localSession = await isar.localWalkSessions
                                          .filter()
                                          .sessionIdEqualTo(summary.id)
                                          .findFirst();
                                      if (localSession != null) {
                                        localSession.isSynced = true;
                                        await isar.writeTxn(() async {
                                          await isar.localWalkSessions.put(localSession);
                                        });
                                      }
                                    } catch (e) {
                                      print("Failed to mark walk session as synced locally: $e");
                                    }
                                  }

                                  if (mounted) {
                                    SummaryBottomSheet.show(
                                      context: context,
                                      mapSnapshot: snapshotBytes,
                                      steps: metricsProvider.steps,
                                      isStepEstimated: metricsProvider.isStepEstimated,
                                      distanceKm: metricsProvider.distanceKm,
                                      loops: metricsProvider.loopCount,
                                      durationSeconds: summary.durationSeconds,
                                      cadence: metricsProvider.cadence,
                                      elevationGainMetres: metricsProvider.elevationGainMetres,
                                      onDone: () => setState(() {}),
                                    );
                                  }
                                }
                              },
                              child: const Text("End Walk", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricWidget(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _showVersionHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Version Info & History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
              children: [
                TextSpan(
                  text: "TURF v1.6.0 (v6)\n",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                TextSpan(text: "Latest version installed successfully.\n\n"),
                TextSpan(
                  text: "Version Changelog:\n",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3)),
                ),
                TextSpan(
                  text: "• v1.6.0 (v6) — Loop Claim & Name: Prompt to claim loops with a custom name upon capture, click active loops on map, and view names in history.\n\n",
                ),
                TextSpan(
                  text: "• v1.5.0 (v5) — Advanced Metrics: Cadence in SPM, Elevation Gain/Climb in meters, and a live duration stopwatch tracker.\n\n",
                ),
                TextSpan(
                  text: "• v1.4.0 (v4) — Directional Arrow: Dynamic flat-rotated user position marker based on real-time GPS bearing.\n\n",
                ),
                TextSpan(
                  text: "• v1.3.0 (v3) — Persistent loops: Clickable historical loops drawn persistently on the map view.\n\n",
                ),
                TextSpan(
                  text: "• v1.2.0 (v2) — Navigation & Logging: Drawer navigation, walk history session repository, and background crash logging.\n\n",
                ),
                TextSpan(
                  text: "• v1.0.0 (v1) — Core Foundations: Fused Location updates, step tracking fallback, maps rendering, and foreground service tracking.",
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Awesome", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showClaimLoopDialog(TurfLoop loop) {
    final textController = TextEditingController(text: loop.name ?? "");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(loop.name != null ? "Rename Claimed Loop" : "Claim this Loop 🏆", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Give this loop a custom name to claim it:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "e.g. Park Path, Garden Walk",
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2196F3))),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Dismiss"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);
                final trackingProvider = Provider.of<LocationTrackingProvider>(context, listen: false);

                Navigator.pop(context);

                if (syncProvider.currentUserId != null) {
                  // Online sync claim
                  final res = await syncProvider.attemptClaimLoop(loop.points, name);
                  if (res != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Loop claimed on backend: $name")),
                    );
                    await trackingProvider.loadClaimedLoops();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to claim loop on backend. Saved locally.")),
                    );
                    await trackingProvider.nameLoop(loop.id, name);
                  }
                } else {
                  // Offline guest claim
                  await trackingProvider.nameLoop(loop.id, name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Loop claimed locally as: $name")),
                  );
                }
              }
            },
            child: const Text("Claim"),
          )
        ],
      ),
    );
  }

  void _showClaimedLoopDetailDialog(ClaimedLoop claim) {
    final textController = TextEditingController(text: claim.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(claim.isMyClaim ? "Claimed Loop: ${claim.name} 🏆" : "Claimed Loop: ${claim.name}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (claim.isMyClaim) ...[
              Text("🔥 Streak: ${claim.streakCount} days", style: const TextStyle(color: Colors.white70)),
              Text("🔄 Covered today: ${claim.coveredCountToday} times", style: const TextStyle(color: Colors.white70)),
              Text("📅 Last covered: ${claim.lastCoveredDate}", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              const Text("Rename claimed loop:", style: TextStyle(color: Colors.white54, fontSize: 13)),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2196F3))),
                ),
              )
            ] else ...[
              Text("Claimed by: ${claim.ownerName.isEmpty ? 'Enemy Player' : claim.ownerName} 👤", style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("This is competitive territory! Recover this loop to claim it.", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ]
          ],
        ),
        actions: [
          if (claim.isMyClaim)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () {
                // Confirm Abandon
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text("Abandon Claim?", style: TextStyle(color: Colors.white)),
                    content: Text("Are you sure you want to abandon the claim on '${claim.name}'? Your streak will be lost.", style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Provider.of<LocationTrackingProvider>(context, listen: false).abandonClaim(claim.id);
                          Navigator.pop(ctx); // Close confirmation
                          Navigator.pop(context); // Close detail dialog
                        },
                        child: const Text("Yes, Abandon"),
                      )
                    ],
                  ),
                );
              },
              child: const Text("Abandon Claim"),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          if (claim.isMyClaim)
            ElevatedButton(
              onPressed: () {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  Provider.of<LocationTrackingProvider>(context, listen: false).nameLoop(claim.id, newName);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            )
        ],
      ),
    );
  }

  LatLng _getCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0.0, 0.0);
    double lat = 0.0;
    double lng = 0.0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  LatLng _getMarkerNorthOffset(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0.0, 0.0);
    double maxLat = -90.0;
    LatLng bestPoint = points[0];
    for (var p in points) {
      if (p.latitude > maxLat) {
        maxLat = p.latitude;
        bestPoint = p;
      }
    }
    // Place card marker approx 13 metres north of the northernmost boundary point
    return LatLng(bestPoint.latitude + 0.00012, bestPoint.longitude);
  }
}
