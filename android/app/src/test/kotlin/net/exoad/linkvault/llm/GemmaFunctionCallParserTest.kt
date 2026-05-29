package net.exoad.linkvault.llm

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class GemmaFunctionCallParserTest {

    @Test
    fun parseFunctionCall_withParameters() {
        val json = """{"name":"search_links","parameters":{"query":"flutter"}}"""
        val call = GemmaFunctionCallParser.tryParse(json)
        assertNotNull(call)
        assertEquals("search_links", call!!.name)
        assertEquals("flutter", call.args["query"])
    }

    @Test
    fun parseFunctionCall_withArgsAlias() {
        val json = """{"name":"get_current_time","args":{}}"""
        val call = GemmaFunctionCallParser.tryParse(json)
        assertNotNull(call)
        assertEquals("get_current_time", call!!.name)
        assertTrue(call.args.isEmpty())
    }

    @Test
    fun parseRejectsNonJson() {
        assertNull(GemmaFunctionCallParser.tryParse("not json"))
        assertNull(GemmaFunctionCallParser.tryParse("""{"parameters":{}}"""))
    }

    @Test
    fun isLikelyFunctionStart_detectsOpeningBrace() {
        assertTrue(GemmaFunctionCallParser.isLikelyFunctionStart("  {\"name\":\"x\"}"))
        assertTrue(GemmaFunctionCallParser.isLikelyFunctionStart("{function"))
    }
}
