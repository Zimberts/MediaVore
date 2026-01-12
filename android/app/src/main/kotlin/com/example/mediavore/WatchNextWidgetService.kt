package com.example.mediavore

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.URLEncoder

class WatchNextWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return WatchNextRemoteViewsFactory(this.applicationContext)
    }
}

class WatchNextRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var items: List<JSONObject> = listOf()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("watch_next_data", "[]")
        val jsonArray = JSONArray(jsonStr)
        val newList = mutableListOf<JSONObject>()
        for (i in 0 until jsonArray.length()) {
            newList.add(jsonArray.getJSONObject(i))
        }
        items = newList
    }

    override fun onDestroy() {}

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= items.size) return RemoteViews(context.packageName, R.layout.watch_next_item)
        
        val item = items[position]
        val views = RemoteViews(context.packageName, R.layout.watch_next_item)

        val title = item.optString("title", "Unknown")
        val episodeLabel = item.optString("episode_label", "")
        val imagePath = item.optString("image_path", "")
        val mediaId = item.optString("id", "")
        val season = item.optInt("season", -1)
        val episode = item.optInt("episode", -1)

        views.setTextViewText(R.id.item_title, title)
        views.setTextViewText(R.id.item_episode, episodeLabel)

        if (imagePath.isNotEmpty()) {
            val file = File(imagePath)
            if (file.exists()) {
                val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                views.setImageViewBitmap(R.id.item_poster, bitmap)
            }
        }

        // Tapping the row opens details
        val detailIntent = Intent().apply {
            data = android.net.Uri.parse("mediavore://details?id=$mediaId&type=tv")
        }
        views.setOnClickFillInIntent(R.id.item_content, detailIntent)

        // Tapping DONE marks as seen - Now includes title 't' for immediate processing
        val checkIntent = Intent().apply {
            val encodedTitle = try { URLEncoder.encode(title, "UTF-8") } catch (e: Exception) { "Show" }
            data = android.net.Uri.parse("mediavore://markSeen?id=$mediaId&s=$season&e=$episode&t=$encodedTitle")
        }
        views.setOnClickFillInIntent(R.id.btn_check, checkIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
