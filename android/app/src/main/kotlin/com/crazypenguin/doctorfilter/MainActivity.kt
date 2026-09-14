package com.crazypenguin.doctorfilter

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL_NAME = "com.crazypenguin.doctorfilter"
        private var activeMethodChannel: MethodChannel? = null

        fun notifyFlutterFilterStateChanged(isEnabled: Boolean) {
            activeMethodChannel?.invokeMethod(
                "onFilterStateChanged",
                mapOf("isEnabled" to isEnabled)
            )
        }

        fun notifyFlutterDensityChanged(alpha: Int) {
            activeMethodChannel?.invokeMethod(
                "onDensityChanged",
                mapOf("alpha" to alpha)
            )
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        activeMethodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(null)
                }

                "startOverlay" -> {
                    val red = call.argument<Int>("red") ?: 255
                    val green = call.argument<Int>("green") ?: 219
                    val blue = call.argument<Int>("blue") ?: 186
                    val alpha = call.argument<Int>("alpha") ?: 25
                    val brightness = call.argument<Int>("brightness") ?: 195
                    val kelvin = call.argument<Int>("kelvin") ?: 5500

                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_START
                        putExtra(OverlayService.EXTRA_RED, red)
                        putExtra(OverlayService.EXTRA_GREEN, green)
                        putExtra(OverlayService.EXTRA_BLUE, blue)
                        putExtra(OverlayService.EXTRA_ALPHA, alpha)
                        putExtra(OverlayService.EXTRA_BRIGHTNESS, brightness)
                        putExtra(OverlayService.EXTRA_KELVIN, kelvin)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }

                "updateOverlay" -> {
                    val red = call.argument<Int>("red") ?: OverlayService.currentRed
                    val green = call.argument<Int>("green") ?: OverlayService.currentGreen
                    val blue = call.argument<Int>("blue") ?: OverlayService.currentBlue
                    val alpha = call.argument<Int>("alpha") ?: OverlayService.currentAlpha
                    val brightness = call.argument<Int>("brightness") ?: OverlayService.currentBrightness
                    val kelvin = call.argument<Int>("kelvin") ?: OverlayService.currentKelvin

                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_UPDATE
                        putExtra(OverlayService.EXTRA_RED, red)
                        putExtra(OverlayService.EXTRA_GREEN, green)
                        putExtra(OverlayService.EXTRA_BLUE, blue)
                        putExtra(OverlayService.EXTRA_ALPHA, alpha)
                        putExtra(OverlayService.EXTRA_BRIGHTNESS, brightness)
                        putExtra(OverlayService.EXTRA_KELVIN, kelvin)
                    }
                    startService(intent)
                    result.success(true)
                }

                "stopOverlay" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }

                "isFilterRunning" -> {
                    result.success(OverlayService.isRunning)
                }

                "setSchedule" -> {
                    val isEnabled = call.argument<Boolean>("isEnabled") ?: false
                    val startHour = call.argument<Int>("startHour") ?: 22
                    val startMinute = call.argument<Int>("startMinute") ?: 0
                    val stopHour = call.argument<Int>("stopHour") ?: 7
                    val stopMinute = call.argument<Int>("stopMinute") ?: 0

                    ScheduleReceiver.updateSchedule(
                        context = this,
                        isEnabled = isEnabled,
                        startHour = startHour,
                        startMinute = startMinute,
                        stopHour = stopHour,
                        stopMinute = stopMinute
                    )
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        activeMethodChannel = null
        super.onDestroy()
    }
}
