package com.notisim.noti_sim

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val miuiChannel = "noti_sim/miui"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, miuiChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdkVersion" -> {
                        result.success(Build.VERSION.SDK_INT)
                    }
                    "getTimezone" -> {
                        result.success(java.util.TimeZone.getDefault().id)
                    }
                    // Non-intrusive STATUS check: does NOT open settings.
                    // This is the source of truth for whether exact alarms will
                    // actually fire (vs. being silently downgraded to inexact).
                    "canScheduleExactAlarms" -> {
                        val canSchedule = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            am.canScheduleExactAlarms()
                        } else {
                            true // granted by default before Android 12
                        }
                        result.success(canSchedule)
                    }
                    // Opens the system "Alarms & reminders" screen for this app.
                    "openExactAlarmSettings" -> {
                        val opened = tryOpenExactAlarmSettings()
                        result.success(opened)
                    }
                    // Is the app whitelisted from battery optimization?
                    "isIgnoringBatteryOptimizations" -> {
                        val ignoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                            pm.isIgnoringBatteryOptimizations(packageName)
                        } else {
                            true
                        }
                        result.success(ignoring)
                    }
                    "isMiui" -> {
                        val manufacturer = Build.MANUFACTURER.lowercase()
                        val fingerprint = Build.FINGERPRINT.lowercase()
                        val isMiui = manufacturer.contains("xiaomi") ||
                            manufacturer.contains("redmi") ||
                            manufacturer.contains("poco") ||
                            fingerprint.contains("miui") ||
                            fingerprint.contains("hyperos")
                        result.success(isMiui)
                    }
                    "openIntent" -> {
                        val action = call.argument<String>("action")
                        val pkg = call.argument<String>("package")
                        val opened = tryOpenIntent(action, pkg)
                        result.success(opened)
                    }
                    "openBatteryOptimization" -> {
                        val opened = tryOpenBatteryOptimization()
                        result.success(opened)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Opens the per-app "Alarms & reminders" settings screen (Android 12+).
    private fun tryOpenExactAlarmSettings(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    // Attempts to launch an intent; returns true if it resolved.
    private fun tryOpenIntent(action: String?, pkg: String?): Boolean {
        return try {
            val intent = Intent(action ?: return false).apply {
                if (pkg != null) setPackage(pkg)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // Opens battery optimization settings for this app.
    private fun tryOpenBatteryOptimization(): Boolean {
        return try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
            } else {
                Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
            }
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            true
        } catch (e: Exception) {
            // Fallback: open generic battery settings
            try {
                val fallback = Intent(Settings.ACTION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallback)
                true
            } catch (e2: Exception) {
                false
            }
        }
    }
}
