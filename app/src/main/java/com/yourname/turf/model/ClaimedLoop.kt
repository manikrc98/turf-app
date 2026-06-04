package com.yourname.turf.model

import android.graphics.Color
import com.google.android.gms.maps.model.LatLng

data class ClaimedLoop(
    val id: String,
    val name: String,
    val points: List<LatLng>,
    val streakCount: Int,
    val lastCoveredDate: String, // "yyyy-MM-dd"
    val coveredCountToday: Int
) {
    fun getDynamicColor(): Int {
        return getDynamicColorForCompletions(coveredCountToday)
    }

    companion object {
        fun getDynamicColorForCompletions(completions: Int): Int {
            val maxCompletions = 50
            val c = completions.coerceIn(1, maxCompletions)
            val t = (c - 1).toFloat() / (maxCompletions - 1).toFloat() // 0.0 to 1.0
            
            val r: Float
            val g: Float
            val b: Float
            
            if (t < 0.4f) {
                val segmentT = t / 0.4f
                // Blue (33, 150, 243) to Yellow (255, 235, 59)
                r = 33f + (255f - 33f) * segmentT
                g = 150f + (235f - 150f) * segmentT
                b = 243f + (59f - 243f) * segmentT
            } else if (t < 0.7f) {
                val segmentT = (t - 0.4f) / 0.3f
                // Yellow (255, 235, 59) to Dark Yellow (190, 145, 0)
                r = 255f + (190f - 255f) * segmentT
                g = 235f + (145f - 235f) * segmentT
                b = 59f + (0f - 59f) * segmentT
            } else {
                val segmentT = (t - 0.7f) / 0.3f
                // Dark Yellow (190, 145, 0) to Dark Red (150, 0, 0)
                r = 190f + (150f - 190f) * segmentT
                g = 145f + (0f - 145f) * segmentT
                b = 0f + (0f - 0f) * segmentT
            }
            
            val darkenFactor = 1.0f - (t * 0.3f)
            
            val finalR = (r * darkenFactor).toInt().coerceIn(0, 255)
            val finalG = (g * darkenFactor).toInt().coerceIn(0, 255)
            val finalB = (b * darkenFactor).toInt().coerceIn(0, 255)
            
            return Color.rgb(finalR, finalG, finalB)
        }
    }
}
