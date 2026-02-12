package com.example.mediavore

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "mediavore/notifications"
	private val REQUEST_CODE_POST_NOTIFICATIONS = 1001

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				// Old names used in earlier native implementation
				"scheduleNotification", "schedule" -> {
					// support multiple possible argument keys from Dart
					val id = (call.argument<Number>("id") ?: call.argument<Number>("notificationId") ?: 0).toInt()
					val title = call.argument<String>("title") ?: call.argument<String>("bodyTitle")
					val body = call.argument<String>("body") ?: call.argument<String>("notificationBody")
					val timestamp = (call.argument<Number>("timestamp") ?: call.argument<Number>("timeEpochMillis") ?: 0).toLong()
					scheduleAlarm(id, title, body, timestamp)
					result.success(true)
				}
				"cancelNotification", "cancel" -> {
					val id = (call.argument<Number>("id") ?: call.argument<Number>("notificationId") ?: 0).toInt()
					cancelAlarm(id)
					result.success(true)
				}
				"requestPermission" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
						val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
						if (!granted) {
							ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE_POST_NOTIFICATIONS)
						}
						result.success(granted)
					} else {
						result.success(true)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun scheduleAlarm(id: Int, title: String?, body: String?, timestamp: Long) {
		val intent = Intent(this, AlarmReceiver::class.java).apply {
			putExtra("id", id)
			putExtra("title", title)
			putExtra("body", body)
		}
		val pending = PendingIntent.getBroadcast(this, id, intent,
			PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)

		val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
		try {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
				alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pending)
			} else {
				alarmManager.setExact(AlarmManager.RTC_WAKEUP, timestamp, pending)
			}
		} catch (se: SecurityException) {
			// On Android 12/13+ exact alarms may require special permission.
			// Try a non-exact alarm as a fallback before posting immediately.
			try {
				alarmManager.set(AlarmManager.RTC_WAKEUP, timestamp, pending)
				return
			} catch (ignored: Exception) {
				// fall through to immediate notification
			}
			// Fallback: post the notification immediately so the developer can test behavior.
			val channelId = "releases"
			val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
				val channel = android.app.NotificationChannel(channelId, "Releases", android.app.NotificationManager.IMPORTANCE_HIGH)
				channel.description = "Notifications for new releases and episodes"
				notificationManager.createNotificationChannel(channel)
			}
			val notification = androidx.core.app.NotificationCompat.Builder(this, channelId)
				.setContentTitle(title ?: "Release")
				.setContentText(body ?: "")
				.setSmallIcon(applicationInfo.icon)
				.setAutoCancel(true)
				.build()
			notificationManager.notify(id, notification)
		}
	}

	private fun cancelAlarm(id: Int) {
		val intent = Intent(this, AlarmReceiver::class.java)
		val pending = PendingIntent.getBroadcast(this, id, intent,
			PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
		val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
		alarmManager.cancel(pending)
		pending.cancel()
	}
}
