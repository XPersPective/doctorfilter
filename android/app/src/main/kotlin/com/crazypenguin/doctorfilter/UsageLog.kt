package com.crazypenguin.doctorfilter

import android.content.Context
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * How long the filter has been on, per day, on this device only.
 *
 * Recorded natively because the filter spends most of its life with no Flutter
 * engine alive — started by a schedule, stopped from the notification. Nothing
 * leaves the phone and there is no identifier of any kind: the point is to show
 * the user their own week, not to measure them.
 */
object UsageLog {

    private const val PREFS = "doctorfilter_usage"
    private const val KEY_SESSION_START = "session_start"

    /** A week is what the UI shows; older buckets are dropped on write. */
    const val DAYS_KEPT = 7

    /**
     * ponytail: a session longer than this is assumed to be a process death that
     * never reported its stop, and is discarded rather than credited. Twelve
     * hours is longer than any real night. Upgrade path if it ever matters: a
     * periodic heartbeat from the service.
     */
    private val MAX_SESSION_MILLIS = TimeUnit.HOURS.toMillis(12)

    fun started(context: Context, atMillis: Long = System.currentTimeMillis()) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        // A session already open means the last one was never closed. Settle it
        // before opening another, or its time is lost.
        prefs.getLong(KEY_SESSION_START, 0L).let { open ->
            if (open > 0L) record(context, open, atMillis)
        }
        prefs.edit().putLong(KEY_SESSION_START, atMillis).apply()
    }

    fun stopped(context: Context, atMillis: Long = System.currentTimeMillis()) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val start = prefs.getLong(KEY_SESSION_START, 0L)
        prefs.edit().remove(KEY_SESSION_START).apply()
        if (start > 0L) record(context, start, atMillis)
    }

    /** Minutes per day key (`yyyy-MM-dd`), most recent [DAYS_KEPT] days. */
    fun read(context: Context): Map<String, Int> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val cutoff = dayKey(daysAgo(DAYS_KEPT - 1))

        val stored = prefs.all
            .filterKeys { it != KEY_SESSION_START && it >= cutoff }
            .mapNotNull { (key, value) -> (value as? Int)?.let { key to it } }
            .toMap()

        // Whatever is running right now, so today's figure is not stale by hours.
        val open = prefs.getLong(KEY_SESSION_START, 0L)
        if (open <= 0L) return stored

        val live = stored.toMutableMap()
        split(open, System.currentTimeMillis()).forEach { (day, minutes) ->
            live[day] = (live[day] ?: 0) + minutes
        }
        return live
    }

    private fun record(context: Context, fromMillis: Long, toMillis: Long) {
        if (toMillis - fromMillis !in 1..MAX_SESSION_MILLIS) return

        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val editor = prefs.edit()

        split(fromMillis, toMillis).forEach { (day, minutes) ->
            editor.putInt(day, prefs.getInt(day, 0) + minutes)
        }

        val cutoff = dayKey(daysAgo(DAYS_KEPT - 1))
        prefs.all.keys
            .filter { it != KEY_SESSION_START && it < cutoff }
            .forEach { editor.remove(it) }

        editor.apply()
    }

    /**
     * Splits a session across the days it spans.
     *
     * A bedtime filter from 22:00 to 07:00 belongs to two days; crediting all
     * nine hours to whichever day it ended on would make the chart nonsense.
     */
    private fun split(fromMillis: Long, toMillis: Long): Map<String, Int> {
        val result = mutableMapOf<String, Int>()
        var cursor = fromMillis

        while (cursor < toMillis) {
            val endOfDay = startOfDayAfter(cursor)
            val sliceEnd = minOf(endOfDay, toMillis)
            val minutes = TimeUnit.MILLISECONDS.toMinutes(sliceEnd - cursor).toInt()
            if (minutes > 0) {
                val key = dayKey(cursor)
                result[key] = (result[key] ?: 0) + minutes
            }
            cursor = sliceEnd
        }
        return result
    }

    private fun startOfDayAfter(millis: Long): Long = Calendar.getInstance().apply {
        timeInMillis = millis
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
        add(Calendar.DAY_OF_YEAR, 1)
    }.timeInMillis

    private fun daysAgo(days: Int): Long = Calendar.getInstance().apply {
        add(Calendar.DAY_OF_YEAR, -days)
    }.timeInMillis

    /** Sorts lexicographically as well as chronologically, which the pruning relies on. */
    private fun dayKey(millis: Long): String {
        val calendar = Calendar.getInstance().apply { timeInMillis = millis }
        return "%04d-%02d-%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH)
        )
    }
}
