package com.crazypenguin.doctorfilter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Handles taps on the notification's buttons and chips.
 *
 * These arrive whether or not the Flutter side is alive, so each handler works
 * from persisted native state and only *notifies* Dart afterwards — it never
 * waits for it. Someone tapping "dimmer" from the lock screen at 2am should not
 * depend on the UI process still existing.
 *
 * Dart owns the arithmetic. The receiver reports the new value of one axis and
 * lets the domain layer recompute the composite and send it back down; doing the
 * sums here would put the caps that keep the screen readable in two languages at
 * once, and eventually in disagreement.
 */
class NotificationActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            FilterNotificationManager.ACTION_TOGGLE -> toggle(context)
            FilterNotificationManager.ACTION_DIM_MORE -> stepAxis(
                context, FilterNotificationManager.AXIS_DIM, FilterNotificationManager.PERCENT_STEP
            )
            FilterNotificationManager.ACTION_DIM_LESS -> stepAxis(
                context, FilterNotificationManager.AXIS_DIM, -FilterNotificationManager.PERCENT_STEP
            )
            FilterNotificationManager.ACTION_NEXT_PRESET ->
                MainActivity.notifyNextPresetRequested()

            FilterNotificationManager.ACTION_AXIS_STEP -> stepAxis(
                context,
                intent.getStringExtra(FilterNotificationManager.EXTRA_AXIS) ?: return,
                intent.getIntExtra(FilterNotificationManager.EXTRA_STEP, 0)
            )

            FilterNotificationManager.ACTION_SELECT_PRESET -> {
                val presetId = intent.getIntExtra(
                    FilterNotificationManager.EXTRA_PRESET_ID, -1
                )
                if (presetId >= 0) MainActivity.notifyPresetSelected(presetId)
            }
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
            startOverlay(context)
            MainActivity.notifyFilterToggled(true)
        }
    }

    private fun stepAxis(context: Context, axis: String, step: Int) {
        if (!OverlayService.isRunning || step == 0) return
        val current = OverlayService.current

        when (axis) {
            FilterNotificationManager.AXIS_KELVIN -> {
                val next = (current.kelvin + step).coerceIn(MIN_KELVIN, MAX_KELVIN)
                if (next != current.kelvin) MainActivity.notifyAxisChanged(kelvin = next)
            }

            FilterNotificationManager.AXIS_DENSITY -> {
                val next = (current.densityPercent + step).coerceIn(0, MAX_DENSITY)
                if (next != current.densityPercent) {
                    MainActivity.notifyAxisChanged(densityPercent = next)
                }
            }

            FilterNotificationManager.AXIS_DIM -> {
                val next = (current.extraDimPercent + step).coerceIn(0, MAX_EXTRA_DIM)
                if (next != current.extraDimPercent) {
                    MainActivity.notifyAxisChanged(extraDimPercent = next)
                }
            }
        }
    }

    private fun startOverlay(context: Context) {
        val intent = Intent(context, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private companion object {
        // Mirror the domain limits so a tap cannot push past them even in the
        // window before Dart answers. Dart clamps again on arrival.
        const val MIN_KELVIN = 1700
        const val MAX_KELVIN = 6500
        const val MAX_DENSITY = 80
        const val MAX_EXTRA_DIM = 70
    }
}
