package net.exoad.linkvault

import android.animation.ObjectAnimator
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.os.Bundle
import android.view.View
import android.view.animation.AnticipateInterpolator
import androidx.core.animation.doOnEnd
import androidx.core.content.FileProvider
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "net.exoad.linkvault/install",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canInstallPackages" -> {
                    result.success(canInstallPackages())
                }
                "openInstallPermissionSettings" -> {
                    try {
                        openInstallPermissionSettings()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("settings_failed", e.message, null)
                    }
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("invalid_path", "APK path required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        installApk(path)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("install_failed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    private fun installApk(path: String) {
        if (!canInstallPackages()) {
            openInstallPermissionSettings()
            throw IllegalStateException(
                "Allow installs from this app, then try again.",
            )
        }
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("APK not found: $path")
        }
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        
        super.onCreate(savedInstanceState)
        
        // Premium exit animation for the splash screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                val slideUp = ObjectAnimator.ofFloat(
                    splashScreenView.iconView,
                    View.TRANSLATION_Y,
                    0f,
                    -splashScreenView.iconView.height.toFloat() * 2
                )
                slideUp.interpolator = AnticipateInterpolator()
                slideUp.duration = 500L

                val fadeOut = ObjectAnimator.ofFloat(
                    splashScreenView.view,
                    View.ALPHA,
                    1f,
                    0f
                )
                fadeOut.duration = 300L
                fadeOut.startDelay = 200L

                slideUp.doOnEnd { splashScreenView.remove() }
                
                slideUp.start()
                fadeOut.start()
            }
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
