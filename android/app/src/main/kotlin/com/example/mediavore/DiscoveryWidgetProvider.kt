package com.example.mediavore

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import kotlin.random.Random

class DiscoveryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.discovery_widget_v2).apply {
                
                // Get pool size and pick a random index
                val poolSize = widgetData.getInt("discovery_pool_size", 0)
                val index = if (poolSize > 0) Random.nextInt(poolSize) else -1
                
                val suffix = if (index >= 0) "_$index" else ""

                val title = widgetData.getString("discovery_title$suffix", "Discover")
                val subtitle = widgetData.getString("discovery_subtitle$suffix", "Tap to explore")
                val imagePath = widgetData.getString("discovery_image$suffix", null)
                val mediaId = widgetData.getString("discovery_id$suffix", null)
                val rating = widgetData.getString("discovery_rating$suffix", "") ?: ""
                val year = widgetData.getString("discovery_year$suffix", "") ?: ""

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_subtitle, subtitle)
                
                if (rating.isNotEmpty()) {
                    setTextViewText(R.id.widget_rating, "★ $rating")
                    setViewVisibility(R.id.widget_rating, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_rating, View.GONE)
                }

                if (year.isNotEmpty()) {
                    setTextViewText(R.id.widget_year, year)
                    setViewVisibility(R.id.widget_year, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_year, View.GONE)
                }

                if (imagePath != null) {
                    val file = File(imagePath)
                    if (file.exists()) {
                        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                        setImageViewBitmap(R.id.widget_image, bitmap)
                    }
                }

                val uri = if (mediaId != null) {
                    Uri.parse("mediavore://details?id=$mediaId")
                } else {
                    Uri.parse("mediavore://discovery")
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    uri
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
