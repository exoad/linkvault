package net.exoad.linkvault.llm.mediapipe

import android.util.Log
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import kotlinx.coroutines.flow.MutableSharedFlow
import net.exoad.linkvault.llm.InferenceSession
import net.exoad.linkvault.llm.SessionConfig

class MediaPipeSession(
    private val llmInference: LlmInference,
    config: SessionConfig,
    private val resultFlow: MutableSharedFlow<Pair<String, Boolean>>,
    private val errorFlow: MutableSharedFlow<Throwable>,
) : InferenceSession {
    private val session: LlmInferenceSession

    init {
        val builder = LlmInferenceSession.LlmInferenceSessionOptions.builder()
            .setTemperature(config.temperature)
            .setRandomSeed(config.randomSeed)
            .setTopK(config.topK)
        config.topP?.let { builder.setTopP(it) }
        session = LlmInferenceSession.createFromOptions(llmInference, builder.build())
    }

    override fun addQueryChunk(prompt: String) {
        session.addQueryChunk(prompt)
    }

    override fun generateResponse(): String {
        return try {
            session.generateResponse()
                ?: throw RuntimeException("MediaPipe returned null response")
        } catch (e: Exception) {
            Log.e(TAG, "generateResponse failed", e)
            errorFlow.tryEmit(e)
            throw e
        }
    }

    override fun generateResponseAsync() {
        session.generateResponseAsync { result, done ->
            if (result != null) {
                resultFlow.tryEmit(result to done)
            } else if (done) {
                resultFlow.tryEmit("" to true)
            }
        }
    }

    override fun cancelGeneration() {
        session.cancelGenerateResponseAsync()
    }

    override fun close() {
        session.close()
    }

    companion object {
        private const val TAG = "MediaPipeSession"
    }
}
