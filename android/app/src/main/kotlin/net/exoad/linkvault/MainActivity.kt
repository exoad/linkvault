package net.exoad.linkvault

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Single Flutter surface for Linkvault.
 *
 * Native: [InstallManager], [IntentReader], orbit splash ([SplashOrbitOverlay]),
 * handoff via [UiHostApi], edge-to-edge window polish.
 */
class MainActivity : FlutterActivity(), IntentHostApi, UiHostApi {

    private var flutterIntentApi: FlutterIntentApi? = null

    private var initialIntent: IncomingIntent? = null

    private val flutterUiReady = AtomicBoolean(false)
    private val splashAnimationDone = AtomicBoolean(false)
    private var splashOrbitStarted = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        InstallHostApi.setUp(messenger, InstallManager(this))
        IntentHostApi.setUp(messenger, this)
        UiHostApi.setUp(messenger, this)
        flutterIntentApi = FlutterIntentApi(messenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        flutterIntentApi = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun getInitialIntent(): IncomingIntent? {
        val pending = initialIntent
        initialIntent = null
        return pending
    }

    override fun notifyUiReady() {
        flutterUiReady.set(true)
        tryDismissSplash()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val incoming = IntentReader.fromIntent(intent) ?: return
        flutterIntentApi?.onIntent(incoming) { /* delivery result ignored */ }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        initialIntent = IntentReader.fromIntent(intent)

        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { shouldKeepSplashOnScreen() }

        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { provider ->
                SplashExitAnimator.play(provider)
            }
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }

        if (savedInstanceState != null) {
            splashAnimationDone.set(true)
            return
        }

        window.decorView.post {
            if (splashOrbitStarted || splashAnimationDone.get()) return@post
            splashOrbitStarted = true
            SplashOrbitOverlay.attach(this) {
                splashAnimationDone.set(true)
                tryDismissSplash()
            }
        }
    }

    private fun shouldKeepSplashOnScreen(): Boolean =
        !flutterUiReady.get() || !splashAnimationDone.get()

    private fun tryDismissSplash() {
        if (flutterUiReady.get() && splashAnimationDone.get()) {
            // Triggers SplashScreen to dismiss when condition becomes false.
            window.decorView.post { window.decorView.invalidate() }
        }
    }
}
