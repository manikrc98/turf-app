package com.yourname.turf.ui

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.JointType
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MapStyleOptions
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.maps.model.Polygon
import com.google.android.gms.maps.model.PolygonOptions
import com.google.android.gms.maps.model.Polyline
import com.google.android.gms.maps.model.PolylineOptions
import com.google.android.gms.maps.model.RoundCap
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.snackbar.Snackbar
import com.yourname.turf.R
import com.yourname.turf.databinding.ActivityMapBinding
import com.yourname.turf.model.SessionStatus
import com.yourname.turf.model.TurfSessionState
import com.yourname.turf.model.WalkSessionSummary
import com.yourname.turf.service.TurfTrackerService
import androidx.core.view.GravityCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import com.yourname.turf.model.ClaimedLoop
import com.yourname.turf.model.ClaimedLoopRepository

class MapActivity : AppCompatActivity(), OnMapReadyCallback, SensorEventListener {

    private lateinit var binding: ActivityMapBinding
    private val viewModel: TurfViewModel by viewModels()

    private var googleMap: GoogleMap? = null
    private var userMarker: Marker? = null
    private lateinit var userIconDescriptor: BitmapDescriptor

    private var activePolyline: Polyline? = null
    private val activePolygons = mutableListOf<Polygon>()

    private var shouldFollowCamera = true

    // Persistent Bottom Sheet Behavior
    private lateinit var bottomSheetBehavior: BottomSheetBehavior<View>

    // Device orientation sensor variables
    private lateinit var sensorManager: SensorManager
    private var rotationSensor: Sensor? = null
    private var currentHeading: Float = 0f

    // Idle state location variables
    private lateinit var activityLocationManager: com.yourname.turf.location.LocationManager
    private var lastKnownLatLng: LatLng? = null

    // Label markers lists
    private val activeLabelMarkers = mutableListOf<Marker>()
    private val historicalLabelMarkers = mutableListOf<Marker>()
    private val claimedLabelMarkers = mutableListOf<Marker>()

    // Permission launcher
    private val requestPermissionsLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        val activityGranted = permissions[Manifest.permission.ACTIVITY_RECOGNITION] ?: false

        if (fineGranted && activityGranted) {
            setupViewsAndMap()
        } else {
            showPermissionRationaleOrSettings()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CrashLogger(applicationContext)
        binding = ActivityMapBinding.inflate(layoutInflater)
        setContentView(binding.root)

        userIconDescriptor = createUserPositionIcon()
        bottomSheetBehavior = BottomSheetBehavior.from(binding.persistentBottomSheet)
        bottomSheetBehavior.addBottomSheetCallback(object : BottomSheetBehavior.BottomSheetCallback() {
            override fun onStateChanged(bottomSheet: View, newState: Int) {}
            override fun onSlide(bottomSheet: View, slideOffset: Float) {
                if (slideOffset > 0f && bottomSheet.height > 0) {
                    val heightDiff = bottomSheet.height - bottomSheetBehavior.peekHeight
                    binding.fabRecenter.translationY = -slideOffset * heightDiff
                } else {
                    binding.fabRecenter.translationY = 0f
                }
            }
        })

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        rotationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if (rotationSensor == null) {
            rotationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ORIENTATION)
        }
        activityLocationManager = com.yourname.turf.location.LocationManager(this)

