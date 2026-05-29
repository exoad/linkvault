package net.exoad.linkvault

import android.app.Application
import androidx.appcompat.app.AppCompatDelegate

/**
 * Forces night mode so native chrome (splash, recents, settings) matches the
 * Flutter dark-only UI.
 */
class LinkvaultApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES)
    }
}
