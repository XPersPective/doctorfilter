package com.example.doctorfilter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            FilterNotificationManager.ACTION_TOGGLE -> {
                if (OverlayService.isRunning) {
                    val stopIntent = Intent(context, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_STOP
                    }
                    context.startService(stopIntent)
                    MainActivity.notifyFlutterFilterStateChanged(false)
                } else {
                    val startIntent = Intent(context, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_START
                    }
                    context.startService(startIntent)
                    MainActivity.notifyFlutterFilterStateChanged(true)
                }
            }
            FilterNotificationManager.ACTION_DIM_MORE -> {
                if (OverlayService.isRunning) {
                    val newAlpha = (OverlayService.currentAlpha + 15).coerceAtMost(220)
                    val updateIntent = Intent(context, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_UPDATE
                        putExtra(OverlayService.EXTRA_ALPHA, newAlpha)
                    }
                    context.startService(updateIntent)
                    MainActivity.notifyFlutterDensityChanged(newAlpha)
                }
            }
            FilterNotificationManager.ACTION_DIM_LESS -> {
                if (OverlayService.isRunning) {
                    val newAlpha = (OverlayService.currentAlpha - 15).coerceAtLeast(10)
                    val updateIntent = Intent(context, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_UPDATE
                        putExtra(OverlayService.EXTRA_ALPHA, newAlpha)
                    }
                    context.startService(updateIntent)
                    MainActivity.notifyFlutterDensityChanged(newAlpha)
                }
            }
        }
    }
}
