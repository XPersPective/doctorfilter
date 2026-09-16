package com.crazypenguin.doctorfilter

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * The 20-20-20 reminder: every twenty minutes, look twenty feet away for twenty
 * seconds.
 *
 * This is the one piece of eye-strain advice with a genuine mechanism behind it
 * — sustained near focus and a reduced blink rate, not blue light — so it earns
 * its place next to a filter that cannot claim as much. Section 5.8 applies to
 * the wording: it is a comfort measure, not a treatment.
 *
 * Inexact repeating alarms on purpose. A break reminder that wakes a dozing
 * phone to the second would cost more battery than it is worth, and nobody
 * notices a reminder arriving at 21 minutes.
 */
class BreakReminderReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_REMIND = "com.crazypenguin.doctorfilter.ACTION_BREAK_REMINDER"

        const val CHANNEL_ID = "doctorfilter_breaks"
        const val NOTIFICATION_ID = 1002

        private const val REQUEST_CODE = 2003

        private const val PREFS = "doctorfilter_breaks"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_INTERVAL = "interval_minutes"

        /** The 20 in 20-20-20. Pro can change it; free cannot. */
        const val DEFAULT_INTERVAL_MINUTES = 20

        fun update(context: Context, isEnabled: Boolean, intervalMinutes: Int) {
            val interval = intervalMinutes.coerceIn(5, 120)

            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ENABLED, isEnabled)
                .putInt(KEY_INTERVAL, interval)
                .apply()

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val operation = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                Intent(context, BreakReminderReceiver::class.java).apply {
                    action = ACTION_REMIND
                    setPackage(context.packageName)
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (!isEnabled) {
                alarmManager.cancel(operation)
                NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
                return
            }

            val intervalMillis = interval * 60_000L
            alarmManager.setInexactRepeating(
                AlarmManager.RTC,
                System.currentTimeMillis() + intervalMillis,
                intervalMillis,
                operation
            )
        }

        /** Re-arms after a reboot, which clears every alarm the app had set. */
        fun reArm(context: Context) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (!prefs.getBoolean(KEY_ENABLED, false)) return
            update(
                context = context,
                isEnabled = true,
                intervalMinutes = prefs.getInt(KEY_INTERVAL, DEFAULT_INTERVAL_MINUTES)
            )
        }

        private fun createChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

            val channel = NotificationChannel(
                CHANNEL_ID,
                PresetCatalog.text(context, R.string.break_channel_name),
                // Silent. A reminder that startles the user is worse than none,
                // and this one arrives every twenty minutes.
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = PresetCatalog.text(context, R.string.break_channel_description)
                setShowBadge(false)
                enableVibration(false)
                enableLights(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_REMIND) return

        // Only while the filter is actually running: the reminder is part of
        // using the app, not something it should do to a phone in a drawer.
        if (!OverlayService.isRunning) return

        createChannel(context)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(PresetCatalog.text(context, R.string.break_title))
            .setContentText(PresetCatalog.text(context, R.string.break_body))
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(PresetCatalog.text(context, R.string.break_body))
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            // Dismisses itself: a twenty-second break does not need to be ticked
            // off, and a reminder still sitting there an hour later is clutter.
            .setTimeoutAfter(2 * 60_000L)
            .setAutoCancel(true)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) {
            // Notification permission revoked. Nothing to do and nothing to fix.
        }
    }
}
