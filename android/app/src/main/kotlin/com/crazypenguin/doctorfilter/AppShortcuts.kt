package com.crazypenguin.doctorfilter

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.Icon
import android.os.Build
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * Long-press shortcuts on the launcher icon: pick a preset without opening the app.
 *
 * Built from the same catalogue the notification uses, so the shortcuts are the
 * user's real presets rather than a fixed list that goes stale the moment they
 * make one of their own.
 */
object AppShortcuts {

    /** Launchers show four at most on nearly every device; more is wasted work. */
    private const val MAX_SHORTCUTS = 4

    fun refresh(context: Context) {
        val presets = PresetCatalog.read(context)
            .filterNot { it.locked }
            .take(MAX_SHORTCUTS)

        if (presets.isEmpty()) {
            ShortcutManagerCompat.removeAllDynamicShortcuts(context)
            return
        }

        val shortcuts = presets.map { preset ->
            ShortcutInfoCompat.Builder(context, "preset_${preset.id}")
                .setShortLabel(preset.name)
                .setLongLabel(preset.name)
                .setIcon(swatch(preset.colour))
                .setIntent(
                    Intent(context, ShortcutActivity::class.java).apply {
                        action = Intent.ACTION_VIEW
                        putExtra(ShortcutActivity.EXTRA_PRESET_ID, preset.id)
                    }
                )
                .build()
        }

        try {
            ShortcutManagerCompat.setDynamicShortcuts(context, shortcuts)
        } catch (e: IllegalArgumentException) {
            // Some launchers cap the count lower than they report. Losing the
            // shortcuts is not worth a crash.
        }
    }

    /**
     * A filled circle in the preset's own colour.
     *
     * Four identical icons would tell the user nothing; the colour is exactly
     * what distinguishes one preset from another everywhere else in the app.
     */
    private fun swatch(colour: Int): IconCompat {
        val size = 108
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).apply {
            drawColor(Color.TRANSPARENT)
            drawCircle(
                size / 2f,
                size / 2f,
                size / 2f - 4f,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colour or Color.BLACK }
            )
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            IconCompat.createFromIcon(Icon.createWithAdaptiveBitmap(bitmap))!!
        } else {
            IconCompat.createWithBitmap(bitmap)
        }
    }
}
