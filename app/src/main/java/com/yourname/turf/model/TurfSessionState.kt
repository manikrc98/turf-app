package com.yourname.turf.model

import com.google.android.gms.maps.model.LatLng

data class TurfSessionState(
    val steps: Int = 0,
    val isStepEstimated: Boolean = false,
    val distanceKm: Double = 0.0,
    val loopCount: Int = 0,
    val trailPoints: List<LatLng> = emptyList(),
    val capturedLoops: List<TurfLoop> = emptyList(),
    val sessionStatus: SessionStatus = SessionStatus.IDLE,
    val gpsSignalWeak: Boolean = false,
    val bearing: Float = 0f,
    val cadence: Int = 0,
    val elevationGainMetres: Double = 0.0,
    val durationSeconds: Long = 0L
)
