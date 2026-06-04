package com.yourname.turf.loop

import com.google.android.gms.maps.model.LatLng
import kotlin.math.*

object LoopDetector {
    const val LOOP_THRESHOLD_METRES = 25f
    const val MIN_TRAIL_POINTS = 20

    /**
     * Checks if the last point in [trailPoints] closes a loop back to the first point of the trail.
     */
    fun isLoopClosed(trailPoints: List<LatLng>): Boolean {
        if (trailPoints.size <= MIN_TRAIL_POINTS) return false

        val startPoint = trailPoints.first()
        val newPoint = trailPoints.last()

        val distance = calculateDistanceMetres(
            startPoint.latitude, startPoint.longitude,
            newPoint.latitude, newPoint.longitude
        )

        return distance < LOOP_THRESHOLD_METRES
    }

    /**
     * Haversine formula to compute distance between two coordinates in metres
     */
    fun calculateDistanceMetres(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ): Double {
        val r = 6371000.0 // Earth radius in metres
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2.0).pow(2.0) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2.0).pow(2.0)
        val c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        return r * c
    }
}
