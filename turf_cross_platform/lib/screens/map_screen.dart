import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../location/loop_detector.dart';
import '../providers/tracking_metrics_provider.dart';
import '../providers/location_tracking_provider.dart';
import '../providers/supabase_sync_provider.dart';
import '../models/session_status.dart';
import '../models/turf_loop.dart';
import '../models/claimed_loop.dart';
import '../models/local_walk_session.dart';
import '../repositories/isar_service.dart';
import '../location/sound_manager.dart'; // Import SoundManager
import 'history_bottom_sheet.dart'; // Contains HistoryView
import 'summary_bottom_sheet.dart';
import 'marker_generator.dart';
import 'package:isar/isar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class GlowPathCache {
  final List<LatLng> closedPoints;
  final List<double> cumulativeDistances;
  final double totalLength;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  GlowPathCache({
    required this.closedPoints,
    required this.cumulativeDistances,
    required this.totalLength,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}

class _MapScreenState extends State<MapScreen> {
  Timer? _glowTimer;
  final ValueNotifier<double> _glowPhaseNotifier = ValueNotifier<double>(0.0);
  double _glowPhase = 0.0;
  final Map<String, GlowPathCache> _glowPathCache = {};

  LatLngBounds? _visibleBounds;
  Set<Polygon> _cachedPolygons = {};
  Set<Marker> _cachedMarkers = {};
  Set<Polyline> _cachedStaticPolylines = {};

  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  bool _permissionsGranted = false;
  bool _permissionDeniedPermanently = false;
  bool _permissionsChecked = false;

  // Custom marker descriptors cached to prevent re-renders
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _dotIcon;
  double _currentZoom = 17.0;

  // Tab Navigation State
  int _currentTabIndex = 0; // 0 = MAP, 1 = HISTORY, 2 = MORE

  // Stream Subscriptions
  StreamSubscription<TurfLoop>? _loopCapturedSubscription;
  StreamSubscription<ClaimedLoop>? _claimedLoopCoveredSubscription;
  StreamSubscription<Position>? _realtimeLocationSubscription;
  StreamSubscription<CompassEvent>? _realtimeCompassSubscription;

  // Real-time location and heading variables
  LatLng? _currentLocation;
  LatLng? _lastSyncCameraCenter;
  double _currentHeading = 0.0;
  bool _shouldFollowCamera = true;
  bool _isProgrammaticMovement = false;

  // Marker caching to avoid UI freezes during map rebuilds
  String _lastCacheStateKey = "";
  final Map<String, BitmapDescriptor> _cardMarkerCache = {};
  final Map<String, BitmapDescriptor> _textMarkerCache = {};
  String? _mapStyleString;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _glowTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        _glowPhase = (_glowPhase + 0.01) % 1.0;
        _glowPhaseNotifier.value = _glowPhase;
      }
    });
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
        _permissionsChecked = true;
      });
      _initAssets();
      _setupEventsListener();
      _startRealtimeTracking();
      _centerOnLastKnownLocation();
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionsGranted = false;
        _permissionDeniedPermanently = true;
        _permissionsChecked = true;
      });
    } else {
      setState(() {
        _permissionsGranted = false;
        _permissionsChecked = true;
      });
    }
  }

  Future<void> _initAssets() async {
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final userIcon = await MarkerGenerator.createUserPositionMarker(pixelRatio);
    final dotIcon = await MarkerGenerator.createDotMarker(pixelRatio);
    
    String? mapStyle;
    try {
      mapStyle = await rootBundle.loadString('assets/map_style.json');
    } catch (e) {
      print("Error loading map style: $e");
    }
    
    setState(() {
      _userIcon = userIcon;
      _dotIcon = dotIcon;
      _mapStyleString = mapStyle;
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
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            "CLAIMED LOOP '${claim.name.toUpperCase()}' COVERED. STREAK: ${claim.streakCount} DAYS",
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, color: const Color(0xFFB8FF00)), // Lime green
          ),
          backgroundColor: const Color(0xFF141414),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          duration: const Duration(seconds: 4),
        ),
      );

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
    _glowTimer?.cancel();
    _glowPhaseNotifier.dispose();
    _loopCapturedSubscription?.cancel();
    _claimedLoopCoveredSubscription?.cancel();
    _realtimeLocationSubscription?.cancel();
    _realtimeCompassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB8FF00)), // Lime green
        ),
      );
    }

    if (!_permissionsGranted) {
      return _buildPermissionDeniedUI();
    }

    final trackingProvider = Provider.of<LocationTrackingProvider>(context);

    // Update static map elements (polygons, markers, static polylines) on parent build
    _updateStaticMapObjects(trackingProvider);

    // Pre-cache custom map markers
    final cacheKey = _getCacheStateKey(trackingProvider);
    if (cacheKey != _lastCacheStateKey) {
      _lastCacheStateKey = cacheKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preCacheMarkers(trackingProvider);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top HUD coordinates ticker (Only in MAP tab)
            if (_currentTabIndex == 0)
              Consumer<TrackingMetricsProvider>(
                builder: (context, metricsProvider, _) {
                  final bool isActive = metricsProvider.sessionStatus == SessionStatus.active;
                  return _buildStatusBarHUD(isActive);
                },
              ),

            // Tab Content
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: [
                  // Tab 0: Map HUD Stack
                  Stack(
                    children: [
                      // Google Map View
                      if (_mapStyleString == null)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
                          ),
                        )
                      else
                        ValueListenableBuilder<double>(
                          valueListenable: _glowPhaseNotifier,
                          builder: (context, phase, child) {
                            return GoogleMap(
                              style: _mapStyleString,
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(0.0, 0.0),
                                zoom: 17.0,
                              ),
                              myLocationButtonEnabled: false,
                              myLocationEnabled: false,
                              compassEnabled: false, // Turn off native compass for HUD feel
                              zoomControlsEnabled: false,
                              mapType: MapType.normal,
                              polylines: Set<Polyline>.of(_cachedStaticPolylines)
                                ..addAll(_buildGlowPolylines(trackingProvider, phase)),
                              polygons: _cachedPolygons,
                              markers: _cachedMarkers,
                              onMapCreated: (GoogleMapController controller) async {
                                _mapController.complete(controller);
                                // Hide native map load pops (e.g. style initialization flash)
                                await Future.delayed(const Duration(milliseconds: 1000));
                                if (mounted) {
                                  LatLngBounds? bounds;
                                  try {
                                    bounds = await controller.getVisibleRegion();
                                  } catch (e) {
                                    print("Failed to get visible bounds onMapCreated: $e");
                                  }
                                  setState(() {
                                    _mapReady = true;
                                    _visibleBounds = bounds;
                                  });
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
                              onCameraIdle: () async {
                                LatLngBounds? bounds;
                                try {
                                  final controller = await _mapController.future;
                                  bounds = await controller.getVisibleRegion();
                                  _visibleBounds = bounds;
                                } catch (e) {
                                  print("Failed to get visible bounds onCameraIdle: $e");
                                }

                                if (mounted) {
                                  setState(() {});
                                }

                                try {
                                  if (bounds != null) {
                                    final LatLng cameraCenter = LatLng(
                                      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                                      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                                    );

                                    if (_lastSyncCameraCenter == null ||
                                        LoopDetector.calculateDistanceMetres(
                                              _lastSyncCameraCenter!.latitude,
                                              _lastSyncCameraCenter!.longitude,
                                              cameraCenter.latitude,
                                              cameraCenter.longitude,
                                            ) >
                                            1000.0) {
                                      _lastSyncCameraCenter = cameraCenter;
                                      if (mounted) {
                                        final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);
                                        await syncProvider.pullClaims(center: cameraCenter);
                                      }
                                    }
                                  }
                                } catch (e) {
                                  print("Failed to sync on camera idle: $e");
                                }
                              },
                            );
                          },
                        ),

                      // Overlay to fade transition the native map load pop
                      if (_mapStyleString != null)
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: _mapReady ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 350),
                            child: IgnorePointer(
                              ignoring: _mapReady,
                              child: Container(
                                color: const Color(0xFF0A0A0A),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFB8FF00),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Status Chips (Paused / GPS Signal)
                      Positioned(
                        top: 16.0,
                        right: 16.0,
                        child: Selector<TrackingMetricsProvider, SessionStatus>(
                          selector: (_, p) => p.sessionStatus,
                          builder: (context, status, _) {
                            final isWeak = trackingProvider.gpsSignalWeak;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (status == SessionStatus.paused)
                                  _buildStatusChip("WALK_PAUSED", const Color(0xFFFF6B00)),
                                if (isWeak && status == SessionStatus.active)
                                  const SizedBox(height: 8),
                                if (isWeak && status == SessionStatus.active)
                                  _buildStatusChip("WEAK_GPS_SIGNAL", const Color(0xFFFF3B3B)),
                              ],
                            );
                          },
                        ),
                      ),

                      // Location FAB
                      Selector<TrackingMetricsProvider, SessionStatus>(
                        selector: (_, p) => p.sessionStatus,
                        builder: (context, status, _) {
                          // Position FAB 88px above screen bottom (bottom navigation clearance is 64px)
                          // If active walk sheet is open, we offset it slightly above sheet height to avoid overlapping.
                          final double bottomOffset = status == SessionStatus.idle
                              ? 88.0
                              : 290.0;
                          return Positioned(
                            bottom: bottomOffset,
                            right: 16.0,
                            child: GestureDetector(
                              onTap: () async {
                                HapticFeedback.heavyImpact();
                                SoundManager.playRecenter();
                                _shouldFollowCamera = true;
                                if (_currentLocation != null) {
                                  _isProgrammaticMovement = true;
                                  final controller = await _mapController.future;
                                  controller.animateCamera(
                                    CameraUpdate.newLatLngZoom(_currentLocation!, 17.0),
                                  );
                                }
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  border: Border.all(color: const Color(0xFF2A2A2A), width: 1.0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Icon(Icons.gps_fixed_outlined, color: Color(0xFF888888), size: 20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Start Walk CTA (Only visible when Idle)
                      Selector<TrackingMetricsProvider, SessionStatus>(
                        selector: (_, p) => p.sessionStatus,
                        builder: (context, status, _) {
                          if (status != SessionStatus.idle) return const SizedBox.shrink();
                          return Positioned(
                            bottom: 16.0,
                            left: 16.0,
                            right: 16.0,
                            child: CrtStartWalkButton(
                              onPressed: () {
                                HapticFeedback.heavyImpact();
                                SoundManager.playStartWalk();
                                trackingProvider.startWalk();
                              },
                            ),
                          );
                        },
                      ),

                      // Active Walk HUD Panel (Only visible when not Idle)
                      _buildActiveWalkPanel(trackingProvider),
                    ],
                  ),

                  // Tab 1: Walk History view
                  const HistoryBottomSheet(), // Converted to full-screen view inside bottom sheet file

                  // Tab 2: MORE Full-screen Menu
                  _buildMoreTab(trackingProvider),
                ],
              ),
            ),

            // 3-tab Bottom Navigation Bar
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 64.0 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, "MAP", Icons.map_outlined),
          _buildNavItem(1, "HISTORY", Icons.history_outlined),
          _buildNavItem(2, "MORE", Icons.more_horiz_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final bool isActive = _currentTabIndex == index;
    final Color color = isActive ? const Color(0xFFB8FF00) : const Color(0xFF444444); // Lime green #B8FF00
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        SoundManager.playButtonClick();
        setState(() {
          _currentTabIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 9 * 0.06,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreTab(LocationTrackingProvider trackingProvider) {
    final syncProv = Provider.of<SupabaseSyncProvider>(context);
    return Container(
      color: const Color(0xFF0A0A0A),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "// MORE",
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFF444444),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 11 * 0.06,
            ),
          ),
          const SizedBox(height: 24),
          _buildMoreRow("MY TURF", onTap: () {
            HapticFeedback.heavyImpact();
            SoundManager.playButtonClick();
            _showMyTurfDialog(trackingProvider);
          }),
          _buildMoreRow("PROFILE", onTap: () {
            HapticFeedback.heavyImpact();
            SoundManager.playButtonClick();
            _showProfileDialog(syncProv);
          }),
          _buildMoreRow("VERSION: 1.6.0 (V6)", isVersion: true),
        ],
      ),
    );
  }

  Widget _buildMoreRow(String label, {VoidCallback? onTap, bool isVersion = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: isVersion ? const Color(0xFF888888) : const Color(0xFFEBEBEB),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 14 * 0.04,
              ),
            ),
            if (!isVersion)
              const Icon(Icons.arrow_forward_ios_outlined, size: 14, color: Color(0xFF444444)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBarHUD(bool isActive) {
    final latStr = _currentLocation != null ? "${_currentLocation!.latitude.toStringAsFixed(4)}°" : "--";
    final lngStr = _currentLocation != null ? "${_currentLocation!.longitude.toStringAsFixed(4)}°" : "--";
    final readout = "SYS_STATUS: ONLINE · LAT: $latStr · LNG: $lngStr";
    return Container(
      height: 28,
      width: double.infinity,
      color: const Color(0xB30A0A0A), // rgba(10, 10, 10, 0.7)
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          readout,
          style: GoogleFonts.jetBrainsMono(
            color: isActive ? const Color(0xFFB8FF00) : const Color(0xFF444444), // Lime green #B8FF00
            fontSize: 10,
            fontWeight: FontWeight.w400,
            letterSpacing: 10 * 0.06,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2), // 2px max radius for chips
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 10 * 0.06,
        ),
      ),
    );
  }

  Widget _buildActiveWalkPanel(LocationTrackingProvider locationProvider) {
    return Consumer<TrackingMetricsProvider>(
      builder: (context, metricsProvider, child) {
        if (metricsProvider.sessionStatus == SessionStatus.idle) return const SizedBox.shrink();

        final minutes = metricsProvider.durationSeconds ~/ 60;
        final seconds = metricsProvider.durationSeconds % 60;
        final durationStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

        // Estimate perimeter percentage:
        int percentage = 0;
        if (metricsProvider.loopCount > 0) {
          percentage = 100;
        } else if (locationProvider.trailPoints.isNotEmpty) {
          final double distanceMeters = metricsProvider.distanceKm * 1000.0;
          percentage = (distanceMeters / 400.0 * 100).clamp(0, 99).toInt();
        }

        // Active walk sheet layout
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 280, // Fixed height to fit 2x3 grid and buttons
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0A), // Styleguide dark bg
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top status line
                Text(
                  "CLAIM_WALK: IN_PROGRESS",
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFFB8FF00), // Lime green #B8FF00
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 11 * 0.06,
                  ),
                ),
                const SizedBox(height: 12),

                // 2x3 metrics grid separated by 1px solid #2A2A2A lines
                Expanded(
                  child: Table(
                    border: const TableBorder(
                      horizontalInside: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
                      verticalInside: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
                    ),
                    children: [
                      TableRow(
                        children: [
                          _buildGridCell("STEPS", "${metricsProvider.steps}${metricsProvider.isStepEstimated ? ' (EST)' : ''}"),
                          _buildGridCell("DISTANCE", "${metricsProvider.distanceKm.toStringAsFixed(2)} KM"),
                          _buildGridCell("TIME", durationStr),
                        ],
                      ),
                      TableRow(
                        children: [
                          _buildGridCell("LOOPS", "${metricsProvider.loopCount}"),
                          _buildGridCell("CADENCE", "${metricsProvider.cadence} SPM"),
                          _buildGridCell("ELEVATION", "${metricsProvider.elevationGainMetres.toStringAsFixed(1)} M"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Perimeter Progress Bar
                _buildPerimeterProgressBar(percentage),
                const SizedBox(height: 16),

                // Control Action Buttons
                Row(
                  children: [
                    // Pause Button (Left half)
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E1E),
                            foregroundColor: const Color(0xFF888888),
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            SoundManager.playButtonClick();
                            if (metricsProvider.sessionStatus == SessionStatus.active) {
                              locationProvider.pauseWalk();
                            } else {
                              locationProvider.resumeWalk();
                            }
                          },
                          child: Text(
                            metricsProvider.sessionStatus == SessionStatus.active ? "PAUSE" : "RESUME",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 14 * 0.04,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // End Walk Button (Right half)
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFFFF3B3B),
                            side: const BorderSide(color: Color(0xFFFF3B3B), width: 1.0),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
                            SoundManager.playEndWalk();
                            final controller = await _mapController.future;

                            // Recenter map on path boundary before snapshot
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

                            await Future.delayed(const Duration(milliseconds: 300));

                            Uint8List? snapshotBytes;
                            try {
                              snapshotBytes = await controller.takeSnapshot();
                            } catch (e) {
                              print("Failed to take map snapshot: $e");
                            }

                            final summary = await locationProvider.endWalk();

                            if (summary != null) {
                              final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);
                              if (syncProvider.currentUserId != null) {
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
                                  zoneName: summary.loops.isNotEmpty
                                      ? (summary.loops.first.name ?? "GHOST_ZONE")
                                      : "GHOST_ZONE",
                                  mapSnapshot: snapshotBytes,
                                  steps: summary.steps,
                                  isStepEstimated: summary.isStepEstimated,
                                  distanceKm: summary.distanceKm,
                                  loops: summary.loopCount,
                                  durationSeconds: summary.durationSeconds,
                                  cadence: summary.cadence,
                                  elevationGainMetres: summary.elevationGainMetres,
                                  onDone: () => setState(() {}),
                                );
                              }
                            }
                          },
                          child: Text(
                            "END WALK",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 14 * 0.04,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFF888888),
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 10 * 0.06,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFFEBEBEB),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerimeterProgressBar(int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "PERIMETER",
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFF888888),
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 10 * 0.06,
              ),
            ),
            Text(
              "$percentage%",
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFB8FF00), // Lime green #B8FF00
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 10 * 0.06,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 3,
          width: double.infinity,
          color: const Color(0xFF2A2A2A),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: percentage / 100.0,
            child: Container(
              color: const Color(0xFFB8FF00), // Lime green #B8FF00
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, size: 80, color: Color(0xFFFF3B3B)),
              const SizedBox(height: 24),
              Text(
                "PERMISSIONS REQUIRED",
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "TURF REQUIRES BACKGROUND LOCATION ACCESS TO MAP YOUR PATHS AND CALCULATE STATS.",
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 12),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8FF00), // Lime green #B8FF00
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    SoundManager.playButtonClick();
                    if (_permissionDeniedPermanently) {
                      Geolocator.openAppSettings();
                    } else {
                      _checkPermissionsAndInit();
                    }
                  },
                  child: Text(
                    _permissionDeniedPermanently ? "OPEN SETTINGS" : "GRANT PERMISSIONS",
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCacheStateKey(LocationTrackingProvider provider) {
    final claimedPart = provider.cachedClaimedLoops
        .map((c) => "${c.id}_${c.streakCount}_${c.coveredCountToday}_${c.isActive}_${c.isMyClaim}")
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

    // Pre-cache claimed loops
    for (var claim in provider.cachedClaimedLoops) {
      final cacheKey = "${claim.id}_${claim.streakCount}_${claim.coveredCountToday}_${claim.isActive}_${claim.isMyClaim}";
      if (!_cardMarkerCache.containsKey(cacheKey)) {
        try {
          final descriptor = await MarkerGenerator.createCardMarker(
            claim.name,
            claim.streakCount,
            claim.coveredCountToday,
            pixelRatio,
            claim.isActive,
            claim.ownerName,
            claim.isMyClaim,
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
          zIndexInt: 10,
        ),
      );
    }

    // 2. Claimed loop label cards
    final zoomInEnough = _currentZoom >= 15.5;
    for (var loop in provider.capturedLoops) {
      final claimedIndex = provider.cachedClaimedLoops.indexWhere((c) => c.id == loop.id);
      if (claimedIndex != -1) {
        final claim = provider.cachedClaimedLoops[claimedIndex];
        final center = _getMarkerNorthOffset(loop.points);
        
        final cacheKey = "${claim.id}_${claim.streakCount}_${claim.coveredCountToday}_${claim.isActive}_${claim.isMyClaim}";
        final cachedIcon = _cardMarkerCache[cacheKey];
        
        final icon = zoomInEnough
            ? (cachedIcon ?? _dotIcon)
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
        final center = _getCentroid(loop.points);
        if (zoomInEnough) {
          final cachedIcon = _textMarkerCache[loop.name!];
          final icon = cachedIcon ?? _dotIcon;
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
      
      final cacheKey = "${claim.id}_${claim.streakCount}_${claim.coveredCountToday}_${claim.isActive}_${claim.isMyClaim}";
      final cachedIcon = _cardMarkerCache[cacheKey];
      
      final icon = zoomInEnough
          ? (cachedIcon ?? _dotIcon)
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

  void _updateStaticMapObjects(LocationTrackingProvider provider) {
    _cachedPolygons = _buildPolygons(provider);
    _cachedMarkers = _buildMarkersSync(provider);
    _cachedStaticPolylines = _buildStaticPolylines(provider);
  }

  Set<Polyline> _buildStaticPolylines(LocationTrackingProvider provider) {
    final Set<Polyline> polylines = {};
    if (provider.trailPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId("active_trail"),
          points: provider.trailPoints,
          color: provider.activeTrailColor ?? const Color(0xFFB8FF00), // #B8FF00 for active trail
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    // Add dashed strokes for GHOST captured loops
    for (var loop in provider.capturedLoops) {
      final claimedIndex = provider.cachedClaimedLoops.indexWhere((c) => c.id == loop.id);
      if (claimedIndex == -1) {
        final closedPoints = List<LatLng>.from(loop.points)..add(loop.points.first);
        polylines.add(
          Polyline(
            polylineId: PolylineId("captured_stroke_${loop.id}"),
            points: closedPoints,
            color: const Color(0xFF4A4A4A),
            width: 1,
            patterns: [PatternItem.dash(10), PatternItem.gap(10)],
          ),
        );
      } else {
        final claim = provider.cachedClaimedLoops[claimedIndex];
        if (!claim.isActive) {
          final closedPoints = List<LatLng>.from(loop.points)..add(loop.points.first);
          polylines.add(
            Polyline(
              polylineId: PolylineId("captured_stroke_${loop.id}"),
              points: closedPoints,
              color: const Color(0xFF4A4A4A),
              width: 1,
              patterns: [PatternItem.dash(10), PatternItem.gap(10)],
            ),
          );
        }
      }
    }

    // Add dashed strokes for GHOST claims
    for (var claim in provider.cachedClaimedLoops) {
      if (provider.capturedLoops.any((l) => l.id == claim.id)) continue;
      if (!claim.isActive || claim.ownerId.isEmpty) {
        final closedPoints = List<LatLng>.from(claim.points)..add(claim.points.first);
        polylines.add(
          Polyline(
            polylineId: PolylineId("claim_stroke_${claim.id}"),
            points: closedPoints,
            color: const Color(0xFF4A4A4A),
            width: 1,
            patterns: [PatternItem.dash(10), PatternItem.gap(10)],
          ),
        );
      }
    }

    return polylines;
  }

  Set<Polyline> _buildGlowPolylines(LocationTrackingProvider provider, double phase) {
    final Set<Polyline> polylines = {};
    // Add travelling glow polylines for actively claimed loops
    for (var claim in provider.cachedClaimedLoops) {
      if (!claim.isActive || claim.ownerId.isEmpty) continue; // Only animate active claims

      final String cacheKey = claim.id;
      final GlowPathCache? cache = _glowPathCache[cacheKey];
      if (cache != null && !_isLoopVisible(cache, _visibleBounds)) {
        continue;
      }

      final Color baseColor = claim.isMyClaim 
          ? const Color(0xFFB8FF00) // Lime green for HELD
          : const Color(0xFFFF6B00); // Orange for CONTESTED

      final List<LatLng> glowPoints = _extractGlowSegment(claim, phase);
      if (glowPoints.length >= 2) {
        // Outer glow
        polylines.add(
          Polyline(
            polylineId: PolylineId("claim_glow_outer_${claim.id}"),
            points: glowPoints,
            color: baseColor.withOpacity(0.35),
            width: 12,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            zIndex: 3,
          ),
        );
        // Inner glow
        polylines.add(
          Polyline(
            polylineId: PolylineId("claim_glow_inner_${claim.id}"),
            points: glowPoints,
            color: baseColor.withOpacity(0.9),
            width: 6,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            zIndex: 4,
          ),
        );
        // Core laser highlight
        polylines.add(
          Polyline(
            polylineId: PolylineId("claim_glow_core_${claim.id}"),
            points: glowPoints,
            color: Colors.white,
            width: 2,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            zIndex: 5,
          ),
        );
      }
    }

    return polylines;
  }

  Set<Polygon> _buildPolygons(LocationTrackingProvider provider) {
    final Set<Polygon> polygons = {};

    // Render active captured loops
    for (var loop in provider.capturedLoops) {
      final claimedIndex = provider.cachedClaimedLoops.indexWhere((c) => c.id == loop.id);
      if (claimedIndex == -1) {
        // Unclaimed: GHOST fill
        polygons.add(
          Polygon(
            polygonId: PolygonId("captured_poly_${loop.id}"),
            points: loop.points,
            fillColor: const Color(0x144A4A4A), // rgba(74, 74, 74, 0.08)
            strokeColor: Colors.transparent,
            strokeWidth: 0,
            consumeTapEvents: true,
            onTap: () => _showClaimLoopDialog(loop),
          ),
        );
      } else {
        final claim = provider.cachedClaimedLoops[claimedIndex];
        _addClaimPolygon(polygons, claim);
      }
    }

    // Render historical claimed loop areas
    for (var claim in provider.cachedClaimedLoops) {
      if (provider.capturedLoops.any((l) => l.id == claim.id)) continue;
      _addClaimPolygon(polygons, claim);
    }

    return polygons;
  }

  void _addClaimPolygon(Set<Polygon> polygons, ClaimedLoop claim) {
    if (!claim.isActive || claim.ownerId.isEmpty) {
      // Unclaimed / Ghost
      polygons.add(
        Polygon(
          polygonId: PolygonId("claim_poly_${claim.id}"),
          points: claim.points,
          fillColor: const Color(0x144A4A4A), // rgba(74, 74, 74, 0.08)
          strokeColor: Colors.transparent,
          strokeWidth: 0,
          consumeTapEvents: true,
          onTap: () => _showClaimedLoopDetailDialog(claim),
        ),
      );
    } else if (claim.isMyClaim) {
      // HELD (Owned)
      polygons.add(
        Polygon(
          polygonId: PolygonId("claim_poly_${claim.id}"),
          points: claim.points,
          fillColor: const Color(0x26B8FF00), // rgba(184, 255, 0, 0.15)
          strokeColor: const Color(0xFFB8FF00), // Lime green #B8FF00
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => _showClaimedLoopDetailDialog(claim),
        ),
      );
    } else {
      // CONTESTED (Enemy owned)
      polygons.add(
        Polygon(
          polygonId: PolygonId("claim_poly_${claim.id}"),
          points: claim.points,
          fillColor: const Color(0x26FF6B00), // rgba(255, 107, 0, 0.15)
          strokeColor: const Color(0xFFFF6B00),
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => _showClaimedLoopDetailDialog(claim),
        ),
      );
    }
  }

  void _showMyTurfDialog(LocationTrackingProvider trackingProvider) {
    final myClaims = trackingProvider.cachedClaimedLoops.where((c) => c.isMyClaim).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          "MY TURF",
          style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEBEBEB), fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: myClaims.isEmpty
              ? Text(
                  "NO TURF YET. WALK A BLOCK. OWN IT.",
                  style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 11),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: myClaims.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2A2A)),
                  itemBuilder: (context, idx) {
                    final claim = myClaims[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        claim.name.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEBEBEB), fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "STREAK: ${claim.streakCount} DAYS",
                        style: GoogleFonts.jetBrainsMono(color: const Color(0xFFB8FF00), fontSize: 11), // Lime green #B8FF00
                      ),
                      trailing: const Icon(Icons.chevron_right_outlined, color: Color(0xFF888888)),
                      onTap: () async {
                        HapticFeedback.heavyImpact();
                        SoundManager.playRecenter();
                        Navigator.pop(context);
                        setState(() {
                          _currentTabIndex = 0; // Swap to MAP
                        });
                        final centroid = _getCentroid(claim.points);
                        final controller = await _mapController.future;
                        _shouldFollowCamera = false;
                        _isProgrammaticMovement = true;
                        await controller.animateCamera(CameraUpdate.newLatLngZoom(centroid, 17.0));
                        _showClaimedLoopDetailDialog(claim);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              SoundManager.playButtonClick();
              Navigator.pop(context);
            },
            child: Text(
              "CLOSE",
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEBEBEB), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(SupabaseSyncProvider syncProv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          "PROFILE",
          style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEBEBEB), fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncProv.currentUserId != null) ...[
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF1E1E1E),
                backgroundImage: syncProv.currentUsername != null
                    ? NetworkImage('https://api.dicebear.com/7.x/bottts/png?seed=${syncProv.currentUsername}')
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                syncProv.currentUsername ?? "USER",
                style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEBEBEB), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "STATUS: ONLINE",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFFB8FF00), fontSize: 11), // Lime green #B8FF00
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFFFF3B3B),
                    side: const BorderSide(color: Color(0xFFFF3B3B), width: 1.0),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    SoundManager.playLogout();
                    syncProv.signOut();
                    Navigator.pop(context);
                  },
                  child: Text(
                    "SIGN OUT",
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else ...[
              Text(
                "SYS_STATUS: GUEST_MODE",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                "Sign in on launch to sync your scores to Supabase.",
                style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              SoundManager.playButtonClick();
              Navigator.pop(context);
            },
            child: Text(
              "CLOSE",
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFFEBEBEB), fontWeight: FontWeight.bold),
            ),
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
        backgroundColor: const Color(0xFF141414),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          loop.name != null ? "RENAME CLAIMED LOOP" : "CLAIM THIS LOOP",
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PROVIDE A SYSTEM NAME FOR THIS ZONE:",
              style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 11),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g. KORAMANGALA_BLOCK_4",
                hintStyle: GoogleFonts.jetBrainsMono(color: const Color(0xFF444444), fontSize: 12),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2A2A2A))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB8FF00))), // Lime green
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              SoundManager.playButtonClick();
              Navigator.pop(context);
            },
            child: Text("DISMISS", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8FF00), // Lime green #B8FF00
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              SoundManager.playButtonClick();
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);
                final trackingProvider = Provider.of<LocationTrackingProvider>(context, listen: false);

                Navigator.pop(context);

                if (syncProvider.currentUserId != null) {
                  final res = await syncProvider.attemptClaimLoop(loop.points, name);
                  if (res != null) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF141414),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        content: Text("LOOP CLAIMED: ${name.toUpperCase()}", style: GoogleFonts.jetBrainsMono(color: const Color(0xFFB8FF00))),
                      ),
                    );
                    await trackingProvider.loadClaimedLoops();
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF141414),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        content: Text("SYNC FAILED. LOOP SAVED LOCALLY.", style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFF3B3B))),
                      ),
                    );
                    await trackingProvider.nameLoop(loop.id, name);
                  }
                } else {
                  await trackingProvider.nameLoop(loop.id, name);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF141414),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      content: Text("LOOP SAVED LOCALLY: ${name.toUpperCase()}", style: GoogleFonts.jetBrainsMono(color: const Color(0xFFB8FF00))),
                    ),
                  );
                }
              }
            },
            child: Text("CLAIM", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF141414),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          !claim.isActive
              ? "EXPIRED CLAIM: ${claim.name.toUpperCase()}"
              : "ZONE: ${claim.name.toUpperCase()}",
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!claim.isActive) ...[
              Text(
                "STATUS: GHOST",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFF3B3B), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              if (claim.ownerName.isNotEmpty && claim.streakCount > 0)
                Text(
                  "LAST OWNER: ${claim.ownerName.toUpperCase()} · STREAK: ${claim.streakCount} DAYS",
                  style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 11),
                ),
              const SizedBox(height: 12),
              Text(
                "Walk this block to claim ownership.",
                style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13),
              ),
            ] else if (claim.ownerId.isEmpty) ...[
              Text(
                "STATUS: UNCLAIMED",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                "Walk this block to claim ownership.",
                style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13),
              ),
            ] else if (claim.isMyClaim) ...[
              Text(
                "STATUS: HELD",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFFB8FF00), fontWeight: FontWeight.bold, fontSize: 13), // Lime green #B8FF00
              ),
              const SizedBox(height: 4),
              Text(
                "STREAK: ${claim.streakCount} DAYS\nCOVERED TODAY: ${claim.coveredCountToday} LOOPS\nLAST COVERED: ${claim.lastCoveredDate}",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 11),
              ),
              const SizedBox(height: 16),
              Text(
                "RENAME ZONE:",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF444444), fontSize: 11),
              ),
              TextField(
                controller: textController,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2A2A2A))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB8FF00))), // Lime green
                ),
              )
            ] else ...[
              Text(
                "STATUS: CONTESTED",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                "OWNER: ${claim.ownerName.toUpperCase()}\nSTREAK: ${claim.streakCount} DAYS\nLAST COVERED: ${claim.lastCoveredDate}",
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 11),
              ),
              const SizedBox(height: 12),
              Text(
                "Complete a loop to contest this territory.",
                style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13),
              ),
            ]
          ],
        ),
        actions: [
          if (claim.isMyClaim)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B3B)),
              onPressed: () {
                HapticFeedback.heavyImpact();
                SoundManager.playDeleteHistory();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF141414),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    title: Text(
                      "ABANDON CLAIM?",
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      "ARE YOU SURE YOU WANT TO ABANDON YOUR STREAK ON '${claim.name.toUpperCase()}'?",
                      style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 11),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          SoundManager.playButtonClick();
                          Navigator.pop(ctx);
                        },
                        child: Text("CANCEL", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888))),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFFFF3B3B),
                          side: const BorderSide(color: Color(0xFFFF3B3B)),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          SoundManager.playDeleteHistory();
                          Provider.of<LocationTrackingProvider>(context, listen: false).abandonClaim(claim.id);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: Text("ABANDON", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                );
              },
              child: Text("ABANDON", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              SoundManager.playButtonClick();
              Navigator.pop(context);
            },
            child: Text("CLOSE", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888))),
          ),
          if (claim.isMyClaim && claim.isActive)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8FF00), // Lime green #B8FF00
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () {
                HapticFeedback.heavyImpact();
                SoundManager.playButtonClick();
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  Provider.of<LocationTrackingProvider>(context, listen: false).nameLoop(claim.id, newName);
                  Navigator.pop(context);
                }
              },
              child: Text("SAVE", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
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
    return LatLng(bestPoint.latitude + 0.00012, bestPoint.longitude);
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

  List<LatLng> _extractGlowSegment(ClaimedLoop claim, double phase) {
    final String cacheKey = claim.id;
    GlowPathCache? pathCache = _glowPathCache[cacheKey];

    if (pathCache == null) {
      final points = claim.points;
      if (points.isEmpty) return [];

      final closedPoints = List<LatLng>.from(points);
      if (closedPoints.first != closedPoints.last) {
        closedPoints.add(closedPoints.first);
      }

      final int numPoints = closedPoints.length;
      final List<double> cumulativeDistances = List<double>.filled(numPoints, 0.0);
      double totalLength = 0.0;
      cumulativeDistances[0] = 0.0;

      double minLat = closedPoints.first.latitude;
      double maxLat = closedPoints.first.latitude;
      double minLng = closedPoints.first.longitude;
      double maxLng = closedPoints.first.longitude;

      for (int i = 0; i < numPoints; i++) {
        final pt = closedPoints[i];
        if (pt.latitude < minLat) minLat = pt.latitude;
        if (pt.latitude > maxLat) maxLat = pt.latitude;
        if (pt.longitude < minLng) minLng = pt.longitude;
        if (pt.longitude > maxLng) maxLng = pt.longitude;

        if (i < numPoints - 1) {
          final dist = _getDistance(pt, closedPoints[i + 1]);
          totalLength += dist;
          cumulativeDistances[i + 1] = totalLength;
        }
      }

      pathCache = GlowPathCache(
        closedPoints: closedPoints,
        cumulativeDistances: cumulativeDistances,
        totalLength: totalLength,
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
      );
      _glowPathCache[cacheKey] = pathCache;
    }

    final double totalLength = pathCache.totalLength;
    if (totalLength <= 0.0) return [];

    final double glowLength = totalLength * 0.25;
    final double startDist = phase * totalLength;
    final double endDist = startDist + glowLength;

    final double s = startDist % totalLength;
    final double e = endDist % totalLength;

    final List<LatLng> result = [];
    if (s <= e) {
      _addPointsForRange(pathCache.closedPoints, pathCache.cumulativeDistances, totalLength, s, e, result);
    } else {
      _addPointsForRange(pathCache.closedPoints, pathCache.cumulativeDistances, totalLength, s, totalLength, result);
      _addPointsForRange(pathCache.closedPoints, pathCache.cumulativeDistances, totalLength, 0.0, e, result);
    }
    return result;
  }

  bool _isLoopVisible(GlowPathCache cache, LatLngBounds? bounds) {
    if (bounds == null) return true;

    // Check if the loop's bounding box overlaps with the visible bounds (plus ~500m safety padding).
    const double padding = 0.005;
    final double minLatLimit = bounds.southwest.latitude - padding;
    final double maxLatLimit = bounds.northeast.latitude + padding;
    final double minLngLimit = bounds.southwest.longitude - padding;
    final double maxLngLimit = bounds.northeast.longitude + padding;

    return (cache.minLat <= maxLatLimit && cache.maxLat >= minLatLimit) &&
           (cache.minLng <= maxLngLimit && cache.maxLng >= minLngLimit);
  }

  double _getDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000.0; // in meters
    final double dLat = _toRadians(p2.latitude - p1.latitude);
    final double dLng = _toRadians(p2.longitude - p1.longitude);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(p1.latitude)) * math.cos(_toRadians(p2.latitude)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180.0;
  }

  LatLng _interpolate(LatLng p1, LatLng p2, double fraction) {
    final double lat = p1.latitude + (p2.latitude - p1.latitude) * fraction;
    final double lng = p1.longitude + (p2.longitude - p1.longitude) * fraction;
    return LatLng(lat, lng);
  }

  LatLng _getInterpolatedPoint(List<LatLng> points, List<double> cumD, double totalLength, double d) {
    if (d <= 0.0) return points.first;
    if (d >= totalLength) return points.last;

    for (int i = 0; i < points.length - 1; i++) {
      final double d1 = cumD[i];
      final double d2 = cumD[i + 1];
      if (d >= d1 && d <= d2) {
        final double denom = d2 - d1;
        final double fraction = denom > 0.0 ? (d - d1) / denom : 0.0;
        return _interpolate(points[i], points[i + 1], fraction);
      }
    }
    return points.last;
  }

  void _addPointsForRange(
    List<LatLng> points,
    List<double> cumD,
    double totalLength,
    double startD,
    double endD,
    List<LatLng> result,
  ) {
    final LatLng startPt = _getInterpolatedPoint(points, cumD, totalLength, startD);
    if (result.isEmpty || startPt != result.last) {
      result.add(startPt);
    }

    for (int i = 0; i < points.length; i++) {
      final double d = cumD[i];
      if (d > startD && d < endD) {
        final LatLng pt = points[i];
        if (pt != result.last) {
          result.add(pt);
        }
      }
    }

    final LatLng endPt = _getInterpolatedPoint(points, cumD, totalLength, endD);
    if (endPt != result.last) {
      result.add(endPt);
    }
  }
}

// ----------------------------------------------------
// CRT SCANLINE BUTTON WIDGETS
// ----------------------------------------------------

class CrtStartWalkButton extends StatefulWidget {
  final VoidCallback onPressed;

  const CrtStartWalkButton({super.key, required this.onPressed});

  @override
  State<CrtStartWalkButton> createState() => _CrtStartWalkButtonState();
}

class _CrtStartWalkButtonState extends State<CrtStartWalkButton> with SingleTickerProviderStateMixin {
  late AnimationController _crtController;

  @override
  void initState() {
    super.initState();
    _crtController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _crtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFB8FF00), // Lime green #B8FF00 background
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8FF00).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ],
        ),
        child: Stack(
          children: [
            // Animating CRT Scanlines
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _crtController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: ScanlinePainter(_crtController.value),
                  );
                },
              ),
            ),
            
            // Text Label
            Center(
              child: Text(
                "START CLAIM WALK",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 16 * 0.04,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanlinePainter extends CustomPainter {
  final double animationValue;

  ScanlinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1.0;

    const double step = 4.0; // Distance between scanlines
    final double offset = (animationValue * step);

    for (double y = offset; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(ScanlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
