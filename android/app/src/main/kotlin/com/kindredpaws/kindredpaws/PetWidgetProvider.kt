package com.kindredpaws.kindredpaws

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Companion Presence home widget (P2-6). Reads the single shared
 * [PetStatusSnapshot] the Flutter app writes to SharedPreferences (key
 * `flutter.kindredpaws.widget.snapshot`, written by PrefsHomeWidgetService) and
 * renders the pet name + a warm, never-guilt status line. Ambient surface; the
 * OS budgets refreshes. Tapping is wired to launch the app in a fast-follow.
 */
class PetWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE,
        )
        val json = prefs.getString("flutter.kindredpaws.widget.snapshot", null)

        var name = "Your pet"
        var status = "Tap to open KindredPaws 🐾"
        if (json != null) {
            try {
                val o = JSONObject(json)
                name = o.optString("name", name)
                status = statusLine(name, o.optString("mood", "content"))
            } catch (_: Exception) {
                // Fall back to the warm default; the widget never errors.
            }
        }

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pet_widget)
            views.setTextViewText(R.id.pet_widget_name, name)
            views.setTextViewText(R.id.pet_widget_status, status)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    /** Warm, never-guilt status copy (Risk R6). */
    private fun statusLine(name: String, mood: String): String = when (mood) {
        "joyful" -> "$name is over the moon! ✨"
        "content" -> "$name is happy and cozy 🐾"
        "wistful" -> "$name is thinking of you 💛"
        else -> "$name would love a little care 🤍"
    }
}
