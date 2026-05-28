package net.exoad.linkvault

import android.content.Intent

/**
 * Converts inbound Android [Intent]s (share, process-text, launcher shortcuts)
 * into a normalized [IncomingIntent] for delivery to Flutter.
 *
 * The classification helpers ([extractUrl], [fromSharedText], [fromShortcut])
 * are pure string logic so they can be unit tested without Robolectric.
 */
object IntentReader {

    /** Extra key for dynamic launcher shortcuts (static ones use actions). */
    const val EXTRA_SHORTCUT = "lv_shortcut"

    const val SHORTCUT_SAVE_LINK = "save_link"
    const val SHORTCUT_NEW_NOTE = "new_note"

    /** Explicit actions used by static launcher shortcuts (res/xml/shortcuts.xml). */
    const val ACTION_SAVE_LINK = "net.exoad.linkvault.action.SAVE_LINK"
    const val ACTION_NEW_NOTE = "net.exoad.linkvault.action.NEW_NOTE"

    const val MODULE_LINKS = "links"
    const val MODULE_NOTES = "notes"

    private val urlRegex = Regex("""https?://\S+""", RegexOption.IGNORE_CASE)
    private const val TRAILING_PUNCTUATION = ".,;:!?)]}>\"'"

    /** First http(s) URL in [text], trimmed of trailing punctuation, or null. */
    fun extractUrl(text: String?): String? {
        if (text.isNullOrBlank()) return null
        val match = urlRegex.find(text)?.value ?: return null
        val trimmed = match.trimEnd { it in TRAILING_PUNCTUATION }
        return trimmed.ifEmpty { null }
    }

    /**
     * Classifies arbitrary shared text: a URL becomes [IntentKind.SAVE_LINK];
     * anything else becomes [IntentKind.SHARE_TEXT]. Blank input yields null.
     */
    fun fromSharedText(raw: String?): IncomingIntent? {
        val text = raw?.trim()
        if (text.isNullOrEmpty()) return null
        val url = extractUrl(text)
        return if (url != null) {
            IncomingIntent(
                kind = IntentKind.SAVE_LINK,
                text = url,
                targetModuleId = MODULE_LINKS,
            )
        } else {
            IncomingIntent(
                kind = IntentKind.SHARE_TEXT,
                text = text,
                targetModuleId = null,
            )
        }
    }

    /** Maps a launcher shortcut token to an intent (no payload text). */
    fun fromShortcut(token: String?): IncomingIntent? {
        return when (token) {
            SHORTCUT_SAVE_LINK -> IncomingIntent(
                kind = IntentKind.SAVE_LINK,
                text = null,
                targetModuleId = MODULE_LINKS,
            )
            SHORTCUT_NEW_NOTE -> IncomingIntent(
                kind = IntentKind.NEW_NOTE,
                text = null,
                targetModuleId = MODULE_NOTES,
            )
            else -> null
        }
    }

    /** Builds an [IncomingIntent] from an Android [Intent], or null if N/A. */
    fun fromIntent(intent: Intent?): IncomingIntent? {
        if (intent == null) return null

        // A dynamic launcher shortcut extra takes priority over the action.
        intent.getStringExtra(EXTRA_SHORTCUT)?.let { token ->
            fromShortcut(token)?.let { return it }
        }

        return when (intent.action) {
            ACTION_SAVE_LINK -> fromShortcut(SHORTCUT_SAVE_LINK)
            ACTION_NEW_NOTE -> fromShortcut(SHORTCUT_NEW_NOTE)
            Intent.ACTION_SEND -> {
                if (intent.type == "text/plain") {
                    fromSharedText(
                        intent.getStringExtra(Intent.EXTRA_TEXT)
                            ?: intent.getStringExtra(Intent.EXTRA_SUBJECT),
                    )
                } else {
                    null
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val parts = intent.getStringArrayListExtra(Intent.EXTRA_TEXT)
                fromSharedText(parts?.joinToString("\n"))
            }
            Intent.ACTION_PROCESS_TEXT -> {
                fromSharedText(
                    intent.getStringExtra(Intent.EXTRA_PROCESS_TEXT),
                )
            }
            else -> null
        }
    }
}
