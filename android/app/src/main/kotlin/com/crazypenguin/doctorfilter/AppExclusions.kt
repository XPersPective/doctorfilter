package com.crazypenguin.doctorfilter

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import java.io.ByteArrayOutputStream

/**
 * Apps the filter should get out of the way for.
 *
 * A warm, dimmed screen is wrong for exactly the tasks where colour is the
 * point: taking a photo, editing one, watching a film. Without this the user
 * switches the filter off to look at something and then forgets to switch it
 * back on, which is the app quietly failing at the one thing it does.
 *
 * Built on [UsageStatsManager] rather than an accessibility service. Both can
 * name the foreground app; only one of them is an accessibility API being used
 * for something that is not accessibility. The permission here is explicit,
 * granted by the user in system settings, and revocable.
 */
object AppExclusions {

    private const val PREFS = "doctorfilter_exclusions"
    private const val KEY_PACKAGES = "packages"
    private const val KEY_ENABLED = "enabled"

    /** How far back to ask the OS about app switches. */
    private const val LOOKBACK_MILLIS = 10_000L

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, isEnabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, isEnabled).apply()
    }

    fun excluded(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()

    fun setExcluded(context: Context, packages: List<String>) {
        prefs(context).edit().putStringSet(KEY_PACKAGES, packages.toSet()).apply()
    }

    /**
     * Whether the user has granted usage access.
     *
     * Checked rather than assumed on every read: this is a permission the user
     * can revoke in settings at any time, and the feature has to notice.
     */
    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false

        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageAccessSettings(context: Context) {
        context.startActivity(
            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    /**
     * The package in front right now, or null if it cannot be determined.
     *
     * Reads the recent event stream rather than aggregate stats: aggregates are
     * bucketed by the hour and would answer "which app did you use today",
     * which is not the question.
     */
    fun foregroundPackage(context: Context): String? {
        val usage = context.getSystemService(Context.USAGE_STATS_SERVICE)
            as? UsageStatsManager ?: return null

        return try {
            val now = System.currentTimeMillis()
            val events = usage.queryEvents(now - LOOKBACK_MILLIS, now)
            val event = android.app.usage.UsageEvents.Event()
            var latest: String? = null

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    latest = event.packageName
                }
            }
            latest
        } catch (e: SecurityException) {
            // Permission revoked between the check and the read.
            null
        }
    }

    /** Label, package name and a small icon for every app with a launcher entry. */
    fun launchableApps(context: Context): List<Map<String, Any?>> {
        val packageManager = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)

        val resolved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(0L)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(intent, 0)
        }

        return resolved
            .asSequence()
            .map { it.activityInfo.packageName to it.loadLabel(packageManager).toString() }
            .filter { (packageName, _) -> packageName != context.packageName }
            .distinctBy { (packageName, _) -> packageName }
            .sortedBy { (_, label) -> label.lowercase() }
            .map { (packageName, label) ->
                mapOf(
                    "package" to packageName,
                    "label" to label,
                    "icon" to iconBytes(context, packageName)
                )
            }
            .toList()
    }

    /**
     * A 96px PNG per app.
     *
     * Small enough that a few hundred of them cross the channel without anyone
     * noticing, large enough to look right on a high-density screen. A picker
     * without icons is a wall of text nobody can scan.
     */
    private fun iconBytes(context: Context, packageName: String): ByteArray? = try {
        val drawable = context.packageManager.getApplicationIcon(packageName)
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(bitmap))

        ByteArrayOutputStream().also { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        }.toByteArray()
    } catch (e: Exception) {
        // An icon that will not render is not worth failing the whole list for.
        null
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
