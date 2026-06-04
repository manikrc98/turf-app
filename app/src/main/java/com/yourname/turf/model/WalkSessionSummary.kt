package com.yourname.turf.model

import com.google.android.gms.maps.model.LatLng

data class WalkSessionSummary(
    val id: String,
    val dateTime: String,
    val steps: Int,
    val isStepEstimated: Boolean,
    val distanceKm: Double,
    val loopCount: Int,
    val durationSeconds: Long,
    val loops: List<TurfLoop> = emptyList(),
    val cadence: Int = 0,
    val elevationGainMetres: Double = 0.0
)
