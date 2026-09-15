package com.crazypenguin.doctorfilter

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast

/**
 * Invisible trampoline for launcher shortcuts.
 *
 * A shortcut has to target an activity, but the point of one is *not* opening
 * the app: it starts the service and finishes before anything is drawn.
 */
class ShortcutActivity : Activity() {

    companion object {
        const val EXTRA_PRESET_ID = "preset_id"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val presetId = intent?.getIntExtra(EXTRA_PRESET_ID, -1) ?: -1

        // Without the overlay permission there is nothing to start, and a
        // shortcut that silently does nothing is worse than one that explains.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Toast.makeText(this, getString(R.string.shortcut_needs_permission), Toast.LENGTH_LONG)
                .show()
            startActivity(
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            finish()
            return
        }

        val service = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
            if (presetId >= 0) putExtra(OverlayService.EXTRA_PRESET_ID, presetId)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(service)
        } else {
            startService(service)
        }

        // Dart resolves the preset to exact values the next time it runs; until
        // then the overlay shows the last-known composite.
        if (presetId >= 0) MainActivity.notifyPresetSelected(presetId)

        finish()
    }
}
