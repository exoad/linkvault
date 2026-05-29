package net.exoad.linkvault.llm

import org.json.JSONObject

/**
 * Detects Gemma-style JSON function calls in model output.
 */
object GemmaFunctionCallParser {
    data class FunctionCall(
        val name: String,
        val args: Map<String, Any?>,
        val raw: String,
    )

    fun tryParse(buffer: String): FunctionCall? {
        val trimmed = buffer.trim()
        if (!trimmed.startsWith("{")) return null
        return try {
            val json = JSONObject(trimmed)
            val name = json.optString("name", "")
            if (name.isEmpty()) return null
            val params = json.optJSONObject("parameters")
                ?: json.optJSONObject("args")
                ?: JSONObject()
            val args = mutableMapOf<String, Any?>()
            params.keys().forEach { key ->
                args[key] = params.get(key)
            }
            FunctionCall(name, args, trimmed)
        } catch (_: Exception) {
            null
        }
    }

    fun isLikelyFunctionStart(text: String): Boolean {
        val t = text.trimStart()
        return t.startsWith("{") && (t.contains("\"name\"") || t.contains("function"))
    }
}
