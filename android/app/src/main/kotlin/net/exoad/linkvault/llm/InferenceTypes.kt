package net.exoad.linkvault.llm

import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow

data class EngineConfig(
    val modelPath: String,
    val maxTokens: Int,
    val preferredBackend: LlmComputeBackend?,
    val maxNumImages: Int? = null,
    val supportAudio: Boolean? = null,
)

data class SessionConfig(
    val temperature: Float = 1.0f,
    val randomSeed: Int = 1,
    val topK: Int = 64,
    val topP: Float? = 0.95f,
    val enableVisionModality: Boolean? = null,
    val enableAudioModality: Boolean? = null,
)

interface InferenceSession {
    fun addQueryChunk(prompt: String)
    fun generateResponse(): String
    fun generateResponseAsync()
    fun cancelGeneration()
    fun close()
}

interface InferenceEngine {
    val isInitialized: Boolean
    suspend fun initialize(config: EngineConfig)
    fun createSession(config: SessionConfig): InferenceSession
    val partialResults: MutableSharedFlow<Pair<String, Boolean>>
    val errors: MutableSharedFlow<Throwable>
    fun close()
}

object FlowFactory {
    fun <T> createSharedFlow(): MutableSharedFlow<T> = MutableSharedFlow(
        extraBufferCapacity = 64,
        onBufferOverflow = BufferOverflow.DROP_OLDEST,
    )
}

enum class EngineType {
    MEDIAPIPE,
    LITERTLM,
}

object EngineFactory {
    fun detectEngineType(modelPath: String): EngineType = when {
        modelPath.endsWith(".litertlm", ignoreCase = true) -> EngineType.LITERTLM
        modelPath.endsWith(".task", ignoreCase = true) -> EngineType.MEDIAPIPE
        else -> throw IllegalArgumentException(
            "Unsupported model: $modelPath (use .litertlm or .task)",
        )
    }
}
