package dev.rudra.donut

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF

/**
 * Draws the home-screen widget's dial, like the app's:
 *
 * - [renderDay]: inner ring AM, outer ring PM.
 * - [renderHour]: inner ring this hour, outer ring the next (faded).
 *
 * Entries are coloured arcs and time already gone is dimmed. The hands are
 * not drawn here: an AnalogClock laid on top keeps them moving without
 * waking the app.
 */
object ClockBitmapRenderer {

    /** An entry as minutes from the start of today (tomorrow is 1440+). */
    data class Entry(val start: Int, val end: Int, val color: Int)

    private val INNER = 0.49f to 0.68f
    private val OUTER = 0.72f to 0.91f

    fun renderDay(entries: List<Entry>, size: Int, nowMinute: Int): Bitmap =
        render(size, origin = 0, turn = 720) { dial ->
            dial.numerals((0 until 12).map { h -> (if (h == 0) "12" else "$h") to h * 30.0 }, major = 3)
            for (e in entries) dial.span(e.start, e.end, e.color)
            dial.dimPast(nowMinute)
        }

    fun renderHour(entries: List<Entry>, size: Int, nowMinute: Int, use24h: Boolean): Bitmap {
        val origin = nowMinute / 60 * 60
        return render(size, origin = origin, turn = 60) { dial ->
            dial.numerals(listOf("00" to 0.0, "15" to 90.0, "30" to 180.0, "45" to 270.0), major = 1)
            dial.outerTag(hourLabel((origin / 60 + 1) % 24, use24h))
            for (e in entries) dial.span(e.start, e.end, e.color)
            dial.dimPast(nowMinute)
        }
    }

    private fun hourLabel(hour: Int, use24h: Boolean): String = when {
        use24h -> "%02d:00".format(hour)
        hour == 0 -> "12 AM"
        hour < 12 -> "$hour AM"
        hour == 12 -> "12 PM"
        else -> "${hour - 12} PM"
    }

    private fun render(size: Int, origin: Int, turn: Int, draw: (Dial) -> Unit): Bitmap {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val dial = Dial(Canvas(bitmap), size / 2f, origin, turn)
        dial.face()
        draw(dial)
        return bitmap
    }

    /** One dial: [turn] minutes per ring, the inner ring starting at [origin]. */
    private class Dial(val canvas: Canvas, val r: Float, val origin: Int, val turn: Int) {
        val c = r

        fun face() {
            val background = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(235, 17, 17, 21) }
            canvas.drawCircle(c, c, r, background)
            val track = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                color = Color.rgb(44, 43, 50)
            }
            for ((r0, r1) in listOf(INNER, OUTER)) {
                track.strokeWidth = (r1 - r0) * r
                canvas.drawCircle(c, c, (r0 + r1) / 2 * r, track)
            }
        }

        /** Labels at clock angles (degrees from 12); every [major]th is bolder. */
        fun numerals(labels: List<Pair<String, Double>>, major: Int) {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }
            for ((i, pair) in labels.withIndex()) {
                val (label, angle) = pair
                val big = i % major == 0
                paint.textSize = r * (if (labels.size > 4) (if (big) 0.1f else 0.075f) else 0.1f)
                paint.isFakeBoldText = big
                paint.color = if (big) Color.argb(220, 236, 232, 242) else Color.argb(150, 220, 215, 228)
                val a = Math.toRadians(angle)
                val x = c + (Math.sin(a) * r * 0.36).toFloat()
                val y = c - (Math.cos(a) * r * 0.36).toFloat() - (paint.ascent() + paint.descent()) / 2
                canvas.drawText(label, x, y, paint)
            }
        }

        /** A small tag naming the outer ring's hour, just before the seam. */
        fun outerTag(text: String) {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.argb(190, 220, 215, 228)
                textSize = r * 0.06f
                isFakeBoldText = true
                textAlign = Paint.Align.RIGHT
            }
            val mid = (OUTER.first + OUTER.second) / 2 * r
            canvas.drawText(text, c - r * 0.03f, c - mid - (paint.ascent() + paint.descent()) / 2, paint)
        }

        private fun arc(start: Float, end: Float, band: Pair<Float, Float>, paint: Paint) {
            if (end <= start) return
            val (r0, r1) = band
            val mid = (r0 + r1) / 2 * r
            paint.strokeWidth = (r1 - r0) * r - 6f
            val oval = RectF(c - mid, c - mid, c + mid, c + mid)
            // Canvas angles start at 3 o'clock; the dial starts at 12.
            val from = ((start % turn) + turn) % turn / turn * 360f - 90f
            val sweep = (end - start) / turn * 360f
            canvas.drawArc(oval, from + 0.6f, (sweep - 1.2f).coerceAtLeast(0.5f), false, paint)
        }

        /** [start, end) on whichever rings it touches; the hour view's outer
         *  ring (the next hour) is drawn at half strength, like the app. */
        fun span(start: Int, end: Int, color: Int) {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeCap = Paint.Cap.BUTT
            }
            val split = origin + turn
            val stop = origin + 2 * turn
            paint.color = color
            arc(maxOf(start, origin).toFloat(), minOf(end, split).toFloat(), INNER, paint)
            if (turn == 60) paint.alpha = paint.alpha / 2
            arc(maxOf(start, split).toFloat(), minOf(end, stop).toFloat(), OUTER, paint)
        }

        /** Dims the time already gone, up to [nowMinute]. */
        fun dimPast(nowMinute: Int) {
            val past = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                color = Color.argb(115, 17, 17, 21)
            }
            val split = origin + turn
            arc(origin.toFloat(), minOf(nowMinute, split).toFloat(), INNER, past)
            arc(split.toFloat(), nowMinute.toFloat(), OUTER, past)
        }
    }
}
