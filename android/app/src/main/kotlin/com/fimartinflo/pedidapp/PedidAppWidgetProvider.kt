package com.fimartinflo.pedidapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PedidAppWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val lowStockCount = widgetData.getInt("low_stock_count", 0)
        val expiringCount = widgetData.getInt("expiring_count", 0)
        val totalProducts = widgetData.getInt("total_products", 0)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pedidapp_widget).apply {
                setTextViewText(R.id.widget_low_stock_count, lowStockCount.toString())
                setTextViewText(R.id.widget_expiring_count, expiringCount.toString())
                setTextViewText(R.id.widget_total_products, totalProducts.toString())

                // Open app when widget is tapped
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (intent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
