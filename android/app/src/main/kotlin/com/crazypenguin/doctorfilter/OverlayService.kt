package com.crazypenguin.doctorfilter

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.View
import android.view.WindowManager
import androidx.core.app.ServiceCompat

/**
 * Draws the filter as a full-screen overlay window.
 *
 * The service is deliberately dumb: it is handed a composite colour and alpha
 * and paints them. Combining the three axes, and enforcing the caps that keep
 * the screen readable, happens in the Dart domain layer where it is unit tested.
 * Splitting that logic across the language boundary is how the previous version
 * ended up storing a brightness value that nothing ever applied.
 */
class OverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    companion object {
        const val ACTION_START = "com.crazypenguin.doctorfilter.action.START"
        const val ACTION_STOP = "com.crazypenguin.doctorfilter.action.STOP"
        const val ACTION_UPDATE = "com.crazypenguin.doctorfilter.action.UPDATE"

        const val EXTRA_RED = "extra_red"
        const val EXTRA_GREEN = "extra_green"
        const val EXTRA_BLUE = "extra_blue"
        const val EXTRA_ALPHA = "extra_alpha"
        const val EXTRA_KELVIN = "extra_kelvin"
        const val EXTRA_DENSITY = "extra_density"
        const val EXTRA_EXTRA_DIM = "extra_extra_dim"
        const val EXTRA_PRESET_ID = "extra_preset_id"

        @Volatile
        var isRunning = false
            private set

        @Volatile
        var current: FilterState.Values = FilterState.DEFAULT
            private set
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        // Restored rather than defaulted: this may be a restart after the system
        // killed us, in which case the user's settings are on disk and the
        // in-memory companion object is back to its defaults.
        current = FilterState.read(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // A null intent means the system restarted us after reclaiming memory.
        // Redraw what the user had rather than dying quietly.
        if (intent == null) {
            startOrUpdateForeground()
            applyOverlay()
            return START_STICKY
        }

        return when (intent.action) {
            ACTION_STOP -> {
                stopOverlay()
                stopSelf()
                START_NOT_STICKY
            }

            ACTION_START, ACTION_UPDATE -> {
                current = readValues(intent)
                FilterState.write(this, current)
                FilterState.setWasRunning(this, true)
                startOrUpdateForeground()
                applyOverlay()
                START_STICKY
            }

            else -> START_STICKY
        }
    }

    /** Extras are optional so callers can nudge one axis without restating the rest. */
    private fun readValues(intent: Intent): FilterState.Values = FilterState.Values(
        red = intent.getIntExtra(EXTRA_RED, current.red),
        green = intent.getIntExtra(EXTRA_GREEN, current.green),
        blue = intent.getIntExtra(EXTRA_BLUE, current.blue),
        alpha = intent.getIntExtra(EXTRA_ALPHA, current.alpha).coerceIn(0, MAX_ALPHA),
        kelvin = intent.getIntExtra(EXTRA_KELVIN, current.kelvin),
        densityPercent = intent.getIntExtra(EXTRA_DENSITY, current.densityPercent),
        extraDimPercent = intent.getIntExtra(EXTRA_EXTRA_DIM, current.extraDimPercent),
        presetId = intent.getIntExtra(EXTRA_PRESET_ID, current.presetId),
        notificationEnabled = current.notificationEnabled
    )

    private fun startOrUpdateForeground() {
        val notification = FilterNotificationManager.buildNotification(
            context = this,
            isActive = true,
            values = current
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val serviceType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            } else {
                0
            }
            ServiceCompat.startForeground(
                this,
                FilterNotificationManager.NOTIFICATION_ID,
                notification,
                serviceType
            )
        } else {
            @Suppress("DEPRECATION")
            startForeground(FilterNotificationManager.NOTIFICATION_ID, notification)
        }
        isRunning = true
        FilterWidgetProvider.refreshAll(this)
    }

    private fun applyOverlay() {
        val wm = windowManager ?: return
        val filterColor = Color.argb(current.alpha, current.red, current.green, current.blue)

        val view = overlayView
        if (view != null) {
            view.setBackgroundColor(filterColor)
            return
        }

        overlayView = View(this).apply { setBackgroundColor(filterColor) }
        layoutParams = buildLayoutParams()

        try {
            wm.addView(overlayView, layoutParams)
        } catch (e: Exception) {
            // Almost always a revoked overlay permission. Nothing can be drawn,
            // so stop cleanly instead of running as a service that does nothing.
            overlayView = null
            stopOverlay()
            stopSelf()
        }
    }

    private fun buildLayoutParams(): WindowManager.LayoutParams {
        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val windowFlags = WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS

        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            overlayType,
            windowFlags,
            PixelFormat.TRANSLUCENT
        ).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                // Without this the tint stops at the notch, leaving a bright
                // unfiltered band across the top of the screen.
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
            }
        }
    }

    private fun stopOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (e: IllegalArgumentException) {
                // Already detached — the window was torn down beneath us.
            }
            overlayView = null
        }
        isRunning = false
        FilterState.setWasRunning(this, false)
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        FilterWidgetProvider.refreshAll(this)
    }

    /**
     * Rotation and window-size changes leave the overlay attached but sized for
     * the old geometry, which shows as an unfiltered strip down one edge.
     */
    override fun onConfigurationChanged(newConfig: android.content.res.Configuration) {
        super.onConfigurationChanged(newConfig)
        val view = overlayView ?: return
        try {
            windowManager?.updateViewLayout(view, layoutParams)
        } catch (e: IllegalArgumentException) {
            // View is gone; the next start will recreate it.
        }
    }

    override fun onDestroy() {
        stopOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

/**
 * Mirrors `FilterConfig.maxCompositeAlpha` (0.92). A second line of defence:
 * if a future caller ever sends an uncapped value, the screen still does not go
 * black.
 */
private const val MAX_ALPHA = 235
