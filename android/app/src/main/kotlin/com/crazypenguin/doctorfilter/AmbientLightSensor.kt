package com.crazypenguin.doctorfilter

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Nudges the filter up and down with the light in the room.
 *
 * The right amount of dimming is not a property of the settings, it is a
 * property of the room: 45% is gentle in a lit kitchen and nearly opaque in a
 * dark bedroom, and the same user wants both without touching a slider.
 *
 * Returns an *adjustment to the painted alpha*, never a change to the stored
 * configuration. The user's settings are the user's; the room is not allowed to
 * rewrite them, and switching the sensor off must leave nothing behind.
 */
class AmbientLightSensor(
    private val context: Context,
    private val onAdjustment: (Int) -> Unit
) : SensorEventListener {

    companion object {
        /**
         * Hard bounds on the nudge, in alpha points out of 255.
         *
         * Small on purpose. An automatic adjustment large enough to be obvious
         * is an automatic adjustment the user fights with; this is meant to
         * smooth over a change of room, not to take over the sliders.
         */
        private const val MAX_DARKEN = 30
        private const val MAX_LIGHTEN = 45

        /** Below this the room reads as dark: night, curtains drawn. */
        private const val DARK_LUX = 10f

        /** Ordinary indoor lighting — the level the user set their value at. */
        private const val INDOOR_LUX = 200f

        /** Daylight. The screen needs every bit of brightness it has. */
        private const val BRIGHT_LUX = 2000f

        /**
         * How much of each new reading to take. A light sensor is noisy and
         * fires on a passing hand; without smoothing the screen would pulse.
         */
        private const val SMOOTHING = 0.1f

        /** Repaints below this are invisible and not worth the work. */
        private const val REPAINT_THRESHOLD = 2
    }

    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager

    private var smoothedLux = -1f
    private var lastAdjustment = 0

    /** False where the device has no light sensor, so callers can say so. */
    fun start(): Boolean {
        val sensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT) ?: return false
        // NORMAL rather than a faster rate: room lighting does not change in
        // milliseconds, and the slowest rate that works is the cheapest one.
        return sensorManager.registerListener(
            this,
            sensor,
            SensorManager.SENSOR_DELAY_NORMAL
        )
    }

    fun stop() {
        sensorManager?.unregisterListener(this)
        smoothedLux = -1f
        if (lastAdjustment != 0) {
            lastAdjustment = 0
            // Hand back a clean zero, so switching the sensor off restores
            // exactly what the user configured.
            onAdjustment(0)
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_LIGHT) return

        val lux = event.values.firstOrNull() ?: return
        smoothedLux = if (smoothedLux < 0f) lux else {
            smoothedLux + SMOOTHING * (lux - smoothedLux)
        }

        val adjustment = adjustmentFor(smoothedLux)
        if (abs(adjustment - lastAdjustment) < REPAINT_THRESHOLD) return

        lastAdjustment = adjustment
        onAdjustment(adjustment)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    /**
     * Piecewise-linear, in alpha points: darken in a dark room, back off in a
     * bright one, leave ordinary indoor lighting exactly as configured.
     */
    private fun adjustmentFor(lux: Float): Int = when {
        lux <= DARK_LUX -> MAX_DARKEN
        lux <= INDOOR_LUX -> {
            val t = (lux - DARK_LUX) / (INDOOR_LUX - DARK_LUX)
            (MAX_DARKEN * (1f - t)).roundToInt()
        }
        lux <= BRIGHT_LUX -> {
            val t = (lux - INDOOR_LUX) / (BRIGHT_LUX - INDOOR_LUX)
            -(MAX_LIGHTEN * t).roundToInt()
        }
        else -> -MAX_LIGHTEN
    }
}
