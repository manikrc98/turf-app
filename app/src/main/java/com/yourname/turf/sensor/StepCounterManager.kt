package com.yourname.turf.sensor

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager

class StepCounterManager(context: Context) : SensorEventListener {

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val stepSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    
    val isSensorAvailable: Boolean = stepSensor != null

    private var stepBaseline: Int = -1
    private var onStepUpdate: ((steps: Int) -> Unit)? = null
    
    fun start(onStepUpdate: (steps: Int) -> Unit) {
        this.onStepUpdate = onStepUpdate
        stepBaseline = -1 // Reset baseline
        if (isSensorAvailable) {
            sensorManager.registerListener(this, stepSensor, SensorManager.SENSOR_DELAY_UI)
        }
    }

    fun stop() {
        if (isSensorAvailable) {
            sensorManager.unregisterListener(this)
        }
        onStepUpdate = null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != Sensor.TYPE_STEP_COUNTER) return
        
        val totalSteps = event.values.getOrNull(0)?.toInt() ?: return
        if (stepBaseline == -1) {
            stepBaseline = totalSteps
        }
        
        val liveSteps = totalSteps - stepBaseline
        onStepUpdate?.invoke(liveSteps)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No-op
    }

    companion object {
        const val STRIDE_METRES = 0.762f

        /**
         * Helper to estimate steps from distance in kilometers
         */
        fun estimateSteps(distanceKm: Double): Int {
            val distanceMetres = distanceKm * 1000.0
            return (distanceMetres / STRIDE_METRES).toInt()
        }

        /**
         * Helper to calculate distance in kilometers from steps
         */
        fun calculateDistanceKm(steps: Int): Double {
            return (steps * STRIDE_METRES) / 1000.0
        }
    }
}