        setupNavigationDrawer()
        checkPermissionsAndInit()
    }

    private fun checkPermissionsAndInit() {
        val fineLocationGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        
        val activityGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACTIVITY_RECOGNITION
        ) == PackageManager.PERMISSION_GRANTED

        if (fineLocationGranted && activityGranted) {
            setupViewsAndMap()
        } else {
            requestPermissionsLauncher.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACTIVITY_RECOGNITION
                )
            )
        }
    }

    private fun showPermissionRationaleOrSettings() {
        val fineRationale = shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_FINE_LOCATION)
        val activityRationale = shouldShowRequestPermissionRationale(Manifest.permission.ACTIVITY_RECOGNITION)

        if (fineRationale || activityRationale) {
            // Explain rationale
            AlertDialog.Builder(this)
                .setTitle("Permissions Required")
                .setMessage("TURF requires location tracking and physical activity permissions to draw your paths, measure distance, and count steps.")
                .setPositiveButton("Grant") { _, _ ->
                    requestPermissionsLauncher.launch(
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACTIVITY_RECOGNITION
                        )
                    )
                }
                .setNegativeButton("Cancel") { dialog, _ ->
                    dialog.dismiss()
                    showEmptyState()
                }
                .show()
        } else {
            // Permanently denied - redirect to Settings
            AlertDialog.Builder(this)
                .setTitle("Permissions Permanently Denied")
                .setMessage("TURF cannot function without location and activity tracking. Please enable them in the app settings.")
                .setPositiveButton("Settings") { _, _ ->
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                    }
                    startActivity(intent)
                }
                .setNegativeButton("Cancel") { dialog, _ ->
                    dialog.dismiss()
                    showEmptyState()
                }
                .show()
        }
    }

    private fun showEmptyState() {
        binding.permissionDeniedContainer.visibility = View.VISIBLE
        binding.btnStartWalk.isEnabled = false
        binding.fabRecenter.visibility = View.GONE
        bottomSheetBehavior.state = BottomSheetBehavior.STATE_COLLAPSED

        binding.btnOpenSettings.setOnClickListener {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
            startActivity(intent)
        }
    }

    private fun setupViewsAndMap() {
        binding.permissionDeniedContainer.visibility = View.GONE
        binding.btnStartWalk.isEnabled = true
        binding.fabRecenter.visibility = View.VISIBLE

        migrateHistoryLoopsToClaims()

        // Initialize Map
        val mapFragment = supportFragmentManager.findFragmentById(R.id.mapFragment) as SupportMapFragment
        mapFragment.getMapAsync(this)

        setupButtonListeners()
        observeViewModel()
        startLocationUpdates()
    }

    override fun onStart() {
        super.onStart()
        // Bind to TurfTrackerService
        val intent = Intent(this, TurfTrackerService::class.java)
        bindService(intent, viewModel.serviceConnection, Context.BIND_AUTO_CREATE)
    }

    override fun onStop() {
        unbindService(viewModel.serviceConnection)
        super.onStop()
    }

    override fun onMapReady(map: GoogleMap) {
        googleMap = map
        
        // Custom Style
        try {
            val styleOptions = MapStyleOptions.loadRawResourceStyle(this, R.raw.map_style)
            map.setMapStyle(styleOptions)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        map.apply {
            mapType = GoogleMap.MAP_TYPE_NORMAL
            uiSettings.isMyLocationButtonEnabled = false
            uiSettings.isCompassEnabled = true
            uiSettings.isZoomControlsEnabled = false
            uiSettings.isScrollGesturesEnabled = true
            uiSettings.isZoomGesturesEnabled = true
        }

        map.setOnCameraIdleListener {
            updateLabelMarkersVisibility()
        }

        // Camera move listener to disable snapping if user manually pans map
        map.setOnCameraMoveStartedListener { reason ->
            if (reason == GoogleMap.OnCameraMoveStartedListener.REASON_GESTURE) {
                shouldFollowCamera = false
            }
        }

        // Trigger updates if service is already active on orientation change
        updateMapOverlays(viewModel.uiState.value)

        // Draw persistent loops from past walk history
        drawHistoricalPolygons()

        map.setOnPolygonClickListener { polygon ->
            when (val tag = polygon.tag) {
                is ClaimedLoop -> {
                    showClaimedLoopDetailDialog(tag)
                }
                is com.yourname.turf.model.TurfLoop -> {
                    showClaimLoopDialog(tag)
                }
                is Pair<*, *> -> {
                    val session = tag.first as? com.yourname.turf.model.WalkSessionSummary
                    val loop = tag.second as? com.yourname.turf.model.TurfLoop
                    if (session != null && loop != null) {
                        showHistoricalLoopDialog(session, loop)
                    }
                }
            }
        }

        // Center on last known location on startup
        centerCameraOnLastLocation()
    }

    private fun setupButtonListeners() {
        binding.btnStartWalk.setOnClickListener {
            val intent = Intent(this, TurfTrackerService::class.java)
            startForegroundService(intent)
            viewModel.startWalk()
            shouldFollowCamera = true
        }

        binding.btnPauseResume.setOnClickListener {
            val state = viewModel.uiState.value
            if (state.sessionStatus == SessionStatus.ACTIVE) {
                viewModel.pauseWalk()
            } else if (state.sessionStatus == SessionStatus.PAUSED) {
                viewModel.resumeWalk()
                shouldFollowCamera = true
            }
        }

        binding.btnEndWalk.setOnClickListener {
            handleEndWalk()
        }

        binding.fabRecenter.setOnClickListener {
            shouldFollowCamera = true
            val marker = userMarker
            if (marker != null) {
                googleMap?.animateCamera(CameraUpdateFactory.newLatLngZoom(marker.position, 17f))
            } else {
                val locManager = com.yourname.turf.location.LocationManager(this)
                locManager.getLastLocation { location ->
                    if (location != null) {
                        val latLng = LatLng(location.latitude, location.longitude)
                        googleMap?.animateCamera(CameraUpdateFactory.newLatLngZoom(latLng, 17f))
                    } else {
                        Toast.makeText(this, "Location unavailable", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }
    }

    private fun centerCameraOnLastLocation() {
        val fineLocationGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        if (fineLocationGranted) {
            val locManager = com.yourname.turf.location.LocationManager(this)
            locManager.getLastLocation { location ->
                if (location != null) {
                    val latLng = LatLng(location.latitude, location.longitude)
                    googleMap?.moveCamera(CameraUpdateFactory.newLatLngZoom(latLng, 17f))
                }
            }
        }
    }

    private fun setupNavigationDrawer() {
        binding.fabMenu.setOnClickListener {
            binding.drawerLayout.openDrawer(GravityCompat.START)
        }

        binding.navigationView.setNavigationItemSelectedListener { menuItem ->
            binding.drawerLayout.closeDrawers()
            when (menuItem.itemId) {
                R.id.nav_track_walk -> {
                    // Already on map
                }
                R.id.nav_walk_history -> {
                    val historySheet = HistoryBottomSheet.newInstance()
                    historySheet.setOnDismissListener {
                        drawHistoricalPolygons()
                    }
                    historySheet.show(supportFragmentManager, HistoryBottomSheet.TAG)
                }
                R.id.nav_version_history -> {
                    showVersionHistoryDialog()
                }
            }
            true
        }
    }

    private fun showVersionHistoryDialog() {
        val dialogMessage = android.text.Html.fromHtml(
            "<h3><b>TURF v1.6.0 (v6)</b></h3>" +
            "<p>Latest version installed successfully.</p><br/>" +
            "<b>Version Changelog:</b><br/>" +
            "• <b>v1.6.0 (v6)</b> — Loop Claim & Name: Prompt to claim loops with a custom name upon capture, click active loops on map, and view names in history.<br/><br/>" +
            "• <b>v1.5.0 (v5)</b> — Advanced Metrics: Cadence in SPM, Elevation Gain/Climb in meters, and a live duration stopwatch tracker.<br/><br/>" +
            "• <b>v1.4.0 (v4)</b> — Directional Arrow: Dynamic flat-rotated user position marker based on real-time GPS bearing.<br/><br/>" +
            "• <b>v1.3.0 (v3)</b> — Persistent loops: Clickable historical loops drawn persistently on the map view.<br/><br/>" +
            "• <b>v1.2.0 (v2)</b> — Navigation & Logging: Drawer navigation, walk history session repository, and background crash logging.<br/><br/>" +
            "• <b>v1.0.0 (v1)</b> — Core Foundations: Fused Location updates, step tracking fallback, maps rendering, and foreground service tracking.",
            android.text.Html.FROM_HTML_MODE_LEGACY
        )

        AlertDialog.Builder(this)
            .setTitle("Version Info & History")
            .setMessage(dialogMessage)
            .setPositiveButton("Awesome", null)
            .show()
    }

    private fun handleEndWalk() {
        val map = googleMap
        val state = viewModel.uiState.value
        
        if (map != null && state.trailPoints.isNotEmpty()) {
            Toast.makeText(this, "Capturing map snapshot...", Toast.LENGTH_SHORT).show()
            
            // Recenter/zoom to fit the trail or user location before snapshot
            val lastPoint = state.trailPoints.last()
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(lastPoint, 17f))
            
            // Small delay to allow map tiles to render before snapshot
            binding.root.postDelayed({
                map.snapshot { bitmap ->
                    viewModel.endWalk()
                    showSummary(bitmap)
                }
            }, 300)
        } else {
            viewModel.endWalk()
            showSummary(null)
        }
    }

    private fun showSummary(snapshot: Bitmap?) {
        val summaryState = viewModel.lastSummaryState ?: return
        val durationSeconds = viewModel.lastSummaryDurationSeconds

        // Save completed walk to history repository
        try {
            val historyRepo = com.yourname.turf.model.HistoryRepository(this)
            val sdf = SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())
            val formattedDate = sdf.format(Date())
            val sessionSummary = com.yourname.turf.model.WalkSessionSummary(
                id = UUID.randomUUID().toString(),
                dateTime = formattedDate,
                steps = summaryState.steps,
                isStepEstimated = summaryState.isStepEstimated,
                distanceKm = summaryState.distanceKm,
                loopCount = summaryState.loopCount,
                durationSeconds = durationSeconds,
                loops = summaryState.capturedLoops,
                cadence = summaryState.cadence,
                elevationGainMetres = summaryState.elevationGainMetres
            )
            historyRepo.addSession(sessionSummary)
            
            // Refresh persistent map loops immediately
            drawHistoricalPolygons()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        val summarySheet = SummaryBottomSheet.newInstance()
        summarySheet.setSessionData(
            snapshot = snapshot,
            steps = summaryState.steps,
            isStepEstimated = summaryState.isStepEstimated,
            distanceKm = summaryState.distanceKm,
            loops = summaryState.loopCount,
            durationSeconds = durationSeconds,
            cadence = summaryState.cadence,
            elevationGainMetres = summaryState.elevationGainMetres,
            onDone = {
                viewModel.clearSummary()
                // Clear overlays from map
                googleMap?.clear()
                userMarker = null
                activePolyline = null
                activePolygons.clear()
                // Redraw persistent history loops
                drawHistoricalPolygons()
            }
        )
        summarySheet.show(supportFragmentManager, SummaryBottomSheet.TAG)
    }

    private val historicalPolygons = mutableListOf<Polygon>()

    private fun drawHistoricalPolygons() {
        val map = googleMap ?: return
        
        // Remove existing historical polygons
        for (poly in historicalPolygons) {
            poly.remove()
        }
        historicalPolygons.clear()

        // Remove existing historical label markers
        for (marker in historicalLabelMarkers) {
            marker.remove()
        }
        historicalLabelMarkers.clear()

        // Remove existing claimed label markers
        for (marker in claimedLabelMarkers) {
            marker.remove()
        }
        claimedLabelMarkers.clear()

        // Read claimed loops first
        val claimedRepo = com.yourname.turf.model.ClaimedLoopRepository(this)
        val claimedLoops = claimedRepo.getClaimedLoops()

        // 1. Draw Claimed Loops (dynamic colors, streak text labels)
        for (claimedLoop in claimedLoops) {
            val baseColor = claimedLoop.getDynamicColor()
            val fill = Color.argb(80, Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor))
            val stroke = Color.argb(200, Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor))

            val options = PolygonOptions()
                .addAll(claimedLoop.points)
                .fillColor(fill)
                .strokeColor(stroke)
                .strokeWidth(5f)
                .clickable(true)
            
            val addedPoly = map.addPolygon(options)
            addedPoly.tag = claimedLoop
            historicalPolygons.add(addedPoly)

            // Add text label with streak count
            val markerPos = getMarkerPosition(claimedLoop.points)
            val currentZoom = googleMap?.cameraPosition?.zoom ?: 0f
            val zoomedIn = currentZoom >= 15.5f
            val bitmap = if (zoomedIn) {
                createCardBitmap(claimedLoop.name, claimedLoop.streakCount, claimedLoop.coveredCountToday)
            } else {
                createDotBitmap()
            }
            val markerOptions = MarkerOptions()
                .position(markerPos)
                .icon(BitmapDescriptorFactory.fromBitmap(bitmap))
                .anchor(0.5f, 0.5f)
                .flat(true)
                .visible(true)
            val marker = map.addMarker(markerOptions)
            if (marker != null) {
                marker.tag = claimedLoop
                claimedLabelMarkers.add(marker)
            }
        }

        // 2. Read from walk history and draw historical unclaimed loops (green)
        val historyRepo = com.yourname.turf.model.HistoryRepository(this)
        val history = historyRepo.getHistory()

        for (session in history) {
            for (loop in session.loops) {
                // Skip if this loop is currently claimed
                if (claimedLoops.any { it.id == loop.id }) {
                    continue
                }

                val options = PolygonOptions()
                    .addAll(loop.points)
                    .fillColor(Color.argb(80, 76, 175, 80))
                    .strokeColor(Color.argb(200, 46, 125, 50))
                    .strokeWidth(3f)
                    .clickable(true)
                
                val addedPoly = map.addPolygon(options)
                addedPoly.tag = Pair(session, loop)
                historicalPolygons.add(addedPoly)

                // Add text label marker if loop has a name
                val loopName = loop.name
                if (!loopName.isNullOrEmpty()) {
                    val centroid = getCentroid(loop.points)
                    val bitmap = createTextBitmap(loopName)
                    val markerOptions = MarkerOptions()
                        .position(centroid)
                        .icon(BitmapDescriptorFactory.fromBitmap(bitmap))
                        .anchor(0.5f, 0.5f)
                        .flat(true)
                        .visible(googleMap?.cameraPosition?.zoom ?: 0f >= 15.5f)
                    val marker = map.addMarker(markerOptions)
                    if (marker != null) {
                        historicalLabelMarkers.add(marker)
                    }
                }
            }
        }
    }

    private fun showHistoricalLoopDialog(session: WalkSessionSummary, loop: com.yourname.turf.model.TurfLoop) {
        val minutes = session.durationSeconds / 60
        val seconds = session.durationSeconds % 60
        val durationStr = String.format("%02d:%02d", minutes, seconds)
        val stepsStr = if (session.isStepEstimated) "${session.steps} (est.)" else "${session.steps}"
        val loopNameStr = loop.name ?: "Unclaimed Loop"

        AlertDialog.Builder(this)
            .setTitle("Loop Area: $loopNameStr")
            .setMessage(
                "This loop was captured during a walk on ${session.dateTime}.\n\n" +
                "Session details:\n" +
                "• Steps: $stepsStr\n" +
                "• Distance: ${String.format("%.2f km", session.distanceKm)}\n" +
                "• Duration: $durationStr\n" +
                "• Session Loops: ${session.loopCount}\n" +
                "• Cadence: ${session.cadence} SPM\n" +
                "• Elevation Gain: ${String.format("%.1f m", session.elevationGainMetres)}"
            )
            .setPositiveButton("Close", null)
            .setNeutralButton("View Full History") { _, _ ->
                val historySheet = HistoryBottomSheet.newInstance()
                historySheet.setOnDismissListener {
                    drawHistoricalPolygons()
                }
                historySheet.show(supportFragmentManager, HistoryBottomSheet.TAG)
            }
            .show()
    }

    private fun showClaimLoopDialog(loop: com.yourname.turf.model.TurfLoop) {
        val input = android.widget.EditText(this).apply {
            hint = "e.g., Park Path, Garden Loop"
            setSingleLine(true)
            setText(loop.name ?: "")
            setSelection(text.length)
        }
        
        val container = android.widget.FrameLayout(this).apply {
            val padding = (16 * resources.displayMetrics.density).toInt()
            setPadding(padding, 8, padding, 8)
            addView(input)
        }

        AlertDialog.Builder(this)
            .setTitle(if (loop.name != null) "Rename Claimed Loop" else "Claim this Loop 🏆")
            .setMessage("Give this captured loop a name to claim it:")
            .setView(container)
            .setPositiveButton("Claim") { _, _ ->
                val name = input.text.toString().trim()
                if (name.isNotEmpty()) {
                    viewModel.nameLoop(loop.id, name)
                    
                    val claimedRepo = com.yourname.turf.model.ClaimedLoopRepository(this)
                    val existingClaim = claimedRepo.getClaimedLoops().find { it.id == loop.id }
                    if (existingClaim != null) {
                        claimedRepo.addOrUpdateClaimedLoop(existingClaim.copy(name = name))
                    } else {
                        val today = com.yourname.turf.model.ClaimedLoopRepository.getTodayDateString()
                        val newClaim = com.yourname.turf.model.ClaimedLoop(
                            id = loop.id,
                            name = name,
                            points = loop.points,
                            streakCount = 1,
                            lastCoveredDate = today,
                            coveredCountToday = 1
                        )
                        claimedRepo.addOrUpdateClaimedLoop(newClaim)
                    }
                    Toast.makeText(this, "Loop claimed as: $name", Toast.LENGTH_SHORT).show()
                    drawHistoricalPolygons()
                } else {
                    Toast.makeText(this, "Loop name cannot be empty", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Dismiss", null)
            .show()
    }

    private fun observeViewModel() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                // Collect UI Session states
                launch {
                    viewModel.uiState.collectLatest { state ->
                        updateUiControls(state)
                        updateMapOverlays(state)
                    }
                }

                // Collect loop events to show success dialog and prompt for claiming
                launch {
                    viewModel.loopCapturedEvent.collectLatest { loop ->
                        Snackbar.make(
                            binding.coordinatorLayout,
                            "Success! Turf Loop Captured! 🟢",
                            Snackbar.LENGTH_SHORT
                        ).show()
                        
                        showClaimLoopDialog(loop)
                    }
                }

                // Collect claimed loop cover events
                launch {
                    viewModel.claimedLoopCoveredEvent.collectLatest { claimedLoop ->
                        Snackbar.make(
                            binding.coordinatorLayout,
                            "Claimed Loop '${claimedLoop.name}' covered! 🔥 Streak: ${claimedLoop.streakCount} days (Covered ${claimedLoop.coveredCountToday} times today)",
                            Snackbar.LENGTH_LONG
                        ).show()
                        
                        // Force redraw of loops to update color/labels
                        drawHistoricalPolygons()
                    }
                }
                
                // Monitor service binding to show step sensor availability toasts
                launch {
                    viewModel.serviceBoundState.collectLatest { service ->
                        if (service != null && !service.sessionState.value.isStepEstimated && !service.sessionState.value.gpsSignalWeak) {
                            // If steps fall back to GPS on active walk, notify the user once
                        }
                    }
                }
            }
        }
    }

    private fun updateUiControls(state: TurfSessionState) {
        // Steps metric
        if (state.isStepEstimated) {
            binding.tvStepsVal.text = "${state.steps}"
            binding.tvStepsLbl.text = "Steps (est.)"
        } else {
            binding.tvStepsVal.text = state.steps.toString()
            binding.tvStepsLbl.text = getString(R.string.steps)
        }

        // Distance and loops
        binding.tvDistanceVal.text = String.format("%.2f", state.distanceKm)
        binding.tvLoopsVal.text = state.loopCount.toString()

        // Cadence, Elevation, and stopwatch Duration
        binding.tvCadenceVal.text = state.cadence.toString()
        binding.tvElevationVal.text = String.format("%.1f", state.elevationGainMetres)
        val minutes = state.durationSeconds / 60
        val seconds = state.durationSeconds % 60
        binding.tvLiveDurationVal.text = String.format("%02d:%02d", minutes, seconds)

        // Handle State-specific UI controls
        when (state.sessionStatus) {
            SessionStatus.IDLE -> {
                binding.btnStartWalk.visibility = View.VISIBLE
                binding.activeControlsContainer.visibility = View.GONE
                binding.walkPausedChip.visibility = View.GONE
                binding.weakGpsChip.visibility = View.GONE
            }
            SessionStatus.ACTIVE -> {
                binding.btnStartWalk.visibility = View.GONE
                binding.activeControlsContainer.visibility = View.VISIBLE
                binding.btnPauseResume.text = getString(R.string.pause)
                binding.btnPauseResume.setBackgroundColor(ContextCompat.getColor(this, R.color.gray_medium))
                binding.btnPauseResume.setTextColor(ContextCompat.getColor(this, R.color.text_primary))
                binding.walkPausedChip.visibility = View.GONE
                binding.weakGpsChip.visibility = if (state.gpsSignalWeak) View.VISIBLE else View.GONE
            }
            SessionStatus.PAUSED -> {
                binding.btnStartWalk.visibility = View.GONE
                binding.activeControlsContainer.visibility = View.VISIBLE
                binding.btnPauseResume.text = getString(R.string.resume)
                binding.btnPauseResume.setBackgroundColor(ContextCompat.getColor(this, R.color.primary))
                binding.btnPauseResume.setTextColor(Color.WHITE)
                binding.walkPausedChip.visibility = View.VISIBLE
                binding.weakGpsChip.visibility = View.GONE
            }
        }
    }

    private fun updateMapOverlays(state: TurfSessionState) {
        val map = googleMap ?: return

        // 1. Draw Active Polyline
        activePolyline?.remove()
        if (state.trailPoints.isNotEmpty()) {
            val trailColor = state.activeTrailColor ?: Color.parseColor("#E53935")
            val options = PolylineOptions()
                .addAll(state.trailPoints)
                .color(trailColor)
                .width(8f)
                .jointType(JointType.ROUND)
                .startCap(RoundCap())
                .endCap(RoundCap())
            activePolyline = map.addPolyline(options)
        } else {
            activePolyline = null
        }

        // 2. Draw Captured Loop Polygons
        for (poly in activePolygons) {
            poly.remove()
        }
        activePolygons.clear()

        for (marker in activeLabelMarkers) {
            marker.remove()
        }
        activeLabelMarkers.clear()

        val claimedRepo = com.yourname.turf.model.ClaimedLoopRepository(this)
        val claimedLoops = claimedRepo.getClaimedLoops()

        for (loop in state.capturedLoops) {
            val claimedLoop = claimedLoops.find { it.id == loop.id }
            val options = PolygonOptions()
                .addAll(loop.points)
                .clickable(true)

            if (claimedLoop != null) {
                val baseColor = claimedLoop.getDynamicColor()
                val fill = Color.argb(80, Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor))
                val stroke = Color.argb(200, Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor))
                options.fillColor(fill)
                       .strokeColor(stroke)
                       .strokeWidth(5f)
            } else {
                options.fillColor(Color.argb(80, 76, 175, 80)) // rgba(76, 175, 80, 0.31)
                       .strokeColor(Color.argb(200, 46, 125, 50)) // rgba(46, 125, 50, 0.78)
                       .strokeWidth(3f)
            }

            val addedPoly = map.addPolygon(options)
            addedPoly.tag = claimedLoop ?: loop
            activePolygons.add(addedPoly)

            // Add text label
            val markerPos = if (claimedLoop != null) getMarkerPosition(loop.points) else getCentroid(loop.points)
            val currentZoom = googleMap?.cameraPosition?.zoom ?: 0f
            val zoomedIn = currentZoom >= 15.5f
            val bitmap = if (claimedLoop != null) {
                if (zoomedIn) {
                    createCardBitmap(claimedLoop.name, claimedLoop.streakCount, claimedLoop.coveredCountToday)
                } else {
                    createDotBitmap()
                }
            } else if (!loop.name.isNullOrEmpty()) {
                createTextBitmap(loop.name)
            } else {
                null
            }

            if (bitmap != null) {
                val markerOptions = MarkerOptions()
                    .position(markerPos)
                    .icon(BitmapDescriptorFactory.fromBitmap(bitmap))
                    .anchor(0.5f, 0.5f)
                    .flat(true)
                    .visible(if (claimedLoop != null) true else currentZoom >= 15.5f)
                val marker = map.addMarker(markerOptions)
                if (marker != null) {
                    marker.tag = claimedLoop ?: loop
                    activeLabelMarkers.add(marker)
                }
            }
        }

        // 3. User Marker position
        val lastPoint = state.trailPoints.lastOrNull() ?: lastKnownLatLng
        if (lastPoint != null) {
            if (userMarker == null) {
                userMarker = map.addMarker(
                    MarkerOptions()
                        .position(lastPoint)
                        .icon(userIconDescriptor)
                        .anchor(0.5f, 0.5f)
                        .flat(true)
                )
            } else {
                userMarker?.position = lastPoint
            }
            userMarker?.rotation = currentHeading

            if (shouldFollowCamera && state.sessionStatus == SessionStatus.ACTIVE) {
                map.animateCamera(CameraUpdateFactory.newLatLngZoom(lastPoint, 17f))
            }
        } else {
            userMarker?.remove()
            userMarker = null
        }
    }

    private fun createUserPositionIcon(): BitmapDescriptor {
        val size24dp = (24 * resources.displayMetrics.density).toInt()
        val size40dp = (40 * resources.displayMetrics.density).toInt()

        val bitmap = Bitmap.createBitmap(size40dp, size40dp, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val center = size40dp / 2f

        // Pulsing Transparent outer ring
        val ringPaint = Paint().apply {
            color = Color.parseColor("#402196F3")
            style = Paint.Style.FILL
            isAntiAlias = true
        }
        canvas.drawCircle(center, center, size40dp / 2f, ringPaint)

        // Core solid blue dot
        val dotPaint = Paint().apply {
            color = Color.parseColor("#2196F3")
            style = Paint.Style.FILL
            isAntiAlias = true
        }
        canvas.drawCircle(center, center, size24dp / 2f, dotPaint)

        // Draw directional pointer arrowhead pointing straight UP (North)
        val arrowPath = android.graphics.Path().apply {
            val arrowHeight = 8f * resources.displayMetrics.density
            val arrowWidth = 10f * resources.displayMetrics.density
            
            // Peak of arrow
            moveTo(center, center - (size24dp / 2f) - arrowHeight)
            // Bottom-left corner
            lineTo(center - (arrowWidth / 2f), center - (size24dp / 2f) + (2f * resources.displayMetrics.density))
            // Bottom-right corner
            lineTo(center + (arrowWidth / 2f), center - (size24dp / 2f) + (2f * resources.displayMetrics.density))
            close()
        }
        canvas.drawPath(arrowPath, dotPaint)

        // Contrast white outline for blue dot
        val outlinePaint = Paint().apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = 2f * resources.displayMetrics.density
            isAntiAlias = true
        }
        canvas.drawCircle(center, center, size24dp / 2f, outlinePaint)

        // Contrast white outline for arrowhead
        val arrowOutlinePaint = Paint().apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = 1.5f * resources.displayMetrics.density
            isAntiAlias = true
        }
        canvas.drawPath(arrowPath, arrowOutlinePaint)

        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }

    private fun startLocationUpdates() {
        val fineLocationGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        if (fineLocationGranted) {
            activityLocationManager.startLocationUpdates { location ->
                val latLng = LatLng(location.latitude, location.longitude)
                lastKnownLatLng = latLng
                updateMapOverlays(viewModel.uiState.value)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        rotationSensor?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        val fineLocationGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        if (fineLocationGranted && ::activityLocationManager.isInitialized) {
            startLocationUpdates()
        }
    }

    override fun onPause() {
        super.onPause()
        sensorManager.unregisterListener(this)
        if (::activityLocationManager.isInitialized) {
            activityLocationManager.stopLocationUpdates()
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
            val rotationMatrix = FloatArray(9)
            SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
            val orientationValues = FloatArray(3)
            SensorManager.getOrientation(rotationMatrix, orientationValues)
            val azimuthInRadians = orientationValues[0]
            var azimuthInDegrees = Math.toDegrees(azimuthInRadians.toDouble()).toFloat()
            if (azimuthInDegrees < 0) {
                azimuthInDegrees += 360f
            }
            currentHeading = azimuthInDegrees
            userMarker?.rotation = currentHeading
        } else if (event.sensor.type == Sensor.TYPE_ORIENTATION) {
            val azimuthInDegrees = event.values[0]
            currentHeading = azimuthInDegrees
            userMarker?.rotation = currentHeading
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No-op
    }

    private fun updateLabelMarkersVisibility() {
        val map = googleMap ?: return
        val zoom = map.cameraPosition.zoom
        val zoomedInEnough = zoom >= 15.5f
        
        // Standard historical labels (unclaimed) are only visible when zoomed in
        val historicalVisible = zoom >= 15.5f
        for (marker in historicalLabelMarkers) {
            marker.isVisible = historicalVisible
        }

        // Active session labels
        for (marker in activeLabelMarkers) {
            val tag = marker.tag
            if (tag is ClaimedLoop) {
                marker.isVisible = true
                val bitmap = if (zoomedInEnough) {
                    createCardBitmap(tag.name, tag.streakCount, tag.coveredCountToday)
                } else {
                    createDotBitmap()
                }
                marker.setIcon(BitmapDescriptorFactory.fromBitmap(bitmap))
            } else {
                marker.isVisible = historicalVisible
            }
        }

        // Claimed loop labels
        for (marker in claimedLabelMarkers) {
            val tag = marker.tag
            if (tag is ClaimedLoop) {
                marker.isVisible = true
                val bitmap = if (zoomedInEnough) {
                    createCardBitmap(tag.name, tag.streakCount, tag.coveredCountToday)
                } else {
                    createDotBitmap()
                }
                marker.setIcon(BitmapDescriptorFactory.fromBitmap(bitmap))
            }
        }
    }

    private fun getCentroid(points: List<LatLng>): LatLng {
        if (points.isEmpty()) return LatLng(0.0, 0.0)
        var lat = 0.0
        var lng = 0.0
        for (p in points) {
            lat += p.latitude
            lng += p.longitude
        }
        return LatLng(lat / points.size, lng / points.size)
    }

    private fun createTextBitmap(text: String): Bitmap {
        val textPaint = Paint().apply {
            color = Color.parseColor("#2E7D32")
            textSize = 36f
            isAntiAlias = true
            style = Paint.Style.FILL
            textAlign = Paint.Align.CENTER
            typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
        }
        
        val outlinePaint = Paint().apply {
            color = Color.WHITE
            textSize = 36f
            isAntiAlias = true
            style = Paint.Style.STROKE
            strokeWidth = 6f
            strokeJoin = Paint.Join.ROUND
            strokeCap = Paint.Cap.ROUND
            textAlign = Paint.Align.CENTER
            typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
        }
        
        val textBounds = android.graphics.Rect()
        textPaint.getTextBounds(text, 0, text.length, textBounds)
        
        val safetyPadding = 8
        val width = textBounds.width() + safetyPadding * 2
        val height = textBounds.height() + safetyPadding * 2
        
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val textX = width / 2f
        val textY = (height / 2f) - textBounds.exactCenterY()
        
        // Draw the outline/halo first
        canvas.drawText(text, textX, textY, outlinePaint)
        // Draw the filled text on top
        canvas.drawText(text, textX, textY, textPaint)
        
        return bitmap
    }

    private fun showClaimedLoopDetailDialog(loop: ClaimedLoop) {
        val input = android.widget.EditText(this).apply {
            hint = "e.g., Park Path, Garden Loop"
            setSingleLine(true)
            setText(loop.name)
            setSelection(text.length)
        }
        
        val container = android.widget.FrameLayout(this).apply {
            val padding = (16 * resources.displayMetrics.density).toInt()
            setPadding(padding, 8, padding, 8)
            addView(input)
        }

        AlertDialog.Builder(this)
            .setTitle("Claimed Loop: ${loop.name} 🏆")
            .setMessage(
                "🔥 Streak: ${loop.streakCount} days\n" +
                "🔄 Covered today: ${loop.coveredCountToday} times\n" +
                "📅 Last covered: ${loop.lastCoveredDate}\n\n" +
                "Rename this claimed loop:"
            )
            .setView(container)
            .setPositiveButton("Save") { _, _ ->
                val newName = input.text.toString().trim()
                if (newName.isNotEmpty()) {
                    val updated = loop.copy(name = newName)
                    val claimedRepo = com.yourname.turf.model.ClaimedLoopRepository(this)
                    claimedRepo.addOrUpdateClaimedLoop(updated)
                    Toast.makeText(this, "Loop renamed to: $newName", Toast.LENGTH_SHORT).show()
                    drawHistoricalPolygons()
                }
            }
            .setNegativeButton("Close", null)
            .setNeutralButton("Abandon Claim") { _, _ ->
                AlertDialog.Builder(this)
                    .setTitle("Abandon Claim?")
                    .setMessage("Are you sure you want to abandon the claim on '${loop.name}'? Your streak will be lost.")
                    .setPositiveButton("Yes, Abandon") { _, _ ->
                        val claimedRepo = com.yourname.turf.model.ClaimedLoopRepository(this)
                        claimedRepo.deleteClaim(loop.id)
                        Toast.makeText(this, "Claim abandoned", Toast.LENGTH_SHORT).show()
                        drawHistoricalPolygons()
                    }
                    .setNegativeButton("Cancel", null)
                    .show()
            }
            .show()
    }

    private fun createDotBitmap(): Bitmap {
        val density = resources.displayMetrics.density
        val size = (16 * density).toInt()
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val center = size / 2f
        val radius = 6f * density
        
        val borderPaint = Paint().apply {
            color = Color.parseColor("#0D47A1") // Dark Blue border
            style = Paint.Style.STROKE
            strokeWidth = 2f * density
            isAntiAlias = true
        }
        
        val fillPaint = Paint().apply {
            color = Color.WHITE
            style = Paint.Style.FILL
            isAntiAlias = true
        }
        
        canvas.drawCircle(center, center, radius, fillPaint)
        canvas.drawCircle(center, center, radius, borderPaint)
        return bitmap
    }

    private fun getMarkerPosition(points: List<LatLng>): LatLng {
        if (points.isEmpty()) return LatLng(0.0, 0.0)
        var maxLat = -90.0
        var bestPoint = points[0]
        for (p in points) {
            if (p.latitude > maxLat) {
                maxLat = p.latitude
                bestPoint = p
            }
        }
        // Place it 0.00012 degrees north (approx 13 metres north of the northernmost boundary point)
        return LatLng(bestPoint.latitude + 0.00012, bestPoint.longitude)
    }

    private fun createCardBitmap(name: String, streak: Int, coveredCount: Int): Bitmap {
        val density = resources.displayMetrics.density
        
        val heroPaint = Paint().apply {
            color = Color.parseColor("#0D47A1") // Vibrant Deep Blue
            textSize = 15f * density
            isAntiAlias = true
            textAlign = Paint.Align.CENTER
            typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
        }
        
        val subtextPaint = Paint().apply {
            color = Color.parseColor("#555555") // Slate Gray
            textSize = 12f * density
            isAntiAlias = true
            textAlign = Paint.Align.CENTER
            typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.NORMAL)
        }
        
        val daysWord = if (streak == 1) "day" else "days"
        val loopsWord = if (coveredCount == 1) "loop" else "loops"
        
        val line1 = "$streak $daysWord of $name"
        val line2 = "$coveredCount $loopsWord done today"
        
        val b1 = android.graphics.Rect()
        heroPaint.getTextBounds(line1, 0, line1.length, b1)
        val b2 = android.graphics.Rect()
        subtextPaint.getTextBounds(line2, 0, line2.length, b2)
        
        val textWidth = maxOf(b1.width(), b2.width())
        val paddingX = 16f * density
        val paddingY = 12f * density
        
        val cardWidth = textWidth + paddingX * 2
        val lineSpacing = 6f * density
        val cardHeight = b1.height() + b2.height() + paddingY * 2 + lineSpacing
        
        val bitmap = Bitmap.createBitmap(cardWidth.toInt(), cardHeight.toInt(), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val cardPaint = Paint().apply {
            color = Color.WHITE
            style = Paint.Style.FILL
            isAntiAlias = true
            setShadowLayer(4f * density, 0f, 2f * density, Color.parseColor("#30000000"))
        }
        
        val borderPaint = Paint().apply {
            color = Color.parseColor("#B0BEC5") // Light Gray-blue border
            style = Paint.Style.STROKE
            strokeWidth = 1.5f * density
            isAntiAlias = true
        }
        
        val shadowPadding = 4f * density
        val rectF = android.graphics.RectF(shadowPadding, shadowPadding, cardWidth - shadowPadding, cardHeight - shadowPadding)
        val cornerRadius = 8f * density
        canvas.drawRoundRect(rectF, cornerRadius, cornerRadius, cardPaint)
        canvas.drawRoundRect(rectF, cornerRadius, cornerRadius, borderPaint)
        
        val centerX = cardWidth / 2f
        val y1 = paddingY + b1.height().toFloat()
        val y2 = y1 + b2.height() + lineSpacing
        
        canvas.drawText(line1, centerX, y1, heroPaint)
        canvas.drawText(line2, centerX, y2, subtextPaint)
        
        return bitmap
    }

    private fun migrateHistoryLoopsToClaims() {
        try {
            val historyRepo = com.yourname.turf.model.HistoryRepository(this)
            val claimedRepo = com.yourname.turf.model.ClaimedLoopRepository(this)
            val history = historyRepo.getHistory()
            val claimed = claimedRepo.getClaimedLoops().toMutableList()
            val today = com.yourname.turf.model.ClaimedLoopRepository.getTodayDateString()
            
            var migrated = false
            for (session in history) {
                for (loop in session.loops) {
                    if (!loop.name.isNullOrEmpty()) {
                        if (claimed.none { it.id == loop.id }) {
                            val newClaim = com.yourname.turf.model.ClaimedLoop(
                                id = loop.id,
                                name = loop.name,
                                points = loop.points,
                                streakCount = 1,
                                lastCoveredDate = today,
                                coveredCountToday = 1
                            )
                            claimed.add(newClaim)
                            migrated = true
                        }
                    }
                }
            }
            if (migrated) {
                claimedRepo.saveClaimedLoops(claimed)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
