package dev.rudra.donut

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.text.format.DateFormat
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZonedDateTime
import java.time.temporal.ChronoUnit

/** Home-screen widget: today's day dial (AM inside, PM outside). */
class DayClockWidget : DonutClockWidget(hourView = false)

/** Home-screen widget: this hour inside, the next hour outside. */
class HourClockWidget : DonutClockWidget(hourView = true)

/**
 * A dial with a live analog clock on top.
 *
 * The app writes today's and tomorrow's saved entries as JSON under
 * [DATA_KEY] (`{"<epochDay>": [[startMin, endMin, argb], ...]}`) whenever
 * they change. The dial is redrawn from it on every update, and each
 * update books the next one (every 15 min for the day view, every 5 for
 * the hour view, so the past dims and the hour turns over on time) as a
 * non-waking alarm: it runs when the phone is next awake.
 */
abstract class DonutClockWidget(private val hourView: Boolean) : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = LocalDate.now().toEpochDay()
        val now = LocalTime.now()
        val nowMinute = now.hour * 60 + now.minute
        val json = widgetData.getString(DATA_KEY, null)
        val bitmap = if (hourView) {
            ClockBitmapRenderer.renderHour(
                parse(json, today, 0) + parse(json, today + 1, 1440),
                480,
                nowMinute,
                DateFormat.is24HourFormat(context),
            )
        } else {
            ClockBitmapRenderer.renderDay(parse(json, today, 0), 480, nowMinute)
        }
        val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.day_clock_widget).apply {
                setImageViewBitmap(R.id.widget_dial, bitmap)
                setOnClickPendingIntent(R.id.widget_root, open)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
        scheduleNext(context, appWidgetManager)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        context.getSystemService(AlarmManager::class.java)?.cancel(refreshIntent(context, IntArray(0)))
    }

    private fun scheduleNext(context: Context, manager: AppWidgetManager) {
        val ids = manager.getAppWidgetIds(ComponentName(context, javaClass))
        if (ids.isEmpty()) return
        val step = if (hourView) 5L else 15L
        val now = ZonedDateTime.now()
        val next = now.truncatedTo(ChronoUnit.HOURS)
            .plusMinutes((now.minute / step + 1) * step)
        context.getSystemService(AlarmManager::class.java)?.setWindow(
            AlarmManager.RTC,
            next.toInstant().toEpochMilli(),
            60_000L,
            refreshIntent(context, ids),
        )
    }

    private fun refreshIntent(context: Context, ids: IntArray): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            if (hourView) 2 else 1,
            Intent(context, javaClass)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** That day's entries, shifted by [offset] minutes (1440 for tomorrow). */
    private fun parse(json: String?, epochDay: Long, offset: Int): List<ClockBitmapRenderer.Entry> {
        if (json == null) return emptyList()
        return try {
            val day = JSONObject(json).optJSONArray(epochDay.toString()) ?: return emptyList()
            (0 until day.length()).map { i ->
                val e = day.getJSONArray(i)
                ClockBitmapRenderer.Entry(e.getInt(0) + offset, e.getInt(1) + offset, e.getLong(2).toInt())
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    companion object {
        const val DATA_KEY = "donut_days"
    }
}
