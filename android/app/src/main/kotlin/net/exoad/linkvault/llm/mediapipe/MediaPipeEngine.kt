package net.exoad.linkvault.llm.mediapipe

import android.content.Context
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import net.exoad.linkvault.llm.EngineConfig
import net.exoad.linkvault.llm.FlowFactory
import net.exoad.linkvault.llm.InferenceEngine
import net.exoad.linkvault.llm.InferenceSession
import net.exoad.linkvault.llm.LlmComputeBackend
import net.exoad.linkvault.llm.SessionConfig
import java.io.File

class MediaPipeEngine(
    private val context: Context,
) : InferenceEngine {
    private var llmInference: LlmInference? = null

    override var isInitialized: Boolean = false
        private set

    override val partialResults = FlowFactory.createSharedFlow<Pair<String, Boolean>>()
    override val errors = FlowFactory.createSharedFlow<Throwable>()

    override suspend fun initialize(config: EngineConfig) {
        if (!File(config.modelPath).exists()) {
            throw IllegalArgumentException("Model not found: ${config.modelPath}")
        }
        val optionsBuilder = LlmInference.LlmInferenceOptions.builder()
            .setModelPath(config.modelPath)
            .setMaxTokens(config.maxTokens)
        config.preferredBackend?.let { backend ->
            val mpBackend = when (backend) {
                LlmComputeBackend.CPU -> LlmInference.Backend.CPU
                LlmComputeBackend.GPU -> LlmInference.Backend.GPU
            }
            optionsBuilder.setPreferredBackend(mpBackend)
        }
        llmInference = LlmInference.createFromOptions(context, optionsBuilder.build())
        isInitialized = true
    }

    override fun createSession(config: SessionConfig): InferenceSession {
        val inference = llmInference
            ?: throw IllegalStateException("MediaPipe engine not initialized")
        return MediaPipeSession(inference, config, partialResults, errors)
    }

    override fun close() {
        llmInference?.close()
        llmInference = null
        isInitialized = false
    }
}
