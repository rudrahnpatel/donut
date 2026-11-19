package dev.rudra.donut

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.content.FileProvider
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    private var liveChannel: MethodChannel? = null

    /** A Live Update button tapped (e.g. `late:5`) not yet taken by Dart. */
    private var pendingAction: String? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = intent.getStringExtra(LiveCountdown.EXTRA_ACTION) ?: return
        intent.removeExtra(LiveCountdown.EXTRA_ACTION)
        val ch = liveChannel
        if (ch != null) ch.invokeMethod("action", action) else pendingAction = action
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingAction = intent?.getStringExtra(LiveCountdown.EXTRA_ACTION)
        intent?.removeExtra(LiveCountdown.EXTRA_ACTION)
        // Android 16 Live Updates for the countdown (see LiveCountdown.kt).
        liveChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "donut/live")
            .apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "supported" -> result.success(LiveCountdown.supported())
                        "canPromote" -> result.success(LiveCountdown.canPromote(this@MainActivity))
                        "show" -> {
                            LiveCountdown.show(this@MainActivity, JSONObject(call.arguments as String))
                            result.success(null)
                        }
                        "schedule" -> {
                            LiveCountdown.schedule(this@MainActivity, JSONArray(call.arguments as String))
                            result.success(null)
                        }
                        "takeAction" -> {
                            result.success(pendingAction)
                            pendingAction = null
                        }
                        "openPromotionSettings" -> {
                            if (Build.VERSION.SDK_INT >= 36) {
                                startActivity(
                                    Intent(Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS)
                                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                )
                            }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "donut/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Once notifications have been refused twice Android stops
                    // asking, so the only way back is Donut's settings page.
                    "openNotificationSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                .setData(Uri.fromParts("package", packageName, null))
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    // In-app updates (see lib/features/update/).
                    "supportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                    "canInstallPackages" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                            packageManager.canRequestPackageInstalls()
                    )
                    "openInstallPermissionSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:$packageName"),
                                )
                            )
                        }
                        result.success(null)
                    }
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        val file = path?.let(::File)
                        if (file == null || !file.isFile) {
                            result.error("missing", "APK not found: $path", null)
                        } else {
                            // The system installer shows its confirm screen;
                            // a normal app can't install silently.
                            val uri = FileProvider.getUriForFile(
                                this, "$packageName.updates", file
                            )
                            startActivity(
                                Intent(Intent.ACTION_VIEW)
                                    .setDataAndType(uri, "application/vnd.android.package-archive")
                                    .addFlags(
                                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                            Intent.FLAG_ACTIVITY_NEW_TASK
                                    )
                            )
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
