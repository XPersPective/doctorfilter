package com.example.doctorfilter

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

class ScheduleReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_SCHEDULE_START = "com.example.doctorfilter.ACTION_SCHEDULE_START"
        const val ACTION_SCHEDULE_STOP = "com.example.doctorfilter.ACTION_SCHEDULE_STOP"

        private const val REQUEST_CODE_START = 2001
        private const val REQUEST_CODE_STOP = 2002

        fun updateSchedule(
            context: Context,
            isEnabled: Boolean,
            startHour: Int,
            startMinute: Int,
            stopHour: Int,
            stopMinute: Int
        ) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val startIntent = Intent(context, ScheduleReceiver::class.java).apply {
                action = ACTION_SCHEDULE_START
            }
            val startPendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE_START,
                startIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val stopIntent = Intent(context, ScheduleReceiver::class.java).apply {
                action = ACTION_SCHEDULE_STOP
            }
            val stopPendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE_STOP,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (!isEnabled) {
                alarmManager.cancel(startPendingIntent)
                alarmManager.cancel(stopPendingIntent)
                return
            }

            val startTimeMillis = getNextTimeMillis(startHour, startMinute)
            val stopTimeMillis = getNextTimeMillis(stopHour, stopMinute)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    startTimeMillis,
                    startPendingIntent
                )
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    stopTimeMillis,
                    stopPendingIntent
                )
            } else {
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    startTimeMillis,
                    startPendingIntent
                )
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    stopTimeMillis,
                    stopPendingIntent
                )
            }
        }

        private fun getNextTimeMillis(hour: Int, minute: Int): Long {
            val now = Calendar.getInstance()
            val target = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            if (target.before(now)) {
                target.add(Calendar.DAY_OF_YEAR, 1)
            }
            return target.timeInMillis
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                // On device restart, read SharedPreferences and re-arm schedule
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val isEnabled = prefs.getBoolean("flutter.df_schedule_enabled", false)
                if (isEnabled) {
                    val startHour = prefs.getLong("flutter.df_schedule_start_hour", 22).toInt()
                    val startMinute = prefs.getLong("flutter.df_schedule_start_minute", 0).toInt()
                    val stopHour = prefs.getLong("flutter.df_schedule_stop_hour", 7).toInt()
                    val stopMinute = prefs.getLong("flutter.df_schedule_stop_minute", 0).toInt()
                    updateSchedule(context, true, startHour, startMinute, stopHour, stopMinute)
                }
            }
            ACTION_SCHEDULE_START -> {
                val serviceIntent = Intent(context, OverlayService::class.java).apply {
                    action = OverlayService.ACTION_START
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                MainActivity.notifyFlutterFilterStateChanged(true)
            }
            ACTION_SCHEDULE_STOP -> {
                val serviceIntent = Intent(context, OverlayService::class.java).apply {
                    action = OverlayService.ACTION_STOP
                }
                context.startService(serviceIntent)
                MainActivity.notifyFlutterFilterStateChanged(false)
            }
        }
    }
}
