package com.crazypenguin.doctorfilter

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter ↔ Android bridge.
 *
 * Dart owns what the filter *means*; this class owns what the OS is asked to do
 * about it. The channel therefore carries an already-composited colour and alpha
 * downwards, and raw user intent — "the notification's dim button was pressed" —
 * upwards.
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL_NAME = "com.crazypenguin.doctorfilter"

        private var channel: MethodChannel? = null

        /**
         * Calls from native to Dart are best-effort. The notification outlives
         * the UI process, so there is frequently nothing on the other end — and
         * that is fine, because native state is already persisted.
         */
        private fun send(method: String, arguments: Map<String, Any?>) {
            channel?.invokeMethod(method, arguments)
        }

        fun notifyFilterToggled(isEnabled: Boolean) =
            send("onFilterStateChanged", mapOf("isEnabled" to isEnabled))

        fun notifyPresetSelected(presetId: Int) =
            send("onPresetSelected", mapOf("presetId" to presetId))

        fun notifyNextPresetRequested() =
            send("onPresetSelected", mapOf("presetId" to -2))

        fun notifyAxisChanged(
            kelvin: Int? = null,
            densityPercent: Int? = null,
            extraDimPercent: Int? = null
        ) = send(
            "onAxisChanged",
            mapOf(
                "kelvin" to kelvin,
                "densityPercent" to densityPercent,
                "extraDimPercent" to extraDimPercent
            )
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel = methodChannel

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> result.success(canDrawOverlays())
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }

                "startOverlay", "updateOverlay" -> {
                    startOverlay(call.toValues())
                    result.success(true)
                }

                "stopOverlay" -> {
                    startService(
                        Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_STOP
                        }
                    )
                    result.success(true)
                }

                "isFilterRunning" -> result.success(OverlayService.isRunning)

                // Dart pushes the preset list down so the notification can show
                // it without a database or the translations.
                "setPresetCatalog" -> {
                    PresetCatalog.save(
                        context = this,
                        json = call.argument<String>("presets") ?: "[]",
                        isPro = call.argument<Boolean>("isPro") ?: false
                    )
                    refreshNotification()
                    AppShortcuts.refresh(this)
                    result.success(true)
                }

                "isBatteryOptimised" -> result.success(isBatteryOptimised())
                "openBatterySettings" -> {
                    openBatterySettings()
                    result.success(true)
                }

                "canScheduleExactAlarms" -> result.success(canScheduleExactAlarms())
                "requestExactAlarmPermission" -> {
                    requestExactAlarmPermission()
                    result.success(true)
                }

                "setSchedule" -> {
                    ScheduleReceiver.updateSchedule(
                        context = this,
                        isEnabled = call.argument<Boolean>("isEnabled") ?: false,
                        startHour = call.argument<Int>("startHour") ?: 22,
                        startMinute = call.argument<Int>("startMinute") ?: 0,
                        stopHour = call.argument<Int>("stopHour") ?: 7,
                        stopMinute = call.argument<Int>("stopMinute") ?: 0,
                        targetPresetId = call.argument<Int>("targetPresetId") ?: 5,
                        transitionMinutes = call.argument<Int>("transitionMinutes") ?: 0
                    )
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun io.flutter.plugin.common.MethodCall.toValues(): FilterState.Values {
        val stored = FilterState.read(this@MainActivity)
        return FilterState.Values(
            red = argument<Int>("red") ?: stored.red,
            green = argument<Int>("green") ?: stored.green,
            blue = argument<Int>("blue") ?: stored.blue,
            alpha = argument<Int>("alpha") ?: stored.alpha,
            kelvin = argument<Int>("kelvin") ?: stored.kelvin,
            densityPercent = argument<Int>("densityPercent") ?: stored.densityPercent,
            extraDimPercent = argument<Int>("extraDimPercent") ?: stored.extraDimPercent,
            presetId = argument<Int>("activePresetId") ?: stored.presetId,
            notificationEnabled = argument<Boolean>("isNotificationEnabled")
                ?: stored.notificationEnabled
        )
    }

    private fun startOverlay(values: FilterState.Values) {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
            putExtra(OverlayService.EXTRA_RED, values.red)
            putExtra(OverlayService.EXTRA_GREEN, values.green)
            putExtra(OverlayService.EXTRA_BLUE, values.blue)
            putExtra(OverlayService.EXTRA_ALPHA, values.alpha)
            putExtra(OverlayService.EXTRA_KELVIN, values.kelvin)
            putExtra(OverlayService.EXTRA_DENSITY, values.densityPercent)
            putExtra(OverlayService.EXTRA_EXTRA_DIM, values.extraDimPercent)
            putExtra(OverlayService.EXTRA_PRESET_ID, values.presetId)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    /**
     * Redraws the notification in place.
     *
     * Only when the service is running: posting this notification without a
     * foreground service behind it would leave an orphan the user cannot dismiss.
     */
    private fun refreshNotification() {
        if (!OverlayService.isRunning) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE)
                as android.app.NotificationManager
        manager.notify(
            FilterNotificationManager.NOTIFICATION_ID,
            FilterNotificationManager.buildNotification(
                context = this,
                isActive = true,
                values = OverlayService.current
            )
        )
    }

    private fun canDrawOverlays(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        startActivity(
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
        )
    }

    /**
     * Whether the OS is still allowed to doze this app.
     *
     * Aggressive OEM power management (Xiaomi, Huawei, Samsung and others) will
     * kill even a foreground service, and the user sees the filter switch itself
     * off overnight for no visible reason.
     */
    private fun isBatteryOptimised(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        return !powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    /**
     * Opens the system's battery-optimisation list.
     *
     * Deliberately the *list*, not a direct "exempt me" prompt: that prompt needs
     * REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, which Play restricts to a short list
     * of qualifying use cases a screen filter is not on. Asking for it would risk
     * the listing; walking the user to the setting achieves the same thing and
     * leaves the choice visibly theirs.
     */
    private fun openBatterySettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
        }
        try {
            startActivity(intent)
        } catch (e: android.content.ActivityNotFoundException) {
            // Some OEM builds ship without the screen. Fall back to app info,
            // which every device has.
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
            )
        }
    }

    /**
     * Android 12 stopped granting exact alarms automatically. Without this the
     * schedule silently drifts by minutes, which for a bedtime filter is the
     * difference between working and not.
     */
    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
    }

    private fun requestExactAlarmPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        startActivity(
            Intent(
                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                Uri.parse("package:$packageName")
            )
        )
    }

    override fun onDestroy() {
        channel = null
        super.onDestroy()
    }
}
