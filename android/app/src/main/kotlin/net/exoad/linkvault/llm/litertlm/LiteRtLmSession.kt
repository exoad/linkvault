package net.exoad.linkvault.llm.litertlm

import android.util.Log
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.MessageCallback
import com.google.ai.edge.litertlm.SamplerConfig
import kotlinx.coroutines.flow.MutableSharedFlow
import net.exoad.linkvault.llm.InferenceSession
import net.exoad.linkvault.llm.SessionConfig

class LiteRtLmSession(
    engine: Engine,
    config: SessionConfig,
    private val resultFlow: MutableSharedFlow<Pair<String, Boolean>>,
    private val errorFlow: MutableSharedFlow<Throwable>,
) : InferenceSession {
    private val conversation: Conversation
    private val pendingPrompt = StringBuilder()
    private val promptLock = Any()

    init {
        val sampler = SamplerConfig(
            topK = config.topK,
            topP = (config.topP ?: 0.95f).toDouble(),
            temperature = config.temperature.toDouble(),
        )
        conversation = engine.createConversation(
            ConversationConfig(samplerConfig = sampler, systemMessage = null),
        )
    }

    override fun addQueryChunk(prompt: String) {
        synchronized(promptLock) {
            pendingPrompt.append(prompt)
        }
    }

    override fun generateResponse(): String {
        val message = consumePendingMessage()
        return conversation.sendMessage(message).toString()
    }

    override fun generateResponseAsync() {
        val message = consumePendingMessage()
        conversation.sendMessageAsync(message, object : MessageCallback {
            override fun onMessage(message: com.google.ai.edge.litertlm.Message) {
                resultFlow.tryEmit(message.toString() to false)
            }

            override fun onDone() {
                resultFlow.tryEmit("" to true)
            }

            override fun onError(throwable: Throwable) {
                errorFlow.tryEmit(throwable)
                resultFlow.tryEmit("" to true)
            }
        })
    }

    override fun cancelGeneration() {
        try {
            conversation.cancelProcess()
        } catch (e: Exception) {
            Log.w(TAG, "cancel failed", e)
        }
    }

    override fun close() {
        try {
            conversation.close()
        } catch (e: Exception) {
            Log.w(TAG, "close failed", e)
        }
    }

    private fun consumePendingMessage(): Contents {
        val text = synchronized(promptLock) {
            val value = pendingPrompt.toString()
            pendingPrompt.clear()
            value
        }
        return Contents.of(listOf(Content.Text(text)))
    }

    companion object {
        private const val TAG = "LiteRtLmSession"
    }
}
