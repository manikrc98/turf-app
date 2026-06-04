package com.yourname.turf.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.NotificationCompat
import androidx.lifecycle.LifecycleService
import com.google.android.gms.maps.model.LatLng
import com.yourname.turf.location.LocationManager
import com.yourname.turf.loop.LoopDetector
import com.yourname.turf.model.SessionStatus
import com.yourname.turf.model.TurfSessionState
import com.yourname.turf.sensor.StepCounterManager
import com.yourname.turf.ui.MapActivity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class TurfTrackerService : LifecycleService() {

    private val binder = TurfBinder()

    private lateinit var locationManager: LocationManager
    private lateinit var stepCounterManager: StepCounterManager

    private val _sessionState = MutableStateFlow(TurfSessionState())
    val sessionState: StateFlow<TurfSessionState> = _sessionState.asStateFlow()

    // Tracking duration
    private var startTimeMillis: Long = 0L
    private var accumulatedTimeMillis: Long = 0L
    private var isTimerRunning = false
    private var timerJob: Job? = null

    // Fallback step calculations
    private var lastLocationForDistance: Location? = null
    private var totalGpsDistanceMetres: Double = 0.0

    // Elevation Gain calculations
    private var lastAltitude: Double? = null
    private var totalElevationGainMetres: Double = 0.0

    // Event listener for loop capture to trigger UI notifications
    private var onLoopCapturedListener: ((com.yourname.turf.model.TurfLoop) -> Unit)? = null

    inner class TurfBinder : Binder() {
        fun getService(): TurfTrackerService = this@TurfTrackerService
    }

    override fun onCreate() {
        super.onCreate()
        locationManager = LocationManager(this)
        stepCounterManager = StepCounterManager(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        if (intent?.action == ACTION_STOP) {
            endWalk()
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent): IBinder {
        super.onBind(intent)
        return binder
    }

    fun setOnLoopCapturedListener(listener: (com.yourname.turf.model.TurfLoop) -> Unit) {
        this.onLoopCapturedListener = listener
    }

    fun nameLoop(loopId: String, name: String) {
        _sessionState.update { state ->
            val updatedLoops = state.capturedLoops.map { loop ->
                if (loop.id == loopId) {
                    loop.copy(name = name)
                } else {
                    loop
                }
            }
            state.copy(capturedLoops = updatedLoops)
        }
    }

    fun startWalk() {
        if (_sessionState.value.sessionStatus != SessionStatus.IDLE) return

        _sessionState.value = TurfSessionState(
            sessionStatus = SessionStatus.ACTIVE
        )
        
        startTimeMillis = System.currentTimeMillis()
        accumulatedTimeMillis = 0L
        isTimerRunning = true
        
        lastLocationForDistance = null
        totalGpsDistanceMetres = 0.0
        
        lastAltitude = null
        totalElevationGainMetres = 0.0

        // Start Foreground
        startForeground(NOTIFICATION_ID, buildNotification(0, 0.0, 0))

        // Start location and step tracking
        startTracking()
        startTimer()
    }

    fun pauseWalk() {
        if (_sessionState.value.sessionStatus != SessionStatus.ACTIVE) return

        isTimerRunning = false
        accumulatedTimeMillis += System.currentTimeMillis() - startTimeMillis

        _sessionState.update { it.copy(sessionStatus = SessionStatus.PAUSED) }
        
        stopTracking()
        stopTimer()
        updateNotification()
    }

    fun resumeWalk() {
        if (_sessionState.value.sessionStatus != SessionStatus.PAUSED) return

        startTimeMillis = System.currentTimeMillis()
        isTimerRunning = true

        _sessionState.update { it.copy(sessionStatus = SessionStatus.ACTIVE) }

        startTracking()
        startTimer()
        updateNotification()
    }

    fun endWalk() {
        isTimerRunning = false
        stopTracking()
        stopTimer()
        
        _sessionState.update { it.copy(sessionStatus = SessionStatus.IDLE) }
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    fun getSessionDurationSeconds(): Long {
        if (!isTimerRunning) {
            return accumulatedTimeMillis / 1000L
        }
        val currentElapsed = System.currentTimeMillis() - startTimeMillis
        return (accumulatedTimeMillis + currentElapsed) / 1000L
    }

    private fun startTimer() {
        timerJob?.cancel()
        timerJob = lifecycleScope.launch {
            while (isTimerRunning) {
                delay(1000L)
                val elapsedSeconds = getSessionDurationSeconds()
                val state = _sessionState.value
                val stepsCount = state.steps
                
                val currentCadence = if (elapsedSeconds > 10) {
                    ((stepsCount.toDouble() / elapsedSeconds.toDouble()) * 60.0).toInt()
                } else {
                    0
                }
                
                _sessionState.update {
                    it.copy(
                        durationSeconds = elapsedSeconds,
                        cadence = currentCadence
                    )
                }
            }
        }
    }

    private fun stopTimer() {
        timerJob?.cancel()
        timerJob = null
    }

    private fun startTracking() {
        // Start Location Updates
        locationManager.startLocationUpdates { location ->
            handleLocationUpdate(location)
        }

        // Start Steps Tracking
        stepCounterManager.start { steps ->
            if (_sessionState.value.sessionStatus == SessionStatus.ACTIVE) {
                val distance = StepCounterManager.calculateDistanceKm(steps)
                _sessionState.update {
                    it.copy(
                        steps = steps,
                        isStepEstimated = false,
                        distanceKm = distance
                    )
                }
                updateNotification()
            }
        }
    }

    private fun stopTracking() {
        locationManager.stopLocationUpdates()
        stepCounterManager.stop()
        lastLocationForDistance = null
    }

    private fun handleLocationUpdate(location: Location) {
        val isWeak = location.accuracy > 20f
        
        _sessionState.update { it.copy(gpsSignalWeak = isWeak) }

        if (isWeak) {
            // Pause trail collection for weak GPS
            return
        }

        val newLatLng = LatLng(location.latitude, location.longitude)
        val currentBearing = if (location.hasBearing()) location.bearing else _sessionState.value.bearing
        
        // Track Altitude / Elevation Gain
        if (location.hasAltitude()) {
            val currentAltitude = location.altitude
            lastAltitude?.let { lastAlt ->
                val diff = currentAltitude - lastAlt
                if (diff > 1.5) { // Threshold to filter minor vertical GPS fluctuations
                    totalElevationGainMetres += diff
                }
            }
            lastAltitude = currentAltitude
        }

        // Handle step/distance fallback estimation if sensor is not available
        if (!stepCounterManager.isSensorAvailable) {
            lastLocationForDistance?.let { lastLoc ->
                val distanceDelta = lastLoc.distanceTo(location).toDouble()
                totalGpsDistanceMetres += distanceDelta
                val distanceKm = totalGpsDistanceMetres / 1000.0
                val estimatedSteps = StepCounterManager.estimateSteps(distanceKm)
                _sessionState.update {
                    it.copy(
                        steps = estimatedSteps,
                        isStepEstimated = true,
                        distanceKm = distanceKm,
                        bearing = currentBearing,
                        elevationGainMetres = totalElevationGainMetres
                    )
                }
            }
            lastLocationForDistance = location
        }

        // Add point to trail
        _sessionState.update { state ->
            val updatedTrail = state.trailPoints + newLatLng
            
            // Check loop closure
            if (LoopDetector.isLoopClosed(updatedTrail)) {
                triggerHapticFeedback()
                val newLoop = com.yourname.turf.model.TurfLoop(points = updatedTrail)
                onLoopCapturedListener?.invoke(newLoop)

                val newCapturedLoops = state.capturedLoops + newLoop
                
                state.copy(
                    loopCount = state.loopCount + 1,
                    trailPoints = listOf(newLatLng), // Reset trail starting from current position
                    capturedLoops = newCapturedLoops,
                    bearing = currentBearing,
                    elevationGainMetres = totalElevationGainMetres
                )
            } else {
                state.copy(
                    trailPoints = updatedTrail,
                    bearing = currentBearing,
                    elevationGainMetres = totalElevationGainMetres
                )
            }
        }
        
        updateNotification()
    }

    private fun triggerHapticFeedback() {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as android.os.VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(60, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(60)
        }
    }

    private fun updateNotification() {
        val state = _sessionState.value
        if (state.sessionStatus != SessionStatus.IDLE) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, buildNotification(state.steps, state.distanceKm, state.loopCount))
        }
    }

    private fun buildNotification(steps: Int, distanceKm: Double, loops: Int): Notification {
        val intent = Intent(this, MapActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, TurfTrackerService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val contentText = String.format(
            "%d steps · %.1f km · %d %s captured",
            steps,
            distanceKm,
            loops,
            if (loops == 1) "loop" else "loops"
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(com.yourname.turf.R.string.notification_title))
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                getString(com.yourname.turf.R.string.end_walk),
                stopPendingIntent
            )
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(com.yourname.turf.R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }

    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "turf_walk_channel"
        const val ACTION_STOP = "com.yourname.turf.ACTION_STOP"
    }
}
