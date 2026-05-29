package net.exoad.linkvault.llm

import net.exoad.linkvault.LlmBackend

enum class LlmComputeBackend {
    CPU,
    GPU,
}

fun LlmBackend.toCompute(): LlmComputeBackend = when (this) {
    LlmBackend.CPU -> LlmComputeBackend.CPU
    LlmBackend.GPU -> LlmComputeBackend.GPU
}
