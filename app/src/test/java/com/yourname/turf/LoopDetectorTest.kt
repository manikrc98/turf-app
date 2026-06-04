package com.yourname.turf

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
}
