package net.exoad.linkvault.llm.litertlm

import android.content.Context
import android.util.Log
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig as LiteRtEngineConfig
import net.exoad.linkvault.llm.EngineConfig
import net.exoad.linkvault.llm.FlowFactory
import net.exoad.linkvault.llm.InferenceEngine
import net.exoad.linkvault.llm.InferenceSession
import net.exoad.linkvault.llm.LlmComputeBackend
import net.exoad.linkvault.llm.SessionConfig
import java.io.File

class LiteRtLmEngine(
    private val context: Context,
) : InferenceEngine {
    private var engine: Engine? = null

    override var isInitialized: Boolean = false
        private set

    override val partialResults = FlowFactory.createSharedFlow<Pair<String, Boolean>>()
    override val errors = FlowFactory.createSharedFlow<Throwable>()

    override suspend fun initialize(config: EngineConfig) {
        if (!File(config.modelPath).exists()) {
            throw IllegalArgumentException("Model not found: ${config.modelPath}")
        }
        val backend = when (config.preferredBackend) {
            LlmComputeBackend.GPU -> Backend.GPU()
            LlmComputeBackend.CPU, null -> Backend.CPU()
        }
        val visionBackend = if (config.maxNumImages != null && config.maxNumImages > 0) {
            backend
        } else {
            null
        }
        val audioBackend = if (config.supportAudio == true) Backend.CPU() else null

        val engineConfig = LiteRtEngineConfig(
            modelPath = config.modelPath,
            backend = backend,
            visionBackend = visionBackend,
            audioBackend = audioBackend,
            maxNumTokens = config.maxTokens,
            cacheDir = context.cacheDir.absolutePath,
        )
        Log.i(TAG, "Initializing LiteRT-LM: $backend maxTokens=${config.maxTokens}")
        val newEngine = Engine(engineConfig)
        newEngine.initialize()
        engine = newEngine
        isInitialized = true
    }

    override fun createSession(config: SessionConfig): InferenceSession {
        val current = engine ?: throw IllegalStateException("LiteRT-LM not initialized")
        return LiteRtLmSession(current, config, partialResults, errors)
    }

    override fun close() {
        try {
            engine?.close()
        } catch (e: Exception) {
            Log.w(TAG, "close failed", e)
        }
        engine = null
        isInitialized = false
    }

    companion object {
        private const val TAG = "LiteRtLmEngine"
    }
}
