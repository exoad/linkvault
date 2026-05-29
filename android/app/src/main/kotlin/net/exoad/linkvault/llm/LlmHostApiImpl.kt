package net.exoad.linkvault.llm

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import net.exoad.linkvault.FlutterLlmApi
import net.exoad.linkvault.LlmBackend
import net.exoad.linkvault.LlmContextStats
import net.exoad.linkvault.LlmGenerationConfig
import net.exoad.linkvault.LlmHistoryMessage
import net.exoad.linkvault.LlmHostApi
import net.exoad.linkvault.llm.toCompute

class LlmHostApiImpl(
    context: Context,
    private val flutterLlmApi: FlutterLlmApi,
) : LlmHostApi, GemmaLlmController.LlmFlutterCallbacks {
    private val controller = GemmaLlmController(context)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    init {
        controller.flutterCallbacks = this
    }

    override fun isModelInstalled(fileName: String): Boolean =
        controller.isModelInstalled(fileName)

    override fun startModelDownload(url: String, fileName: String, bearerToken: String?) {
        controller.startDownload(url, fileName, bearerToken)
    }

    override fun cancelModelDownload() {
        controller.cancelDownload()
    }

    override fun uninstallModel(fileName: String) {
        controller.uninstall(fileName)
    }

    override fun loadModel(
        fileName: String,
        backend: LlmBackend,
        maxTokens: Long,
        callback: (Result<Unit>) -> Unit,
    ) {
        scope.launch(Dispatchers.IO) {
            try {
                controller.loadModel(fileName, backend.toCompute(), maxTokens.toInt())
                withContext(Dispatchers.Main) { callback(Result.success(Unit)) }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun unloadModel() {
        controller.unload()
    }

    override fun resetConversation() {
        controller.resetConversation()
    }

    override fun replayHistory(messages: List<LlmHistoryMessage>) {
        controller.replayHistory(messages)
    }

    override fun sendUserMessage(text: String) {
        controller.sendUserMessage(text)
    }

    override fun sendToolResult(toolName: String, resultJson: String) {
        controller.sendToolResult(toolName, resultJson)
    }

    override fun startGeneration() {
        controller.startGeneration()
    }

    override fun stopGeneration() {
        controller.stopGeneration()
    }

    override fun getActiveBackendLabel(): String? = controller.getActiveBackendLabel()

    override fun applyGenerationConfig(config: LlmGenerationConfig) {
        controller.applyGenerationConfig(config)
    }

    override fun getContextStats(): LlmContextStats {
        val (used, max) = controller.getContextStats()
        return LlmContextStats(used.toLong(), max.toLong())
    }

    override fun onDownloadProgress(percent: Int) {
        flutterLlmApi.onDownloadProgress(percent.toLong()) { }
    }

    override fun onToken(token: String) {
        flutterLlmApi.onToken(token) { }
    }

    override fun onGenerationComplete(fullText: String) {
        flutterLlmApi.onGenerationComplete(fullText) { }
    }

    override fun onFunctionCall(name: String, argsJson: String) {
        flutterLlmApi.onFunctionCall(name, argsJson) { }
    }

    override fun onError(code: String, message: String) {
        flutterLlmApi.onLlmError(code, message) { }
    }

    fun dispose() {
        controller.dispose()
    }
}
