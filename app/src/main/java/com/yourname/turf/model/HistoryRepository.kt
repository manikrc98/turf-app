package com.yourname.turf.model

import android.content.Context
import com.google.android.gms.maps.model.LatLng
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileReader
import java.io.FileWriter

class HistoryRepository(private val context: Context) {

    private val historyFile = File(context.filesDir, "walk_history.json")

    @Synchronized
    fun getHistory(): List<WalkSessionSummary> {
        if (!historyFile.exists()) return emptyList()
        val historyList = mutableListOf<WalkSessionSummary>()
        try {
            val jsonStr = FileReader(historyFile).use { it.readText() }
            val jsonArray = JSONArray(jsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                
                // Read loops (with fallback to old polygons array)
                val loopsList = mutableListOf<TurfLoop>()
                val loopsArray = obj.optJSONArray("loops")
                if (loopsArray != null) {
                    for (j in 0 until loopsArray.length()) {
                        val loopObj = loopsArray.getJSONObject(j)
                        val loopId = loopObj.optString("id", java.util.UUID.randomUUID().toString())
                        val loopName = if (loopObj.has("name") && !loopObj.isNull("name")) loopObj.getString("name") else null
                        
                        val ptArray = loopObj.getJSONArray("points")
                        val points = mutableListOf<LatLng>()
                        for (k in 0 until ptArray.length()) {
                            val ptObj = ptArray.getJSONObject(k)
                            points.add(LatLng(ptObj.getDouble("lat"), ptObj.getDouble("lng")))
                        }
                        loopsList.add(TurfLoop(id = loopId, name = loopName, points = points))
                    }
                } else {
                    // Fallback to old polygons array
                    val polygonsArray = obj.optJSONArray("polygons")
                    if (polygonsArray != null) {
                        for (j in 0 until polygonsArray.length()) {
                            val pointArray = polygonsArray.getJSONArray(j)
                            val points = mutableListOf<LatLng>()
                            for (k in 0 until pointArray.length()) {
                                val ptObj = pointArray.getJSONObject(k)
                                points.add(LatLng(ptObj.getDouble("lat"), ptObj.getDouble("lng")))
                            }
                            loopsList.add(TurfLoop(points = points))
                        }
                    }
                }

                historyList.add(
                    WalkSessionSummary(
                        id = obj.getString("id"),
                        dateTime = obj.getString("dateTime"),
                        steps = obj.getInt("steps"),
                        isStepEstimated = obj.optBoolean("isStepEstimated", false),
                        distanceKm = obj.getDouble("distanceKm"),
                        loopCount = obj.getInt("loopCount"),
                        durationSeconds = obj.optLong("durationSeconds", 0L),
                        loops = loopsList,
                        cadence = obj.optInt("cadence", 0),
                        elevationGainMetres = obj.optDouble("elevationGainMetres", 0.0)
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return historyList.reversed()
    }

    @Synchronized
    fun addSession(session: WalkSessionSummary) {
        val currentHistory = getHistory().reversed().toMutableList()
        currentHistory.add(session)

        try {
            val jsonArray = JSONArray()
            for (s in currentHistory) {
                val obj = JSONObject().apply {
                    put("id", s.id)
                    put("dateTime", s.dateTime)
                    put("steps", s.steps)
                    put("isStepEstimated", s.isStepEstimated)
                    put("distanceKm", s.distanceKm)
                    put("loopCount", s.loopCount)
                    put("durationSeconds", s.durationSeconds)
                    put("cadence", s.cadence)
                    put("elevationGainMetres", s.elevationGainMetres)
                    
                    // Write loops nested coordinates and details
                    val loopsArray = JSONArray()
                    for (loop in s.loops) {
                        val loopObj = JSONObject().apply {
                            put("id", loop.id)
                            if (loop.name != null) {
                                put("name", loop.name)
                            } else {
                                put("name", JSONObject.NULL)
                            }
                            
                            val pointArray = JSONArray()
                            for (point in loop.points) {
                                val ptObj = JSONObject().apply {
                                    put("lat", point.latitude)
                                    put("lng", point.longitude)
                                }
                                pointArray.put(ptObj)
                            }
                            put("points", pointArray)
                        }
                        loopsArray.put(loopObj)
                    }
                    put("loops", loopsArray)
                }
                jsonArray.put(obj)
            }
            FileWriter(historyFile).use { it.write(jsonArray.toString(2)) }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    @Synchronized
    fun clearHistory() {
        if (historyFile.exists()) {
            historyFile.delete()
        }
    }
}
