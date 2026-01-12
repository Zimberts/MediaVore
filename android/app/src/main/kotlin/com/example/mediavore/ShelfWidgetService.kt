package com.example.mediavore

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class ShelfWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ShelfRemoteViewsFactory(this.applicationContext, intent)
    }
}

class ShelfRemoteViewsFactory(private val context: Context, private val intent: Intent) : RemoteViewsService.RemoteViewsFactory {
    private var items: List<JSONObject> = listOf()
    private var displayMode: Int = 0
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate() {
        appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
    }

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        
        // 1. Find out which list this specific widget instance is supposed to show
        val listName = prefs.getString("shelf_list_name_$appWidgetId", "watchlist") ?: "watchlist"
        displayMode = prefs.getInt("shelf_display_mode_$appWidgetId", 0)
        
        // 2. Load the data for THAT specific list
        // Note: MainPage.dart now saves data as 'shelf_data_watchlist', 'shelf_data_liked', etc.
        val jsonStr = prefs.getString("shelf_data_$listName", "[]")
        
        try {
            val jsonArray = JSONArray(jsonStr)
            val newList = mutableListOf<JSONObject>()
            for (i in 0 until jsonArray.length()) {
                newList.add(jsonArray.getJSONObject(i))
            }
            items = newList
        } catch (e: Exception) {
            items = listOf()
        }
    }

    override fun onDestroy() {
        items = listOf()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position < 0 || position >= items.size) {
            return RemoteViews(context.packageName, R.layout.shelf_item)
        }
        
        val item = items[position]
        val layoutId = if (displayMode == 1) R.layout.shelf_item_grid else R.layout.shelf_item
        val views = RemoteViews(context.packageName, layoutId)

        val title = item.optString("title", "Unknown")
        val subtitle = item.optString("subtitle", "")
        val type = item.optString("type", "movie")
        val imagePath = item.optString("image_path", "")
        val mediaId = item.optString("id", "")

        views.setTextViewText(R.id.item_title, title)
        
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val textColor = prefs.getString("theme_text_primary", "#FFFFFF") ?: "#FFFFFF"
        try {
            views.setTextColor(R.id.item_title, Color.parseColor(textColor))
        } catch (e: Exception) {}

        if (displayMode != 1) {
            views.setTextViewText(R.id.item_subtitle, subtitle)
            val iconRes = if (type == "tv" || type == "TV Show") android.R.drawable.ic_menu_slideshow else android.R.drawable.ic_menu_gallery
            views.setImageViewResource(R.id.item_type_icon, iconRes)
        }

        if (imagePath.isNotEmpty()) {
            val file = File(imagePath)
            if (file.exists()) {
                val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.item_poster, bitmap)
                }
            }
        }

        val fillInIntent = Intent().apply {
            data = android.net.Uri.parse("mediavore://details?id=$mediaId&type=${if(type.contains("tv", true)) "tv" else "movie"}")
        }
        views.setOnClickFillInIntent(R.id.shelf_item_container, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 2
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
