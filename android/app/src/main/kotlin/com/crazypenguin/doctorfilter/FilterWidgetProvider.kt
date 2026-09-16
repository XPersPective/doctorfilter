package com.crazypenguin.doctorfilter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.provider.Settings
import android.widget.RemoteViews

/**
 * Home-screen widget: one tap to toggle the filter.
 *
 * The widget and the Quick Settings tile answer the same need from opposite
 * habits — some people live in the shade, some on the home screen. Both are
 * cheap because the work is already in [OverlayService].
 */
class FilterWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE = "com.crazypenguin.doctorfilter.widget.TOGGLE"

        /**
         * Repaints every placed widget.
         *
         * Called whenever the filter changes from anywhere — app, notification,
         * tile or scheduler — so the widget never sits there showing "off" while
         * the screen is visibly tinted.
         */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(
                ComponentName(context, FilterWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return
            ids.forEach { id -> manager.updateAppWidget(id, buildViews(context)) }
        }

        private fun buildViews(context: Context): RemoteViews {
            val running = OverlayService.isRunning
            val values = OverlayService.current

            return RemoteViews(context.packageName, R.layout.widget_filter).apply {
                setTextViewText(
                    R.id.widget_status,
                    PresetCatalog.text(context,
                        if (running) R.string.widget_on else R.string.widget_off
                    )
                )
                setTextViewText(
                    R.id.widget_detail,
                    if (running) {
                        PresetCatalog.text(context, R.string.axis_value_kelvin, values.kelvin)
                    } else {
                        PresetCatalog.text(context, R.string.app_name)
                    }
                )
                setInt(
                    R.id.widget_swatch,
                    "setBackgroundColor",
                    if (running) {
                        Color.rgb(values.red, values.green, values.blue)
                    } else {
                        Color.argb(60, 128, 128, 128)
                    }
                )

                val intent = Intent(context, FilterWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE
                    setPackage(context.packageName)
                }
                setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getBroadcast(
                        context,
                        0,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                )
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { id -> appWidgetManager.updateAppWidget(id, buildViews(context)) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_TOGGLE) return

        if (!canDrawOverlays(context)) {
            // Nothing can be drawn without the permission; open the app rather
            // than toggling a filter that would be invisible.
            context.startActivity(
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
            )
            return
        }

        if (OverlayService.isRunning) {
            context.startService(
                Intent(context, OverlayService::class.java).apply {
                    action = OverlayService.ACTION_STOP
                }
            )
            MainActivity.notifyFilterToggled(false)
        } else {
            val start = Intent(context, OverlayService::class.java).apply {
                action = OverlayService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(start)
            } else {
                context.startService(start)
            }
            MainActivity.notifyFilterToggled(true)
        }

        refreshAll(context)
    }

    private fun canDrawOverlays(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)
}
