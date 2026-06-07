package com.yourname.turf

import com.google.android.gms.maps.model.LatLng
import com.yourname.turf.loop.LoopDetector
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.assertFalse
import org.junit.Test

class LoopDetectorTest {

    @Test
    fun testCalculateDistanceMetres_sameCoordinate_returnsZero() {
        val dist = LoopDetector.calculateDistanceMetres(37.7749, -122.4194, 37.7749, -122.4194)
        assertEquals(0.0, dist, 0.01)
    }

    @Test
    fun testCalculateDistanceMetres_knownDistance_returnsCorrectValue() {
        // San Francisco to Los Angeles is approx 559 km (559000 metres)
        val sfLat = 37.7749
        val sfLon = -122.4194
        val laLat = 34.0522
        val laLon = -118.2437
        
        val dist = LoopDetector.calculateDistanceMetres(sfLat, sfLon, laLat, laLon)
        // Check within 5% tolerance
        assertEquals(559000.0, dist, 30000.0)
    }

    @Test
    fun testCalculateDistanceMetres_smallDistance_returnsCorrectValue() {
        // Points approx 10 metres apart
        val lat1 = 37.7749
        val lon1 = -122.4194
        val lat2 = 37.77499 // offset slightly north
        val lon2 = -122.4194
        
        val dist = LoopDetector.calculateDistanceMetres(lat1, lon1, lat2, lon2)
        assertTrue(dist > 0.0)
        assertTrue(dist < 15.0)
    }

    @Test
    fun testIsLoopClosed_straightLine_returnsFalse() {
        val trail = mutableListOf<LatLng>()
        // Generate a straight line of 25 points
        for (i in 0..25) {
            trail.add(LatLng(37.7749 + (i * 0.0001), -122.4194))
        }
        assertFalse(LoopDetector.isLoopClosed(trail))
        assertEquals(-1, LoopDetector.findLoopClosureIndex(trail))
    }

    @Test
    fun testIsLoopClosed_insufficientPoints_returnsFalse() {
        val trail = mutableListOf<LatLng>()
        // Close loop but with only 10 points
        for (i in 0..9) {
            trail.add(LatLng(37.7749 + (i * 0.00001), -122.4194))
        }
        trail.add(LatLng(37.7749, -122.4194)) // closes back to start
        assertFalse(LoopDetector.isLoopClosed(trail))
        assertEquals(-1, LoopDetector.findLoopClosureIndex(trail))
    }

    @Test
    fun testIsLoopClosed_loopAtStart_returnsTrue() {
        val trail = mutableListOf<LatLng>()
        val startLat = 37.7749
        val startLon = -122.4194
        // Add 20 points going away
        for (i in 0..20) {
            trail.add(LatLng(startLat + (i * 0.00001), startLon))
        }
        // Add 5 points coming back to start
        for (i in 4 downTo 0) {
            trail.add(LatLng(startLat + (i * 0.00001), startLon))
        }
        // Last point is exactly start point
        assertTrue(LoopDetector.isLoopClosed(trail))
        assertEquals(0, LoopDetector.findLoopClosureIndex(trail))
    }

    @Test
    fun testIsLoopClosed_loopWithPrefixTail_returnsTrue() {
        val trail = mutableListOf<LatLng>()
        // User walks 50m to loop (approx 10 points of tail)
        for (i in 0..9) {
            trail.add(LatLng(37.7749 + (i * 0.0001), -122.4194))
        }
        
        // Loop starts at index 9: LatLng(37.7758, -122.4194)
        val loopStartLat = 37.7758
        val loopStartLon = -122.4194
        
        // Add 20 points for the loop going away
        for (i in 0..20) {
            trail.add(LatLng(loopStartLat, loopStartLon + (i * 0.00005)))
        }
        
        // Add points coming back to index 9
        for (i in 19 downTo 0) {
            trail.add(LatLng(loopStartLat, loopStartLon + (i * 0.00005)))
        }
        
        assertTrue(LoopDetector.isLoopClosed(trail))
        assertEquals(9, LoopDetector.findLoopClosureIndex(trail))
    }
}
