package com.crazypenguin.doctorfilter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

object FilterNotificationManager {
    const val CHANNEL_ID = "doctorfilter_channel_active"
    const val NOTIFICATION_ID = 1001

    const val ACTION_TOGGLE = "com.crazypenguin.doctorfilter.action.TOGGLE"
    const val ACTION_DIM_MORE = "com.crazypenguin.doctorfilter.action.DIM_MORE"
    const val ACTION_DIM_LESS = "com.crazypenguin.doctorfilter.action.DIM_LESS"

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "DoctorFilter Active Service"
            val descriptionText = "Displays quick filter status and toggle controls in notification panel"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
                enableVibration(false)
                enableLights(false)
            }
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun buildNotification(
        context: Context,
        isActive: Boolean,
        kelvin: Int,
        brightness: Int,
        alpha: Int
    ): Notification {
        createNotificationChannel(context)

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val toggleIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = ACTION_TOGGLE
        }
        val togglePendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val dimMoreIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = ACTION_DIM_MORE
        }
        val dimMorePendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            dimMoreIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val dimLessIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = ACTION_DIM_LESS
        }
        val dimLessPendingIntent = PendingIntent.getBroadcast(
            context,
            3,
            dimLessIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val densityPercent = ((alpha / 255.0) * 100).toInt().coerceIn(0, 100)

        val title = if (isActive) "DoctorFilter Active • ${kelvin}K" else "DoctorFilter Paused"
        val subtitle = "Density: $densityPercent% • Touch to adjust"

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setContentIntent(openAppPendingIntent)
            .setOngoing(isActive)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(
                0,
                if (isActive) "Turn Off" else "Turn On",
                togglePendingIntent
            )
            .addAction(0, "Darker (+)", dimMorePendingIntent)
            .addAction(0, "Lighter (-)", dimLessPendingIntent)
            .build()
    }
}
