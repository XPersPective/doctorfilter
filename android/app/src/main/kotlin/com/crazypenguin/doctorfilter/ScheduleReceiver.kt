package com.crazypenguin.doctorfilter

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

/**
 * Turns the filter on and off at the scheduled times, and restores the schedule
 * after a reboot.
 *
 * Each alarm re-arms itself for the following day when it fires. The previous
 * version set both alarms once and never again, so the schedule worked for
 * exactly one night and then quietly stopped — the kind of failure a user
 * attributes to the app being broken rather than to a missing line of code.
 */
class ScheduleReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_SCHEDULE_START = "com.crazypenguin.doctorfilter.ACTION_SCHEDULE_START"
        const val ACTION_SCHEDULE_STOP = "com.crazypenguin.doctorfilter.ACTION_SCHEDULE_STOP"

        private const val REQUEST_START = 2001
        private const val REQUEST_STOP = 2002

        private const val PREFS = "doctorfilter_schedule"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_START_HOUR = "start_hour"
        private const val KEY_START_MINUTE = "start_minute"
        private const val KEY_STOP_HOUR = "stop_hour"
        private const val KEY_STOP_MINUTE = "stop_minute"
        private const val KEY_PRESET_ID = "preset_id"
        private const val KEY_TRANSITION = "transition_minutes"

        fun updateSchedule(
            context: Context,
            isEnabled: Boolean,
            startHour: Int,
            startMinute: Int,
            stopHour: Int,
            stopMinute: Int,
            targetPresetId: Int,
            transitionMinutes: Int
        ) {
            // Persisted natively as well as in Flutter's preferences: after a
            // reboot this receiver runs long before any Flutter engine exists.
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ENABLED, isEnabled)
                .putInt(KEY_START_HOUR, startHour)
                .putInt(KEY_START_MINUTE, startMinute)
                .putInt(KEY_STOP_HOUR, stopHour)
                .putInt(KEY_STOP_MINUTE, stopMinute)
                .putInt(KEY_PRESET_ID, targetPresetId)
                .putInt(KEY_TRANSITION, transitionMinutes)
                .apply()

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val startIntent = pendingIntent(context, ACTION_SCHEDULE_START, REQUEST_START)
            val stopIntent = pendingIntent(context, ACTION_SCHEDULE_STOP, REQUEST_STOP)

            if (!isEnabled) {
                alarmManager.cancel(startIntent)
                alarmManager.cancel(stopIntent)
                return
            }

            schedule(alarmManager, nextOccurrenceOf(startHour, startMinute), startIntent)
            schedule(alarmManager, nextOccurrenceOf(stopHour, stopMinute), stopIntent)
        }

        private fun pendingIntent(context: Context, action: String, requestCode: Int) =
            PendingIntent.getBroadcast(
                context,
                requestCode,
                Intent(context, ScheduleReceiver::class.java).apply {
                    this.action = action
                    setPackage(context.packageName)
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

        /**
         * Exact where allowed, inexact where not.
         *
         * Android 12+ can refuse exact alarms, and calling the exact API without
         * the permission throws. Falling back keeps the schedule working — a few
         * minutes late is worth far more to the user than a crash.
         */
        private fun schedule(alarmManager: AlarmManager, atMillis: Long, operation: PendingIntent) {
            val canBeExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                    alarmManager.canScheduleExactAlarms()

            try {
                if (canBeExact) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, atMillis, operation
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, atMillis, operation
                    )
                }
            } catch (e: SecurityException) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, operation)
            }
        }

        private fun nextOccurrenceOf(hour: Int, minute: Int): Long {
            val now = Calendar.getInstance()
            val target = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            if (!target.after(now)) target.add(Calendar.DAY_OF_YEAR, 1)
            return target.timeInMillis
        }

        private fun reArm(context: Context) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (!prefs.getBoolean(KEY_ENABLED, false)) return
            updateSchedule(
                context = context,
                isEnabled = true,
                startHour = prefs.getInt(KEY_START_HOUR, 22),
                startMinute = prefs.getInt(KEY_START_MINUTE, 0),
                stopHour = prefs.getInt(KEY_STOP_HOUR, 7),
                stopMinute = prefs.getInt(KEY_STOP_MINUTE, 0),
                targetPresetId = prefs.getInt(KEY_PRESET_ID, 5),
                transitionMinutes = prefs.getInt(KEY_TRANSITION, 0)
            )
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                reArm(context)
                // A filter that was on when the phone went down should be on
                // when it comes back up.
                if (FilterState.wasRunning(context)) startFilter(context)
            }

            ACTION_SCHEDULE_START -> {
                startFilter(context, rampMillis = transitionMillis(context))
                MainActivity.notifyFilterToggled(true)
                reArm(context)
            }

            ACTION_SCHEDULE_STOP -> {
                context.startService(
                    Intent(context, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_STOP
                        putExtra(OverlayService.EXTRA_RAMP_MILLIS, transitionMillis(context))
                    }
                )
                MainActivity.notifyFilterToggled(false)
                reArm(context)
            }
        }
    }

    /**
     * Only scheduled transitions fade. A reboot restore has nothing to fade in
     * from — the user last saw the filter already on.
     */
    private fun transitionMillis(context: Context): Long =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(KEY_TRANSITION, 0)
            .coerceIn(0, 60) * 60_000L

    private fun startFilter(context: Context, rampMillis: Long = 0L) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val presetId = prefs.getInt(KEY_PRESET_ID, -1)

        val intent = Intent(context, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
            if (presetId >= 0) putExtra(OverlayService.EXTRA_PRESET_ID, presetId)
            if (rampMillis > 0) putExtra(OverlayService.EXTRA_RAMP_MILLIS, rampMillis)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }

        // The overlay starts with the last-known values immediately; Dart, when
        // it next runs, resolves the target preset and sends the exact composite.
        if (presetId >= 0) MainActivity.notifyPresetSelected(presetId)
    }
}
