package com.crazypenguin.doctorfilter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

/**
 * Builds the persistent control notification.
 *
 * Two layers of control:
 *
 * * **Collapsed** — status and the power button, for when the shade is barely open.
 * * **Expanded** — the cockpit: preset chips and steppers for all three axes, so
 *   the filter can be driven without opening the app at all.
 *
 * Standard notification actions are kept alongside the custom views, because
 * Android Auto, Wear and some launchers render actions but not custom layouts.
 *
 * Every action carries a real drawable. Android silently drops actions whose
 * icon resource is 0, which is why the previous version showed a notification
 * with no buttons at all — the code looked right and the controls simply were
 * not there.
 */
object FilterNotificationManager {

    const val CHANNEL_ID = "doctorfilter_active"
    const val NOTIFICATION_ID = 1001

    const val ACTION_TOGGLE = "com.crazypenguin.doctorfilter.action.TOGGLE"
    const val ACTION_DIM_MORE = "com.crazypenguin.doctorfilter.action.DIM_MORE"
    const val ACTION_DIM_LESS = "com.crazypenguin.doctorfilter.action.DIM_LESS"
    const val ACTION_NEXT_PRESET = "com.crazypenguin.doctorfilter.action.NEXT_PRESET"
    const val ACTION_AXIS_STEP = "com.crazypenguin.doctorfilter.action.AXIS_STEP"
    const val ACTION_SELECT_PRESET = "com.crazypenguin.doctorfilter.action.SELECT_PRESET"
    const val ACTION_OPEN_PAYWALL = "com.crazypenguin.doctorfilter.action.OPEN_PAYWALL"

    const val EXTRA_AXIS = "axis"
    const val EXTRA_STEP = "step"
    const val EXTRA_PRESET_ID = "preset_id"

    const val AXIS_KELVIN = "kelvin"
    const val AXIS_DENSITY = "density"
    const val AXIS_DIM = "dim"

    /** Slots in the expanded layout. More presets than this simply do not fit. */
    private const val CHIP_SLOTS = 6

