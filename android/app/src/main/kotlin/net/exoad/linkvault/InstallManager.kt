package net.exoad.linkvault

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import java.security.MessageDigest

/**
 * Android package-install and signing operations.
 *
 * Backs [InstallHostApi]; extracted from MainActivity so the native install
 * flow is isolated and unit-friendly. Throws [FlutterError] with code
 * `SIGNING_MISMATCH` so Flutter can distinguish key mismatches by code.
 */
class InstallManager(private val activity: Activity) : InstallHostApi {

    override fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    override fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:${activity.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
        }
    }

    override fun checkApkSigning(path: String): ApkSigningResult {
        val file = File(path)
        if (!file.exists()) {
            throw FlutterError("invalid_path", "APK not found: $path", null)
        }
        val installed = installedAppCertSha256()
        val apk = apkCertSha256(path)
        val compatible = installed != null && apk != null && installed == apk
        return ApkSigningResult(
            compatible = compatible,
            installedCertSha256 = installed,
            apkCertSha256 = apk,
        )
    }

    override fun installApk(path: String) {
        if (!canInstallPackages()) {
            openInstallPermissionSettings()
            throw FlutterError(
                "install_blocked",
                "Allow installs from this app, then try again.",
                null,
            )
        }
        val check = checkApkSigning(path)
        if (!check.compatible) {
            throw FlutterError(
                "SIGNING_MISMATCH",
                "This update was signed with a different key than the app on " +
                    "this device. Uninstall Linkvault and install the new APK " +
                    "from GitHub Releases (local data will be removed).",
                null,
            )
        }
        val file = File(path)
        if (!file.exists()) {
            throw FlutterError("invalid_path", "APK not found: $path", null)
        }
        val uri: Uri = FileProvider.getUriForFile(
            activity,
            "${activity.applicationContext.packageName}.fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(intent)
    }

    private fun installedAppCertSha256(): String? {
        val flags = signingFlags()
        @Suppress("DEPRECATION")
        val info = activity.packageManager.getPackageInfo(activity.packageName, flags)
        return certSha256FromPackageInfo(info)
    }

    private fun apkCertSha256(apkPath: String): String? {
        val flags = signingFlags()
        @Suppress("DEPRECATION")
        val info = activity.packageManager.getPackageArchiveInfo(apkPath, flags)
            ?: return null
        info.applicationInfo?.let { appInfo ->
            appInfo.sourceDir = apkPath
            appInfo.publicSourceDir = apkPath
        }
        return certSha256FromPackageInfo(info)
    }

    private fun signingFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }
    }

    private fun certSha256FromPackageInfo(info: PackageInfo): String? {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            info.signatures
        } ?: return null
        if (signatures.isEmpty()) return null
        val digest = MessageDigest.getInstance("SHA-256")
        digest.update(signatures[0].toByteArray())
        return SigningHex.toHex(digest.digest())
    }
}

/** Hex helper kept separate so it can be unit tested without Android. */
object SigningHex {
    fun toHex(bytes: ByteArray): String =
        bytes.joinToString("") { byte -> "%02x".format(byte) }
}
