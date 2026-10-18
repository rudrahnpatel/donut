package dev.rudra.donut

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF

/**
 * Draws today's day dial for the home-screen widget: inner ring AM, outer
 * ring PM, entries as coloured arcs, the part of the day already gone
 * dimmed. The hour hand is not drawn here: an AnalogClock laid on top keeps
 * it moving without waking the app.
 */
object ClockBitmapRenderer {

    /** An entry as minutes of the day, already clipped to [0, 1440]. */
    data class Entry(val start: Int, val end: Int, val color: Int)

    private const val HALF_DAY = 720f

    fun render(entries: List<Entry>, size: Int, nowMinute: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val c = size / 2f
        val r = size / 2f

        val background = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(235, 17, 17, 21) }
        canvas.drawCircle(c, c, r, background)

        // Same proportions as the app's day dial.
        val inner = 0.49f to 0.68f
        val outer = 0.72f to 0.91f
        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.rgb(44, 43, 50)
        }
        for ((r0, r1) in listOf(inner, outer)) {
            track.strokeWidth = (r1 - r0) * r
            canvas.drawCircle(c, c, (r0 + r1) / 2 * r, track)
        }

        // Hour numerals at the quarters, small and quiet.
        val numerals = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(170, 230, 225, 235)
            textSize = r * 0.11f
            textAlign = Paint.Align.CENTER
            isFakeBoldText = true
        }
        for ((label, angle) in listOf("12" to 0.0, "3" to 90.0, "6" to 180.0, "9" to 270.0)) {
            val a = Math.toRadians(angle)
            val x = c + (Math.sin(a) * r * 0.35).toFloat()
            val y = c - (Math.cos(a) * r * 0.35).toFloat() - (numerals.ascent() + numerals.descent()) / 2
            canvas.drawText(label, x, y, numerals)
        }

        val arc = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.BUTT
        }
        fun ring(start: Float, end: Float, band: Pair<Float, Float>, paint: Paint) {
            if (end <= start) return
            val (r0, r1) = band
            val mid = (r0 + r1) / 2 * r
            paint.strokeWidth = (r1 - r0) * r - 6f
            val oval = RectF(c - mid, c - mid, c + mid, c + mid)
            // Canvas angles start at 3 o'clock; the dial starts at 12.
            val from = start % HALF_DAY / HALF_DAY * 360f - 90f
            val sweep = (end - start) / HALF_DAY * 360f
            canvas.drawArc(oval, from + 0.6f, (sweep - 1.2f).coerceAtLeast(0.5f), false, paint)
        }
        fun paintSpan(start: Float, end: Float, paint: Paint) {
            ring(start, minOf(end, HALF_DAY), inner, paint)
            ring(maxOf(start, HALF_DAY), end, outer, paint)
        }

        for (e in entries) {
            arc.color = e.color
            paintSpan(e.start.toFloat(), e.end.toFloat(), arc)
        }

        // Dim what is already past.
        val past = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.argb(115, 17, 17, 21)
        }
        paintSpan(0f, nowMinute.toFloat(), past)
        return bitmap
    }
}