    private val chipRoots = intArrayOf(
        R.id.chip_0, R.id.chip_1, R.id.chip_2, R.id.chip_3, R.id.chip_4, R.id.chip_5
    )
    private val chipSwatches = intArrayOf(
        R.id.chip_swatch_0, R.id.chip_swatch_1, R.id.chip_swatch_2,
        R.id.chip_swatch_3, R.id.chip_swatch_4, R.id.chip_swatch_5
    )
    private val chipLabels = intArrayOf(
        R.id.chip_label_0, R.id.chip_label_1, R.id.chip_label_2,
        R.id.chip_label_3, R.id.chip_label_4, R.id.chip_label_5
    )
    private val chipLocks = intArrayOf(
        R.id.chip_lock_0, R.id.chip_lock_1, R.id.chip_lock_2,
        R.id.chip_lock_3, R.id.chip_lock_4, R.id.chip_lock_5
    )

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            PresetCatalog.text(context, R.string.notification_channel_name),
            // The filter runs all evening; this must never make a sound, vibrate
            // or peek over whatever the user is doing.
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = PresetCatalog.text(context, R.string.notification_channel_description)
            setShowBadge(false)
            enableVibration(false)
            enableLights(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }

        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(channel)
    }

    fun buildNotification(
        context: Context,
        isActive: Boolean,
        values: FilterState.Values
    ): Notification {
        createNotificationChannel(context)

        val title = if (isActive) {
            PresetCatalog.text(context, R.string.notification_title_active, values.kelvin)
        } else {
            PresetCatalog.text(context, R.string.notification_title_paused)
        }
        val summary = PresetCatalog.text(context,
            R.string.notification_summary,
            values.densityPercent,
            values.extraDimPercent
        )

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(summary)
            .setContentIntent(openApp(context))
            .setCustomContentView(collapsedView(context, title, summary))
            .setCustomBigContentView(cockpitView(context, title, summary, values))
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setOngoing(isActive)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                R.drawable.ic_power,
                PresetCatalog.text(context,
                    if (isActive) R.string.notification_action_off
                    else R.string.notification_action_on
                ),
                broadcast(context, ACTION_TOGGLE, REQUEST_TOGGLE)
            )
            .addAction(
                R.drawable.ic_dimmer,
                PresetCatalog.text(context, R.string.notification_action_dimmer),
                broadcast(context, ACTION_DIM_MORE, REQUEST_DIM_MORE)
            )
            .addAction(
                R.drawable.ic_brighter,
                PresetCatalog.text(context, R.string.notification_action_brighter),
                broadcast(context, ACTION_DIM_LESS, REQUEST_DIM_LESS)
            )
            .addAction(
                R.drawable.ic_next_preset,
                PresetCatalog.text(context, R.string.notification_action_next_preset),
                broadcast(context, ACTION_NEXT_PRESET, REQUEST_NEXT_PRESET)
            )
            .build()
    }

    private fun collapsedView(context: Context, title: String, summary: String) =
        RemoteViews(context.packageName, R.layout.notification_collapsed).apply {
            setTextViewText(R.id.collapsed_title, title)
            setTextViewText(R.id.collapsed_summary, summary)
            setOnClickPendingIntent(
                R.id.collapsed_power,
                broadcast(context, ACTION_TOGGLE, REQUEST_TOGGLE)
            )
        }

    private fun cockpitView(
        context: Context,
        title: String,
        summary: String,
        values: FilterState.Values
    ) = RemoteViews(context.packageName, R.layout.notification_cockpit).apply {
        setTextViewText(R.id.cockpit_title, title)
        setTextViewText(R.id.cockpit_summary, summary)
        setOnClickPendingIntent(
            R.id.cockpit_power,
            broadcast(context, ACTION_TOGGLE, REQUEST_TOGGLE)
        )

        bindPresets(context, values)
        bindAxes(context, values)
    }

    private fun RemoteViews.bindPresets(context: Context, values: FilterState.Values) {
        val presets = PresetCatalog.read(context)

        for (slot in 0 until CHIP_SLOTS) {
            val preset = presets.getOrNull(slot)
            if (preset == null) {
                setViewVisibility(chipRoots[slot], View.GONE)
                continue
            }

            setViewVisibility(chipRoots[slot], View.VISIBLE)
            setTextViewText(chipLabels[slot], preset.name)
            setViewVisibility(chipLocks[slot], if (preset.locked) View.VISIBLE else View.GONE)

            // A locked preset is shown rather than hidden: the point is that the
            // user can see what Pro would give them.
            val swatch = if (preset.locked) dim(preset.colour) else preset.colour
            setInt(chipSwatches[slot], "setBackgroundColor", swatch)

            // The active preset gets a ring of its own colour behind the chip.
            setInt(
                chipRoots[slot],
                "setBackgroundColor",
                if (preset.id == values.presetId) translucent(preset.colour) else Color.TRANSPARENT
            )

            setOnClickPendingIntent(
                chipRoots[slot],
                if (preset.locked) {
                    paywall(context, REQUEST_PRESET_BASE + slot)
                } else {
                    broadcast(
                        context,
                        ACTION_SELECT_PRESET,
                        REQUEST_PRESET_BASE + slot
                    ) { it.putExtra(EXTRA_PRESET_ID, preset.id) }
                }
            )
        }
    }

    private fun RemoteViews.bindAxes(context: Context, values: FilterState.Values) {
        val isPro = PresetCatalog.isPro(context)

        bindAxis(
            context = context,
            axis = AXIS_KELVIN,
            labelId = R.id.axis_label_kelvin,
            valueId = R.id.axis_value_kelvin,
            minusId = R.id.axis_minus_kelvin,
            plusId = R.id.axis_plus_kelvin,
            label = PresetCatalog.text(context, R.string.axis_kelvin),
            value = PresetCatalog.text(context, R.string.axis_value_kelvin, values.kelvin),
            step = KELVIN_STEP,
            requestBase = REQUEST_AXIS_KELVIN,
            enabled = isPro
        )
        bindAxis(
            context = context,
            axis = AXIS_DENSITY,
            labelId = R.id.axis_label_density,
            valueId = R.id.axis_value_density,
            minusId = R.id.axis_minus_density,
            plusId = R.id.axis_plus_density,
            label = PresetCatalog.text(context, R.string.axis_density),
            value = PresetCatalog.text(context, R.string.axis_value_percent, values.densityPercent),
            step = PERCENT_STEP,
            requestBase = REQUEST_AXIS_DENSITY,
            enabled = isPro
        )
        // Extra dim stays available to everyone. It is the axis that does the most
        // for the user (Nagare et al., 2019), and a free user who can never feel
        // the app work has no reason to buy anything.
        bindAxis(
            context = context,
            axis = AXIS_DIM,
            labelId = R.id.axis_label_dim,
            valueId = R.id.axis_value_dim,
            minusId = R.id.axis_minus_dim,
            plusId = R.id.axis_plus_dim,
            label = PresetCatalog.text(context, R.string.axis_dim),
            value = PresetCatalog.text(context, R.string.axis_value_percent, values.extraDimPercent),
            step = PERCENT_STEP,
            requestBase = REQUEST_AXIS_DIM,
            enabled = true
        )

        setViewVisibility(R.id.cockpit_pro_hint, if (isPro) View.GONE else View.VISIBLE)
        setTextViewText(
            R.id.cockpit_pro_hint,
            PresetCatalog.text(context, R.string.notification_pro_required)
        )
        if (!isPro) {
            setOnClickPendingIntent(R.id.cockpit_pro_hint, paywall(context, REQUEST_PAYWALL))
        }
    }

    private fun RemoteViews.bindAxis(
        context: Context,
        axis: String,
        labelId: Int,
        valueId: Int,
        minusId: Int,
        plusId: Int,
        label: String,
        value: String,
        step: Int,
        requestBase: Int,
        enabled: Boolean
    ) {
        setTextViewText(labelId, label)
        setTextViewText(valueId, value)

        if (!enabled) {
            // Visible but inert, with the lock explained once at the bottom of
            // the panel rather than repeated on every row.
            setImageViewResource(minusId, R.drawable.ic_locked)
            setImageViewResource(plusId, R.drawable.ic_locked)
            val toPaywall = paywall(context, requestBase)
            setOnClickPendingIntent(minusId, toPaywall)
            setOnClickPendingIntent(plusId, toPaywall)
            return
        }

        setOnClickPendingIntent(
            minusId,
            broadcast(context, ACTION_AXIS_STEP, requestBase) {
                it.putExtra(EXTRA_AXIS, axis).putExtra(EXTRA_STEP, -step)
            }
        )
        setOnClickPendingIntent(
            plusId,
            broadcast(context, ACTION_AXIS_STEP, requestBase + 1) {
                it.putExtra(EXTRA_AXIS, axis).putExtra(EXTRA_STEP, step)
            }
        )
    }

    private fun dim(colour: Int) = Color.argb(
        90, Color.red(colour), Color.green(colour), Color.blue(colour)
    )

    private fun translucent(colour: Int) = Color.argb(
        60, Color.red(colour), Color.green(colour), Color.blue(colour)
    )

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

    private fun paywall(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_PAYWALL
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun broadcast(
        context: Context,
        action: String,
        requestCode: Int,
        extras: (Intent) -> Intent = { it }
    ): PendingIntent {
        val intent = extras(
            Intent(context, NotificationActionReceiver::class.java).apply {
                this.action = action
                // Explicit package: an implicit broadcast would be refused on
                // Android 8+ and the button would appear to do nothing.
                setPackage(context.packageName)
            }
        )
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** One tap should be a visible change without overshooting. */
    const val KELVIN_STEP = 200
    const val PERCENT_STEP = 10

    private const val REQUEST_OPEN = 0
    private const val REQUEST_TOGGLE = 1
    private const val REQUEST_DIM_MORE = 2
    private const val REQUEST_DIM_LESS = 3
    private const val REQUEST_NEXT_PRESET = 4
    private const val REQUEST_PAYWALL = 5
    private const val REQUEST_AXIS_KELVIN = 10
    private const val REQUEST_AXIS_DENSITY = 20
    private const val REQUEST_AXIS_DIM = 30
    private const val REQUEST_PRESET_BASE = 100
}
