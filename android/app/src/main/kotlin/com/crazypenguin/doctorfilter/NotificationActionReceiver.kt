package com.crazypenguin.doctorfilter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Handles taps on the notification's buttons.
 *
 * These arrive whether or not the Flutter side is alive, so every handler works
 * from persisted native state and only *notifies* Dart afterwards — it never
 * waits for it. A user tapping "dimmer" from the lock screen at 2am should not
 * depend on the UI process still existing.
 */
class NotificationActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            FilterNotificationManager.ACTION_TOGGLE -> toggle(context)
            FilterNotificationManager.ACTION_DIM_MORE -> stepDim(context, DIM_STEP)
            FilterNotificationManager.ACTION_DIM_LESS -> stepDim(context, -DIM_STEP)
            FilterNotificationManager.ACTION_NEXT_PRESET -> nextPreset(context)
        }
    }

    private fun toggle(context: Context) {
        if (OverlayService.isRunning) {
            context.startService(
                Intent(context, OverlayService::class.java).apply {
                    action = OverlayService.ACTION_STOP
                }
            )
            MainActivity.notifyFilterToggled(false)
        } else {
            startOverlay(context, Intent(context, OverlayService::class.java).apply {
                action = OverlayService.ACTION_START
            })
            MainActivity.notifyFilterToggled(true)
        }
    }

    private fun stepDim(context: Context, delta: Int) {
        if (!OverlayService.isRunning) return

        val current = OverlayService.current
        val dim = (current.extraDimPercent + delta).coerceIn(0, MAX_EXTRA_DIM)
        if (dim == current.extraDimPercent) return

        // Recomputing the composite here would duplicate the domain rules in a
        // second language. Instead the axis is sent up to Dart, which owns the
        // maths and sends a fully-formed composite straight back down.
        MainActivity.notifyAxisChanged(extraDimPercent = dim)
    }

    private fun nextPreset(context: Context) {
        MainActivity.notifyNextPresetRequested()
    }

    private fun startOverlay(context: Context, intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private companion object {
        /** One tap should be a visible change without overshooting. */
        const val DIM_STEP = 10

        /** Mirrors `FilterConfig.maxExtraDimPercent`. */
        const val MAX_EXTRA_DIM = 70
    }
}
