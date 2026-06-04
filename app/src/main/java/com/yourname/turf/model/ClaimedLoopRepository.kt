package com.yourname.turf.model

import android.content.Context
import com.google.android.gms.maps.model.LatLng
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileReader
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

class ClaimedLoopRepository(private val context: Context) {

    private val claimedFile = File(context.filesDir, "claimed_loops.json")

    @Synchronized
    fun getClaimedLoops(): List<ClaimedLoop> {
        if (!claimedFile.exists()) return emptyList()
        val list = mutableListOf<ClaimedLoop>()
        try {
            val jsonStr = FileReader(claimedFile).use { it.readText() }
            val jsonArray = JSONArray(jsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val id = obj.getString("id")
                val name = obj.getString("name")
                val streakCount = obj.getInt("streakCount")
                val lastCoveredDate = obj.getString("lastCoveredDate")
                val coveredCountToday = obj.getInt("coveredCountToday")

                val ptArray = obj.getJSONArray("points")
                val points = mutableListOf<LatLng>()
                for (j in 0 until ptArray.length()) {
                    val ptObj = ptArray.getJSONObject(j)
                    points.add(LatLng(ptObj.getDouble("lat"), ptObj.getDouble("lng")))
                }
                list.add(
                    ClaimedLoop(
                        id = id,
                        name = name,
                        points = points,
                        streakCount = streakCount,
                        lastCoveredDate = lastCoveredDate,
                        coveredCountToday = coveredCountToday
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Apply streak checking and pruning
        val today = getTodayDateString()
        val yesterday = getYesterdayDateString()
        var changed = false
        val prunedList = mutableListOf<ClaimedLoop>()

        for (loop in list) {
            when (loop.lastCoveredDate) {
                today -> {
                    prunedList.add(loop)
                }
                yesterday -> {
                    if (loop.coveredCountToday > 0) {
                        prunedList.add(loop.copy(coveredCountToday = 0))
                        changed = true
                    } else {
                        prunedList.add(loop)
                    }
                }
                else -> {
                    // Expired - do not add to prunedList, we lost the claim!
                    changed = true
                }
            }
        }

        if (changed) {
            saveClaimedLoops(prunedList)
        }

        return prunedList
    }

    @Synchronized
    fun saveClaimedLoops(loops: List<ClaimedLoop>) {
        try {
            val jsonArray = JSONArray()
            for (s in loops) {
                val obj = JSONObject().apply {
                    put("id", s.id)
                    put("name", s.name)
                    put("streakCount", s.streakCount)
                    put("lastCoveredDate", s.lastCoveredDate)
                    put("coveredCountToday", s.coveredCountToday)

                    val pointArray = JSONArray()
                    for (point in s.points) {
                        val ptObj = JSONObject().apply {
                            put("lat", point.latitude)
                            put("lng", point.longitude)
                        }
                        pointArray.put(ptObj)
                    }
                    put("points", pointArray)
                }
                jsonArray.put(obj)
            }
            FileWriter(claimedFile).use { it.write(jsonArray.toString(2)) }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    @Synchronized
    fun addOrUpdateClaimedLoop(loop: ClaimedLoop) {
        val current = getClaimedLoops().toMutableList()
        val index = current.indexOfFirst { it.id == loop.id }
        if (index != -1) {
            current[index] = loop
        } else {
            current.add(loop)
        }
        saveClaimedLoops(current)
    }

    @Synchronized
    fun deleteClaim(loopId: String) {
        val current = getClaimedLoops().filter { it.id != loopId }
        saveClaimedLoops(current)
    }

    companion object {
        fun getTodayDateString(): String {
            return SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        }

        fun getYesterdayDateString(): String {
            val cal = Calendar.getInstance()
            cal.add(Calendar.DAY_OF_YEAR, -1)
            return SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(cal.time)
        }
    }
}
