package com.yourname.turf.ui

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
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

class MapActivity : AppCompatActivity(), OnMapReadyCallback {

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

        // Initialize Map
        val mapFragment = supportFragmentManager.findFragmentById(R.id.mapFragment) as SupportMapFragment
        mapFragment.getMapAsync(this)

        setupButtonListeners()
        observeViewModel()
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

        // Set listener for taps on persistent or active loops
        map.setOnPolygonClickListener { polygon ->
            when (val tag = polygon.tag) {
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

        // Read from history
        val historyRepo = com.yourname.turf.model.HistoryRepository(this)
        val history = historyRepo.getHistory()

        for (session in history) {
            for (loop in session.loops) {
                val options = PolygonOptions()
                    .addAll(loop.points)
                    .fillColor(Color.argb(80, 76, 175, 80))
                    .strokeColor(Color.argb(200, 46, 125, 50))
                    .strokeWidth(3f)
                    .clickable(true)
                
                val addedPoly = map.addPolygon(options)
                addedPoly.tag = Pair(session, loop)
                historicalPolygons.add(addedPoly)
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
                    Toast.makeText(this, "Loop claimed as: $name", Toast.LENGTH_SHORT).show()
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
            val options = PolylineOptions()
                .addAll(state.trailPoints)
                .color(Color.parseColor("#E53935")) // Crimson red
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

        for (loop in state.capturedLoops) {
            val options = PolygonOptions()
                .addAll(loop.points)
                .fillColor(Color.argb(80, 76, 175, 80)) // rgba(76, 175, 80, 0.31)
                .strokeColor(Color.argb(200, 46, 125, 50)) // rgba(46, 125, 50, 0.78)
                .strokeWidth(3f)
                .clickable(true)
            val addedPoly = map.addPolygon(options)
            addedPoly.tag = loop
            activePolygons.add(addedPoly)
        }

        // 3. User Marker position
        // When active, the user position is the last trail point.
        // Otherwise we check for the last known GPS location in standard map settings.
        val lastPoint = state.trailPoints.lastOrNull()
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
            userMarker?.rotation = state.bearing

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
}
