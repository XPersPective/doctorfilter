package com.crazypenguin.doctorfilter

import android.annotation.TargetApi
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick Settings tile — turn the filter on or off from the shade.
 *
 * The single most requested control for an app like this: at bedtime the user is
 * already pulling the shade down to dim the screen, and the filter belongs in
 * the same gesture rather than two taps deeper in an app.
 */
@TargetApi(Build.VERSION_CODES.N)
class FilterTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        refresh()
    }

    override fun onClick() {
        super.onClick()

        // Without overlay permission the service would start and draw nothing,
        // so send the user to grant it instead of failing silently.
        if (!canDrawOverlays()) {
            openApp()
            return
        }

        if (OverlayService.isRunning) {
            startService(
                Intent(this, OverlayService::class.java).apply {
                    action = OverlayService.ACTION_STOP
                }
            )
            MainActivity.notifyFilterToggled(false)
        } else {
            val intent = Intent(this, OverlayService::class.java).apply {
                action = OverlayService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            MainActivity.notifyFilterToggled(true)
        }

        refresh()
    }

    private fun refresh() {
        val tile = qsTile ?: return
        val running = OverlayService.isRunning
        tile.state = if (running) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = getString(R.string.app_name)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = if (running) {
                getString(R.string.tile_subtitle_active, OverlayService.current.kelvin)
            } else {
                getString(R.string.tile_subtitle_off)
            }
        }
        tile.updateTile()
    }

    private fun canDrawOverlays(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)

    private fun openApp() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                android.app.PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                            android.app.PendingIntent.FLAG_IMMUTABLE
                )
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
