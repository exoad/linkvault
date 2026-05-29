package net.exoad.linkvault

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.view.View
import android.view.animation.PathInterpolator
import androidx.core.animation.doOnEnd
import androidx.core.splashscreen.SplashScreenViewProvider

/**
 * Material-style fade/scale exit for the Android 12+ splash screen.
 */
object SplashExitAnimator {
    private val easeOut = PathInterpolator(0.2f, 0f, 0f, 1f)

    fun play(provider: SplashScreenViewProvider) {
        val root = provider.view
        val icon = provider.iconView

        val rootFade = ObjectAnimator.ofFloat(root, View.ALPHA, 1f, 0f).apply {
            duration = 380L
            interpolator = easeOut
        }

        val iconScaleX = ObjectAnimator.ofFloat(icon, View.SCALE_X, 1f, 0.94f).apply {
            duration = 380L
            interpolator = easeOut
        }
        val iconScaleY = ObjectAnimator.ofFloat(icon, View.SCALE_Y, 1f, 0.94f).apply {
            duration = 380L
            interpolator = easeOut
        }

        AnimatorSet().apply {
            playTogether(rootFade, iconScaleX, iconScaleY)
            doOnEnd { provider.remove() }
            start()
        }
    }
}
