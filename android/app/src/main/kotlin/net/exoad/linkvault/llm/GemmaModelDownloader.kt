package net.exoad.linkvault.llm

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

class GemmaModelDownloader(private val context: Context) {
    private val cancelFlag = AtomicBoolean(false)

    fun cancel() {
        cancelFlag.set(true)
    }

    fun modelsDir(): File {
        val dir = File(context.filesDir, "models")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    fun modelFile(fileName: String): File = File(modelsDir(), fileName)

    fun isInstalled(fileName: String): Boolean {
        val file = modelFile(fileName)
        return file.exists() && file.length() > 0L
    }

    fun uninstall(fileName: String) {
        modelFile(fileName).delete()
        File(modelsDir(), "$fileName.part").delete()
    }

    fun download(
        url: String,
        fileName: String,
        bearerToken: String?,
        onProgress: (Int) -> Unit,
    ) {
        cancelFlag.set(false)
        val dest = modelFile(fileName)
        val temp = File(modelsDir(), "$fileName.part")
        if (temp.exists()) temp.delete()

        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 60_000
            readTimeout = 120_000
            if (!bearerToken.isNullOrBlank()) {
                setRequestProperty("Authorization", "Bearer $bearerToken")
            }
        }

        try {
            connection.connect()
            val code = connection.responseCode
            if (code !in 200..299) {
                val err = connection.errorStream?.bufferedReader()?.readText()
                throw IllegalStateException("Download failed HTTP $code: $err")
            }

            val total = connection.contentLengthLong.coerceAtLeast(0L)
            connection.inputStream.use { input ->
                FileOutputStream(temp).use { output ->
                    val buffer = ByteArray(1024 * 256)
                    var downloaded = 0L
                    var lastPercent = -1
                    while (true) {
                        if (cancelFlag.get()) {
                            throw InterruptedException("Download cancelled")
                        }
                        val read = input.read(buffer)
                        if (read <= 0) break
                        output.write(buffer, 0, read)
                        downloaded += read
                        if (total > 0) {
                            val percent = ((downloaded * 100) / total).toInt().coerceIn(0, 100)
                            if (percent != lastPercent) {
                                lastPercent = percent
                                onProgress(percent)
                            }
                        }
                    }
                }
            }
            if (dest.exists()) dest.delete()
            if (!temp.renameTo(dest)) {
                temp.copyTo(dest, overwrite = true)
                temp.delete()
            }
            onProgress(100)
            Log.i(TAG, "Downloaded model to ${dest.absolutePath} (${dest.length()} bytes)")
        } finally {
            connection.disconnect()
            if (!dest.exists() && temp.exists()) temp.delete()
        }
    }

    companion object {
        private const val TAG = "GemmaModelDownloader"
    }
}
