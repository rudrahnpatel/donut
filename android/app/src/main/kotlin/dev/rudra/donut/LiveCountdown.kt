package dev.rudra.donut

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import org.json.JSONArray
import org.json.JSONObject

/**
 * The "happening now" countdown as an Android 16 Live Update: promoted, so
 * the status bar shows a chip with the entry's emoji and the time left
 * (ticked by the system), like a call timer.
 *
 * flutter_local_notifications can't request promotion, so on API 36+ Dart
 * hands countdowns here instead. They are posted now or at their start by
 * an exact alarm, and the schedule is kept in prefs so a reboot re-arms it.
 */
object LiveCountdown {
    private const val PREFS = "donut_live"
    private const val KEY = "schedule"
    const val EXTRA_JSON = "live_json"
    const val EXTRA_ACTION = "donut_action"

    fun supported(): Boolean = Build.VERSION.SDK_INT >= 36

    /** Whether the system will promote our notifications (user can turn Live Updates off). */
    fun canPromote(ctx: Context): Boolean =
        supported() && ctx.getSystemService(NotificationManager::class.java)
            .canPostPromotedNotifications()

    /** Replaces every pending countdown alarm with [items] (start in the future). */
    fun schedule(ctx: Context, items: JSONArray) {
        cancelAlarms(ctx)
        val am = ctx.getSystemService(AlarmManager::class.java)
        for (i in 0 until items.length()) {
            val o = items.getJSONObject(i)
            am.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP, o.getLong("at"), alarmIntent(ctx, o)
            )
        }
        prefs(ctx).edit().putString(KEY, items.toString()).apply()
    }

    /** After a reboot: re-arms what is still ahead, shows what is under way. */
    fun rearm(ctx: Context) {
        val saved = JSONArray(prefs(ctx).getString(KEY, "[]"))
        val now = System.currentTimeMillis()
        val ahead = JSONArray()
        for (i in 0 until saved.length()) {
            val o = saved.getJSONObject(i)
            when {
                o.getLong("at") > now -> ahead.put(o)
                o.getLong("until") > now -> show(ctx, o.put("alert", false))
            }
        }
        schedule(ctx, ahead)
    }

    private fun cancelAlarms(ctx: Context) {
        val am = ctx.getSystemService(AlarmManager::class.java)
        val saved = JSONArray(prefs(ctx).getString(KEY, "[]"))
        for (i in 0 until saved.length()) {
            am.cancel(alarmIntent(ctx, saved.getJSONObject(i)))
        }
    }

    private fun alarmIntent(ctx: Context, o: JSONObject): PendingIntent =
        PendingIntent.getBroadcast(
            ctx,
            o.getInt("id"),
            Intent(ctx, LiveCountdownReceiver::class.java)
                .setAction("dev.rudra.donut.LIVE")
                .putExtra(EXTRA_JSON, o.toString()),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /**
     * Posts the countdown. [o]: id, title, body, emoji, until (epoch ms),
     * alert (sound + heads-up, when it is the start reminder itself).
     */
    fun show(ctx: Context, o: JSONObject) {
        if (!supported()) return
        val until = o.getLong("until")
        val now = System.currentTimeMillis()
        if (until <= now) return
        val nm = ctx.getSystemService(NotificationManager::class.java)
        val alert = o.optBoolean("alert", false)
        val channel = if (alert) "entries" else "now"
        ensureChannel(nm, channel)
        val id = o.getInt("id")
        val emoji = o.optString("emoji", "")
        val smallIcon = emojiIcon(emoji) ?: Icon.createWithResource(ctx, R.drawable.ic_stat_donut)

        val n = Notification.Builder(ctx, channel)
            .setSmallIcon(smallIcon)
            .setContentTitle(o.getString("title"))
            .setContentText(o.optString("body"))
            .setContentIntent(openApp(ctx, id, null))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_PROGRESS)
            // The chip and the shade both count down to the end.
            .setWhen(until)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setTimeoutAfter(until - now)
            // Builder.setRequestPromotedOngoing is API 36.1; the extra it sets
            // (EXTRA_REQUEST_PROMOTED_ONGOING) works from 36.
            .addExtras(Bundle().apply { putBoolean("android.requestPromotedOngoing", true) })
            .addAction(lateAction(ctx, id, 5))
            .addAction(lateAction(ctx, id, 10))
            .build()
        nm.notify(id, n)
    }

    private fun lateAction(ctx: Context, id: Int, min: Int) = Notification.Action.Builder(
        null, "+$min min late", openApp(ctx, id * 31 + min, "late:$min")
    ).build()

    /** Opens Donut; [action] (e.g. `late:5`) is handed to Dart by MainActivity. */
    private fun openApp(ctx: Context, request: Int, action: String?): PendingIntent =
        PendingIntent.getActivity(
            ctx,
            request,
            Intent(ctx, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .apply { if (action != null) putExtra(EXTRA_ACTION, action) },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun ensureChannel(nm: NotificationManager, id: String) {
        if (nm.getNotificationChannel(id) != null) return
        val ch = if (id == "entries") {
            NotificationChannel(id, "Entry reminders", NotificationManager.IMPORTANCE_HIGH)
                .apply { description = "A nudge when a saved entry starts" }
        } else {
            NotificationChannel(id, "Happening now", NotificationManager.IMPORTANCE_LOW)
                .apply { description = "The entry under way, counting down to its end" }
        }
        nm.createNotificationChannel(ch)
    }

    /**
     * The entry's emoji drawn as a status-bar icon. The system keeps only its
     * alpha, so it shows as a silhouette (☕ → a cup), like other Live Updates.
     */
    private fun emojiIcon(emoji: String): Icon? {
        if (emoji.isBlank()) return null
        val size = 96
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = size * 0.8f
            textAlign = Paint.Align.CENTER
            color = Color.WHITE
        }
        val fm = paint.fontMetrics
        val y = size / 2f - (fm.ascent + fm.descent) / 2f
        Canvas(bmp).drawText(emoji, size / 2f, y, paint)
        return Icon.createWithBitmap(bmp)
    }
}

/** Fires a countdown at its entry's start; re-arms after a reboot. */
class LiveCountdownReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> LiveCountdown.rearm(ctx)
            else -> intent.getStringExtra(LiveCountdown.EXTRA_JSON)?.let {
                LiveCountdown.show(ctx, JSONObject(it))
            }
        }
    }
}
