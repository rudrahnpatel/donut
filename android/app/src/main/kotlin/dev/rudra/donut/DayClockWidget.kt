package dev.rudra.donut

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalTime

/**
 * Home-screen widget: today's dial with a live hour hand.
 *
 * The app writes today's and tomorrow's saved entries as JSON under
 * [DATA_KEY] (`{"<epochDay>": [[startMin, endMin, argb], ...]}`) whenever
 * they change; this provider redraws from it on every update, including
 * the periodic one, so the dial also turns over at midnight by itself.
 */
class DayClockWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = LocalDate.now().toEpochDay()
        val now = LocalTime.now()
        val entries = parse(widgetData.getString(DATA_KEY, null), today)
        val bitmap = ClockBitmapRenderer.render(entries, 480, now.hour * 60 + now.minute)
        val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.day_clock_widget).apply {
                setImageViewBitmap(R.id.widget_dial, bitmap)
                setOnClickPendingIntent(R.id.widget_root, open)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun parse(json: String?, epochDay: Long): List<ClockBitmapRenderer.Entry> {
        if (json == null) return emptyList()
        return try {
            val day = JSONObject(json).optJSONArray(epochDay.toString()) ?: return emptyList()
            (0 until day.length()).map { i ->
                val e = day.getJSONArray(i)
                ClockBitmapRenderer.Entry(e.getInt(0), e.getInt(1), e.getLong(2).toInt())
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    companion object {
        const val DATA_KEY = "donut_days"
    }
}
