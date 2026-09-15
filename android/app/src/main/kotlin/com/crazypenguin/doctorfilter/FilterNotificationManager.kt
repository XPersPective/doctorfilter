package com.crazypenguin.doctorfilter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Builds the persistent control notification.
 *
 * Every action carries a real drawable. Android silently drops actions whose
 * icon resource is 0, which is why the previous version showed a notification
 * with no buttons on it at all — the code looked right and the controls simply
 * were not there.
 */
object FilterNotificationManager {

    const val CHANNEL_ID = "doctorfilter_active"
    const val NOTIFICATION_ID = 1001

    const val ACTION_TOGGLE = "com.crazypenguin.doctorfilter.action.TOGGLE"
    const val ACTION_DIM_MORE = "com.crazypenguin.doctorfilter.action.DIM_MORE"
    const val ACTION_DIM_LESS = "com.crazypenguin.doctorfilter.action.DIM_LESS"
    const val ACTION_NEXT_PRESET = "com.crazypenguin.doctorfilter.action.NEXT_PRESET"

    private const val REQUEST_OPEN = 0
    private const val REQUEST_TOGGLE = 1
    private const val REQUEST_DIM_MORE = 2
    private const val REQUEST_DIM_LESS = 3
    private const val REQUEST_NEXT_PRESET = 4

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notification_channel_name),
            // The filter runs all evening; this notification must never make a
            // sound, vibrate, or peek over what the user is doing.
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = context.getString(R.string.notification_channel_description)
            setShowBadge(false)
            enableVibration(false)
            enableLights(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    fun buildNotification(
        context: Context,
        isActive: Boolean,
        values: FilterState.Values
    ): Notification {
        createNotificationChannel(context)

        val title = if (isActive) {
            context.getString(R.string.notification_title_active, values.kelvin)
        } else {
            context.getString(R.string.notification_title_paused)
        }

        val summary = context.getString(
            R.string.notification_summary,
            values.densityPercent,
            values.extraDimPercent
        )

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(summary)
            .setContentIntent(openApp(context))
            .setOngoing(isActive)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                R.drawable.ic_power,
                context.getString(
                    if (isActive) R.string.notification_action_off
                    else R.string.notification_action_on
                ),
                broadcast(context, ACTION_TOGGLE, REQUEST_TOGGLE)
            )
            .addAction(
                R.drawable.ic_dimmer,
                context.getString(R.string.notification_action_dimmer),
                broadcast(context, ACTION_DIM_MORE, REQUEST_DIM_MORE)
            )
            .addAction(
                R.drawable.ic_brighter,
                context.getString(R.string.notification_action_brighter),
                broadcast(context, ACTION_DIM_LESS, REQUEST_DIM_LESS)
            )
            .addAction(
                R.drawable.ic_next_preset,
                context.getString(R.string.notification_action_next_preset),
                broadcast(context, ACTION_NEXT_PRESET, REQUEST_NEXT_PRESET)
            )
            .build()
    }

    private fun openApp(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun broadcast(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            this.action = action
            // Explicit package: an implicit broadcast would be refused on
            // Android 8+ and the button would appear to do nothing.
            setPackage(context.packageName)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
