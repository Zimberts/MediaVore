package com.example.mediavore

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ShelfWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val mode = widgetData.getInt("shelf_display_mode_$appWidgetId", 0)
            val cols = widgetData.getInt("shelf_grid_columns_$appWidgetId", 3)
            val listName = widgetData.getString("shelf_list_name_$appWidgetId", "watchlist") ?: "watchlist"
            
            val bgColor = widgetData.getString("theme_primary_bg", "#121212") ?: "#121212"
            val textColor = widgetData.getString("theme_text_primary", "#FFFFFF") ?: "#FFFFFF"

            val views = RemoteViews(context.packageName, R.layout.shelf_widget).apply {
                setTextViewText(R.id.shelf_title, listName.replaceFirstChar { it.uppercase() })
                
                try {
                    setInt(R.id.widget_root, "setBackgroundColor", Color.parseColor(bgColor))
                    setTextColor(R.id.shelf_title, Color.parseColor(textColor))
                    setInt(R.id.shelf_refresh_icon, "setColorFilter", Color.parseColor(textColor))
                } catch (e: Exception) {}

                // Hide all potential collection views first
                setViewVisibility(R.id.shelf_list, View.GONE)
                setViewVisibility(R.id.shelf_grid_2, View.GONE)
                setViewVisibility(R.id.shelf_grid_3, View.GONE)
                setViewVisibility(R.id.shelf_grid_4, View.GONE)
                setViewVisibility(R.id.shelf_grid_5, View.GONE)
                setViewVisibility(R.id.shelf_stack, View.GONE)

                val targetViewId = if (mode == 1) {
                    when (cols) {
                        2 -> R.id.shelf_grid_2
                        4 -> R.id.shelf_grid_4
                        5 -> R.id.shelf_grid_5
                        else -> R.id.shelf_grid_3
                    }
                } else {
                    R.id.shelf_list
                }

                setViewVisibility(targetViewId, View.VISIBLE)

                val intent = Intent(context, ShelfWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse("mediavore://shelf/$appWidgetId/$mode/$cols/${System.currentTimeMillis()}")
                }
                setRemoteAdapter(targetViewId, intent)
                setEmptyView(targetViewId, R.id.shelf_empty)

                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    appWidgetId, 
                    Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_VIEW
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }, 
                    flags
                )
                setPendingIntentTemplate(targetViewId, pendingIntent)
                
                // Refresh button
                val refreshIntent = Intent(context, ShelfWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
                }
                val refreshPendingIntent = PendingIntent.getBroadcast(
                    context, appWidgetId, refreshIntent, 
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
                )
                setOnClickPendingIntent(R.id.shelf_refresh, refreshPendingIntent)
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
            
            // Notify all possible grid views and list view to be safe
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.shelf_list)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.shelf_grid_2)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.shelf_grid_3)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.shelf_grid_4)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.shelf_grid_5)
        }
    }
}
