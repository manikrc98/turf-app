package com.yourname.turf.loop

import com.google.android.gms.maps.model.LatLng
import kotlin.math.*

object LoopDetector {
    const val LOOP_THRESHOLD_METRES = 15f
    const val MIN_TRAIL_POINTS = 20

    /**
     * Checks if the last point in [trailPoints] closes a loop.
     */
    fun isLoopClosed(trailPoints: List<LatLng>): Boolean {
        return findLoopClosureIndex(trailPoints) != -1
    }

    /**
     * Finds the index of the point where the loop closes (i.e. the last point is close to a historical point).
     * Only checks points up to `trailPoints.size - MIN_TRAIL_POINTS` to avoid false closures on consecutive points.
     * Returns -1 if no loop is detected.
     */
    fun findLoopClosureIndex(trailPoints: List<LatLng>): Int {
        if (trailPoints.size <= MIN_TRAIL_POINTS) return -1

        val newPoint = trailPoints.last()
        val searchLimit = trailPoints.size - MIN_TRAIL_POINTS

        for (i in 0..searchLimit) {
            val historicalPoint = trailPoints[i]
            val distance = calculateDistanceMetres(
                historicalPoint.latitude, historicalPoint.longitude,
                newPoint.latitude, newPoint.longitude
            )
            if (distance < LOOP_THRESHOLD_METRES) {
                return i
            }
        }
        return -1
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
