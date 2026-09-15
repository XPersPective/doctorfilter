package com.crazypenguin.doctorfilter

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * The preset list, mirrored natively so the notification can show it.
 *
 * Presets live in SQLite on the Dart side, with names that come from the app's
 * localisation files. The notification, however, is frequently built by a
 * service running with no Flutter engine alive — after a reboot, or once the
 * system has killed the UI process. It cannot query the database or the
 * translations, so Dart pushes a flattened copy down whenever the list changes
 * and this reads it back.
 */
object PresetCatalog {

    private const val PREFS = "doctorfilter_presets"
    private const val KEY_JSON = "catalog"
    private const val KEY_IS_PRO = "is_pro"

    /**
     * [locked] is decided by Dart, not here: entitlement is a domain concept and
     * duplicating the rule in two languages is how the two end up disagreeing.
     */
    data class Entry(
        val id: Int,
        val name: String,
        val colour: Int,
        val locked: Boolean
    )

    fun save(context: Context, json: String, isPro: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_JSON, json)
            .putBoolean(KEY_IS_PRO, isPro)
            .apply()
    }

    fun isPro(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_IS_PRO, false)

    fun read(context: Context): List<Entry> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_JSON, null) ?: return emptyList()

        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { index ->
                val item = array.getJSONObject(index)
                Entry(
                    id = item.getInt("id"),
                    name = item.optString("name"),
                    colour = item.optInt("colour"),
                    locked = item.optBoolean("locked", false)
                )
            }
        } catch (e: Exception) {
            // A malformed catalogue should cost the user the chips, not the
            // whole notification.
            emptyList()
        }
    }

    /** Builds the JSON Dart sends down; kept here so both sides share one shape. */
    fun encode(entries: List<Entry>): String {
        val array = JSONArray()
        entries.forEach { entry ->
            array.put(
                JSONObject()
                    .put("id", entry.id)
                    .put("name", entry.name)
                    .put("colour", entry.colour)
                    .put("locked", entry.locked)
            )
        }
        return array.toString()
    }
}
