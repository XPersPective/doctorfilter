package com.crazypenguin.doctorfilter

import android.content.Context

/**
 * The filter values the native side is currently drawing with.
 *
 * Android can and does kill a foreground service and restart it later with a
 * null intent. Without somewhere durable to read from, the service would come
 * back drawing its compile-time defaults — a user who had set a deep amber
 * night filter would find a pale one after the system reclaimed memory.
 *
 * Written by whoever changes the filter, read by the service on restart.
 */
object FilterState {

    private const val PREFS = "doctorfilter_native_state"

    private const val KEY_RED = "red"
    private const val KEY_GREEN = "green"
    private const val KEY_BLUE = "blue"
    private const val KEY_ALPHA = "alpha"
    private const val KEY_KELVIN = "kelvin"
    private const val KEY_DENSITY = "density"
    private const val KEY_EXTRA_DIM = "extra_dim"
    private const val KEY_PRESET_ID = "preset_id"
    private const val KEY_NOTIFICATION = "notification_enabled"
    private const val KEY_WAS_RUNNING = "was_running"

    /**
     * The composite overlay colour and alpha, already combined from the three
     * axes by the Dart layer. The native side deliberately does not recompute
     * them: the meaning of the axes — including the caps that stop the screen
     * going black — lives in one place, where it is unit tested without a device.
     */
    data class Values(
        val red: Int,
        val green: Int,
        val blue: Int,
        val alpha: Int,
        val kelvin: Int,
        val densityPercent: Int,
        val extraDimPercent: Int,
        val presetId: Int,
        val notificationEnabled: Boolean
    )

    /** Values used before the user has ever configured anything. */
    val DEFAULT = Values(
        red = 255,
        green = 190,
        blue = 122,
        alpha = 110,
        kelvin = 3200,
        densityPercent = 30,
        extraDimPercent = 20,
        presetId = 0,
        notificationEnabled = true
    )

    fun read(context: Context): Values {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return Values(
            red = prefs.getInt(KEY_RED, DEFAULT.red),
            green = prefs.getInt(KEY_GREEN, DEFAULT.green),
            blue = prefs.getInt(KEY_BLUE, DEFAULT.blue),
            alpha = prefs.getInt(KEY_ALPHA, DEFAULT.alpha),
            kelvin = prefs.getInt(KEY_KELVIN, DEFAULT.kelvin),
            densityPercent = prefs.getInt(KEY_DENSITY, DEFAULT.densityPercent),
            extraDimPercent = prefs.getInt(KEY_EXTRA_DIM, DEFAULT.extraDimPercent),
            presetId = prefs.getInt(KEY_PRESET_ID, DEFAULT.presetId),
            notificationEnabled = prefs.getBoolean(KEY_NOTIFICATION, DEFAULT.notificationEnabled)
        )
    }

    fun write(context: Context, values: Values) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putInt(KEY_RED, values.red)
            .putInt(KEY_GREEN, values.green)
            .putInt(KEY_BLUE, values.blue)
            .putInt(KEY_ALPHA, values.alpha)
            .putInt(KEY_KELVIN, values.kelvin)
            .putInt(KEY_DENSITY, values.densityPercent)
            .putInt(KEY_EXTRA_DIM, values.extraDimPercent)
            .putInt(KEY_PRESET_ID, values.presetId)
            .putBoolean(KEY_NOTIFICATION, values.notificationEnabled)
            .apply()
    }

    /**
     * Whether the filter was on when the app last had a say.
     *
     * Read after a reboot or a process death, so the filter comes back the way
     * the user left it rather than silently staying off.
     */
    fun wasRunning(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_WAS_RUNNING, false)

    fun setWasRunning(context: Context, running: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_WAS_RUNNING, running)
            .apply()
    }
}
