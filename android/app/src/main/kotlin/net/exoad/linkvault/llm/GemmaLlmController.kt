package net.exoad.linkvault.llm

import android.content.Context
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import net.exoad.linkvault.LlmGenerationConfig
import net.exoad.linkvault.LlmHistoryMessage
import net.exoad.linkvault.LlmHistoryRole
import net.exoad.linkvault.llm.litertlm.LiteRtLmEngine
import net.exoad.linkvault.llm.mediapipe.MediaPipeEngine

/**
 * Owns native inference lifecycle (engine, session, streaming, tool-call detection).
 */
class GemmaLlmController(
    context: Context,
) {
    private val appContext = context.applicationContext
    private val downloader = GemmaModelDownloader(appContext)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private var engine: InferenceEngine? = null
    private var session: InferenceSession? = null
    private var engineType: EngineType? = null
    private var activeBackend: LlmComputeBackend? = null
    private var loadedFileName: String? = null
    private var engineMaxTokens: Int = DEFAULT_MAX_OUTPUT

    private var streamJob: Job? = null
    private val generationBuffer = StringBuilder()
    private val functionBuffer = StringBuilder()
    private var inFunctionCapture = false

    private var sessionConfig: SessionConfig = defaultSessionConfig()
    private var contextTokenLimit: Int = DEFAULT_CONTEXT_LIMIT
    private var historyCharEstimate: Int = 0
    private var cachedHistory: List<LlmHistoryMessage> = emptyList()

    var flutterCallbacks: LlmFlutterCallbacks? = null

    interface LlmFlutterCallbacks {
        fun onDownloadProgress(percent: Int)
        fun onToken(token: String)
        fun onGenerationComplete(fullText: String)
        fun onFunctionCall(name: String, argsJson: String)
        fun onError(code: String, message: String)
    }

    fun isModelInstalled(fileName: String): Boolean = downloader.isInstalled(fileName)

    fun startDownload(
        url: String,
        fileName: String,
        bearerToken: String?,
    ) {
        scope.launch(Dispatchers.IO) {
            try {
                downloader.download(url, fileName, bearerToken) { percent ->
                    scope.launch(Dispatchers.Main) {
                        flutterCallbacks?.onDownloadProgress(percent)
                    }
                }
            } catch (e: InterruptedException) {
                flutterCallbacks?.onError("CANCELLED", e.message ?: "cancelled")
            } catch (e: Exception) {
                Log.e(TAG, "download failed", e)
                flutterCallbacks?.onError("DOWNLOAD_FAILED", e.message ?: "download failed")
            }
        }
    }

    fun cancelDownload() {
        downloader.cancel()
    }

    fun uninstall(fileName: String) {
        unload()
        downloader.uninstall(fileName)
    }

    suspend fun loadModel(
        fileName: String,
        backend: LlmComputeBackend,
        maxTokens: Int,
    ) = withContext(Dispatchers.IO) {
        unloadInternal()
        engineMaxTokens = maxTokens.coerceIn(64, 4096)
        val path = downloader.modelFile(fileName).absolutePath
        val type = EngineFactory.detectEngineType(path)
        val newEngine: InferenceEngine = when (type) {
            EngineType.MEDIAPIPE -> MediaPipeEngine(appContext)
            EngineType.LITERTLM -> LiteRtLmEngine(appContext)
        }
        val config = EngineConfig(
            modelPath = path,
            maxTokens = engineMaxTokens,
            preferredBackend = backend,
            maxNumImages = if (type == EngineType.LITERTLM) 1 else null,
            supportAudio = if (type == EngineType.LITERTLM) true else null,
        )
        newEngine.initialize(config)
        engine = newEngine
        engineType = type
        activeBackend = backend
        loadedFileName = fileName
        resetConversation()
    }

    fun applyGenerationConfig(config: LlmGenerationConfig) {
        sessionConfig = SessionConfig(
            temperature = config.temperature.toFloat().coerceIn(0.1f, 2.0f),
            randomSeed = 1,
            topK = config.topK.toInt().coerceIn(1, 128),
            topP = config.topP.toFloat().coerceIn(0.05f, 1.0f),
            enableVisionModality = if (engineType == EngineType.LITERTLM) false else null,
        )
        engineMaxTokens = config.maxOutputTokens.toInt().coerceIn(64, 4096)
        contextTokenLimit = config.contextTokenLimit.toInt().coerceIn(1024, 32768)
        if (cachedHistory.isNotEmpty()) {
            replayHistory(cachedHistory)
        } else {
            resetConversation()
        }
    }

    fun getContextStats(): Pair<Int, Int> {
        val pending = generationBuffer.length + functionBuffer.length
        val used = estimateTokens(historyCharEstimate + pending)
        return used to contextTokenLimit
    }

    fun unload() {
        scope.launch(Dispatchers.IO) {
            unloadInternal()
        }
    }

    private fun unloadInternal() {
        stopGeneration()
        session?.close()
        session = null
        engine?.close()
        engine = null
        engineType = null
        activeBackend = null
        loadedFileName = null
        cachedHistory = emptyList()
        historyCharEstimate = 0
    }

    fun resetConversation() {
        stopGeneration()
        session?.close()
        session = null
        val eng = engine ?: return
        session = eng.createSession(
            sessionConfig.copy(
                enableVisionModality = if (engineType == EngineType.LITERTLM) false else null,
            ),
        )
        generationBuffer.clear()
        functionBuffer.clear()
        inFunctionCapture = false
        historyCharEstimate = 0
    }

    fun replayHistory(messages: List<LlmHistoryMessage>) {
        cachedHistory = messages
        resetConversation()
        val current = session ?: return
        for (message in messages) {
            val chunk = historyChunk(message)
            historyCharEstimate += chunk.length
            current.addQueryChunk(chunk)
        }
    }

    fun sendUserMessage(text: String) {
        val chunk = formatTurn("user", text)
        historyCharEstimate += chunk.length
        session?.addQueryChunk(chunk)
    }

    fun sendToolResult(toolName: String, resultJson: String) {
        val chunk = formatToolResult(toolName, resultJson)
        historyCharEstimate += chunk.length
        session?.addQueryChunk(chunk)
    }

    fun startGeneration() {
        val eng = engine ?: run {
            flutterCallbacks?.onError("NOT_LOADED", "Model not loaded")
            return
        }
        val sess = session ?: run {
            flutterCallbacks?.onError("NO_SESSION", "No active session")
            return
        }
        stopGeneration()
        generationBuffer.clear()
        functionBuffer.clear()
        inFunctionCapture = false

        streamJob = eng.partialResults.onEach { (token, done) ->
            if (token.isNotEmpty()) {
                handleStreamToken(token)
            }
            if (done) {
                finishGeneration()
            }
        }.launchIn(scope)

        scope.launch(Dispatchers.IO) {
            try {
                sess.generateResponseAsync()
            } catch (e: Exception) {
                Log.e(TAG, "generation failed", e)
                scope.launch(Dispatchers.Main) {
                    flutterCallbacks?.onError("GENERATION_FAILED", e.message ?: "generation failed")
                }
            }
        }
    }

    fun stopGeneration() {
        streamJob?.cancel()
        streamJob = null
        session?.cancelGeneration()
    }

    fun getActiveBackendLabel(): String? {
        val backend = activeBackend ?: return null
        return when (backend) {
            LlmComputeBackend.GPU -> "Using GPU"
            LlmComputeBackend.CPU -> "Using CPU"
        }
    }

    fun dispose() {
        scope.launch(Dispatchers.IO) { unloadInternal() }
        scope.cancel()
    }

    private fun handleStreamToken(token: String) {
        if (inFunctionCapture || GemmaFunctionCallParser.isLikelyFunctionStart(token)) {
            inFunctionCapture = true
            functionBuffer.append(token)
            val call = GemmaFunctionCallParser.tryParse(functionBuffer.toString())
            if (call != null) {
                inFunctionCapture = false
                functionBuffer.clear()
                flutterCallbacks?.onFunctionCall(call.name, org.json.JSONObject(call.args).toString())
                stopGeneration()
                return
            }
            return
        }
        generationBuffer.append(token)
        flutterCallbacks?.onToken(token)
    }

    private fun finishGeneration() {
        val full = generationBuffer.toString()
        if (full.isNotEmpty()) {
            historyCharEstimate += formatTurn("model", full).length
            flutterCallbacks?.onGenerationComplete(full)
        } else if (functionBuffer.isNotEmpty()) {
            val call = GemmaFunctionCallParser.tryParse(functionBuffer.toString())
            if (call != null) {
                flutterCallbacks?.onFunctionCall(call.name, org.json.JSONObject(call.args).toString())
            }
        } else {
            flutterCallbacks?.onGenerationComplete("")
        }
        generationBuffer.clear()
        functionBuffer.clear()
        inFunctionCapture = false
    }

    private fun historyChunk(message: LlmHistoryMessage): String = when (message.role) {
        LlmHistoryRole.USER -> formatTurn("user", message.content)
        LlmHistoryRole.ASSISTANT -> formatTurn("model", message.content)
        LlmHistoryRole.TOOL -> formatToolResult(message.toolName ?: "tool", message.content)
    }

    private fun formatTurn(role: String, content: String): String = "$role: $content\n"

    private fun formatToolResult(toolName: String, content: String): String =
        "tool ($toolName): $content\n"

    private fun estimateTokens(charCount: Int): Int =
        maxOf(1, charCount / CHARS_PER_TOKEN_ESTIMATE)

    companion object {
        private const val TAG = "GemmaLlmController"
        private const val CHARS_PER_TOKEN_ESTIMATE = 4
        private const val DEFAULT_MAX_OUTPUT = 768
        private const val DEFAULT_CONTEXT_LIMIT = 8192

        /** Tuned defaults for Gemma 4 E2B on-device chat. */
        fun defaultSessionConfig(): SessionConfig = SessionConfig(
            temperature = 0.85f,
            randomSeed = 1,
            topK = 40,
            topP = 0.92f,
        )
    }
}
