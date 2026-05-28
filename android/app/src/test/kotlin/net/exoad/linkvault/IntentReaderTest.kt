package net.exoad.linkvault

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** JVM unit tests for the pure classification helpers in [IntentReader]. */
class IntentReaderTest {

    @Test
    fun extractsUrlFromMixedText() {
        assertEquals(
            "https://example.com/page",
            IntentReader.extractUrl("Check this out https://example.com/page now"),
        )
    }

    @Test
    fun trimsTrailingPunctuationFromUrl() {
        assertEquals(
            "https://example.com",
            IntentReader.extractUrl("see (https://example.com)."),
        )
    }

    @Test
    fun returnsNullWhenNoUrlPresent() {
        assertNull(IntentReader.extractUrl("just some plain words"))
        assertNull(IntentReader.extractUrl(null))
        assertNull(IntentReader.extractUrl("   "))
    }

    @Test
    fun sharedUrlBecomesSaveLink() {
        val intent = IntentReader.fromSharedText("https://example.com")
        assertEquals(IntentKind.SAVE_LINK, intent?.kind)
        assertEquals("https://example.com", intent?.text)
        assertEquals(IntentReader.MODULE_LINKS, intent?.targetModuleId)
    }

    @Test
    fun sharedPlainTextBecomesShareText() {
        val intent = IntentReader.fromSharedText("a quick thought")
        assertEquals(IntentKind.SHARE_TEXT, intent?.kind)
        assertEquals("a quick thought", intent?.text)
        assertNull(intent?.targetModuleId)
    }

    @Test
    fun blankSharedTextIsNull() {
        assertNull(IntentReader.fromSharedText("   "))
        assertNull(IntentReader.fromSharedText(null))
    }

    @Test
    fun shortcutTokensMapToKinds() {
        assertEquals(
            IntentKind.SAVE_LINK,
            IntentReader.fromShortcut(IntentReader.SHORTCUT_SAVE_LINK)?.kind,
        )
        assertEquals(
            IntentKind.NEW_NOTE,
            IntentReader.fromShortcut(IntentReader.SHORTCUT_NEW_NOTE)?.kind,
        )
        assertNull(IntentReader.fromShortcut("bogus"))
    }

    @Test
    fun signingHexFormatsBytesAsLowercasePaddedHex() {
        val hex = SigningHex.toHex(byteArrayOf(0x00, 0x0f, 0xff.toByte(), 0x10))
        assertEquals("000fff10", hex)
    }
}
