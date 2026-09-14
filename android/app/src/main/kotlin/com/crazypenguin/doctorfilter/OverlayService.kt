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
        const val EXTRA_BRIGHTNESS = "extra_brightness"
        const val EXTRA_KELVIN = "extra_kelvin"

        var isRunning = false
            private set

        var currentRed = 255
            private set
        var currentGreen = 219
            private set
        var currentBlue = 186
            private set
        var currentAlpha = 25
            private set
        var currentBrightness = 195
            private set
        var currentKelvin = 5500
            private set
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            return START_NOT_STICKY
        }

        when (intent.action) {
            ACTION_STOP -> {
                stopOverlay()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START, ACTION_UPDATE -> {
                currentRed = intent.getIntExtra(EXTRA_RED, currentRed)
                currentGreen = intent.getIntExtra(EXTRA_GREEN, currentGreen)
                currentBlue = intent.getIntExtra(EXTRA_BLUE, currentBlue)
                currentAlpha = intent.getIntExtra(EXTRA_ALPHA, currentAlpha)
                currentBrightness = intent.getIntExtra(EXTRA_BRIGHTNESS, currentBrightness)
                currentKelvin = intent.getIntExtra(EXTRA_KELVIN, currentKelvin)

                startOrUpdateForeground()
                applyOverlay()
                return START_STICKY
            }
        }

        return START_STICKY
    }

    private fun startOrUpdateForeground() {
        val notification = FilterNotificationManager.buildNotification(
            context = this,
            isActive = true,
            kelvin = currentKelvin,
            brightness = currentBrightness,
            alpha = currentAlpha
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
            startForeground(FilterNotificationManager.NOTIFICATION_ID, notification)
        }
        isRunning = true
    }

    private fun applyOverlay() {
        val wm = windowManager ?: return

        // Compute composite alpha combining tint alpha and extra dimming
        val effectiveAlpha = currentAlpha.coerceIn(0, 255)
        val filterColor = Color.argb(effectiveAlpha, currentRed, currentGreen, currentBlue)

        if (overlayView == null) {
            overlayView = View(this).apply {
                setBackgroundColor(filterColor)
            }

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

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                layoutParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    overlayType,
                    windowFlags,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    layoutInDisplayCutoutMode =
                        WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                }
            } else {
                layoutParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    overlayType,
                    windowFlags,
                    PixelFormat.TRANSLUCENT
                )
            }

            try {
                wm.addView(overlayView, layoutParams)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        } else {
            overlayView?.setBackgroundColor(filterColor)
            try {
                wm.updateViewLayout(overlayView, layoutParams)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun stopOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            overlayView = null
        }
        isRunning = false
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
    }

    override fun onDestroy() {
        stopOverlay()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
