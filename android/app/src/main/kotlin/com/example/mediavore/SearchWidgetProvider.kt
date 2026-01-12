package com.example.mediavore

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SearchWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.search_widget).apply {
                // Open app to search
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mediavore://search")
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Open app to scan (if we want to differentiate)
                val scanIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("mediavore://scan")
                )
                setOnClickPendingIntent(R.id.btn_scan, scanIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
