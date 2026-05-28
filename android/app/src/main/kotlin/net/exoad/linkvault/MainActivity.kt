package net.exoad.linkvault

import android.animation.ObjectAnimator
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.animation.AnticipateInterpolator
import androidx.core.animation.doOnEnd
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Single Flutter surface for Linkvault.
 *
 * Native responsibilities are delegated: [InstallManager] backs the install
 * Pigeon API, [IntentReader] normalizes inbound intents. This activity only
 * wires the platform channels, owns the launch intent, and runs the splash.
 */
class MainActivity : FlutterActivity(), IntentHostApi {

    private var flutterIntentApi: FlutterIntentApi? = null

    /** Launch intent (share/shortcut) pulled once by Flutter on startup. */
    private var initialIntent: IncomingIntent? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        InstallHostApi.setUp(messenger, InstallManager(this))
        IntentHostApi.setUp(messenger, this)
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val incoming = IntentReader.fromIntent(intent) ?: return
        flutterIntentApi?.onIntent(incoming) { /* delivery result ignored */ }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        initialIntent = IntentReader.fromIntent(intent)

        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                val slideUp = ObjectAnimator.ofFloat(
                    splashScreenView.iconView,
                    View.TRANSLATION_Y,
                    0f,
                    -splashScreenView.iconView.height.toFloat() * 2,
                )
                slideUp.interpolator = AnticipateInterpolator()
                slideUp.duration = 500L

                val fadeOut = ObjectAnimator.ofFloat(
                    splashScreenView.view,
                    View.ALPHA,
                    1f,
                    0f,
                )
                fadeOut.duration = 300L
                fadeOut.startDelay = 200L

                slideUp.doOnEnd { splashScreenView.remove() }

                slideUp.start()
                fadeOut.start()
            }
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
