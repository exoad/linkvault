package net.exoad.linkvault

import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.PathInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.core.animation.doOnEnd
import kotlin.math.cos
import kotlin.math.sin

/**
 * Full-screen splash: white [head-circuit] logo with ambient orbs that orbit from
 * behind the mark to the front (a front spin-by into the logo).
 */
class SplashOrbitOverlay(context: Context) : FrameLayout(context) {

    private val logo: ImageView
    private val orbs: List<View>
    private val orbColors = intArrayOf(
        0xFF6B9FFF.toInt(),
        0xFFFF8FAB.toInt(),
        0xFF5ED4B8.toInt(),
        0xFFA78BFA.toInt(),
    )

    private val logoSizePx: Int
    private val orbSizePx: Int
    private val orbitRxPx: Float
    private val orbitRyPx: Float

    init {
        setBackgroundResource(R.drawable.splash_background)

        logoSizePx = dp(128)
        orbSizePx = dp(16)
        orbitRxPx = dpF(78)
        orbitRyPx = dpF(56)

        logo = ImageView(context).apply {
            setImageResource(R.drawable.ic_head_circuit_logo)
            scaleType = ImageView.ScaleType.FIT_CENTER
            elevation = dpF(12)
        }
        addView(
            logo,
            LayoutParams(logoSizePx, logoSizePx, Gravity.CENTER),
        )

        orbs = orbColors.mapIndexed { index, color ->
            View(context).apply {
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(color)
                }
                elevation = dpF(2)
                alpha = 0f
            }.also { orb ->
                addView(orb, LayoutParams(orbSizePx, orbSizePx, Gravity.CENTER))
            }
        }
    }

    /**
     * Plays the orbit-in animation, then fades the overlay out.
     */
    fun play(onFinished: () -> Unit) {
        val ease = PathInterpolator(0.35f, 0f, 0.15f, 1f)
        val orbitDuration = 1200L
        val stagger = 140L

        val orbitAnimators = orbs.mapIndexed { index, orb ->
            ValueAnimator.ofFloat(0f, 1f).apply {
                duration = orbitDuration
                startDelay = index * stagger
                interpolator = ease
                addUpdateListener { animator ->
                    val t = animator.animatedValue as Float
                    placeOrb(orb, t)
                }
            }
        }

        val fadeInLogo = ValueAnimator.ofFloat(0.85f, 1f).apply {
            duration = 480L
            interpolator = ease
            addUpdateListener {
                val s = it.animatedValue as Float
                logo.scaleX = s
                logo.scaleY = s
                logo.alpha = (it.animatedFraction * 1f).coerceIn(0f, 1f)
            }
        }

        AnimatorSet().apply {
            playTogether(orbitAnimators + fadeInLogo)
            doOnEnd {
                animate()
                    .alpha(0f)
                    .setDuration(280L)
                    .setInterpolator(ease)
                    .withEndAction { onFinished() }
                    .start()
            }
            start()
        }
    }

    /**
     * [t]: 0 = behind the logo (top of orbit, small/faint), 1 = merged at front.
     */
    private fun placeOrb(orb: View, t: Float) {
        val cx = width / 2f
        val cy = height / 2f
        // π (back/top) → 2π (front/bottom) — sweeps in front of the logo.
        val angle = Math.PI + t * Math.PI
        var ox = orbitRxPx * cos(angle).toFloat()
        var oy = orbitRyPx * sin(angle).toFloat()

        // Final beat: pull orbs into the logo (front spin-by merge).
        if (t > 0.78f) {
            val merge = ((t - 0.78f) / 0.22f).coerceIn(0f, 1f)
            ox *= 1f - merge
            oy *= 1f - merge
        }

        orb.x = cx + ox - orbSizePx / 2f
        orb.y = cy + oy - orbSizePx / 2f

        val depth = sin(angle).toFloat()
        val frontness = ((depth + 1f) / 2f).coerceIn(0f, 1f)
        val mergeScale = if (t > 0.78f) 1f - ((t - 0.78f) / 0.22f) * 0.35f else 1f
        val scale = (0.32f + 0.68f * frontness) * mergeScale
        orb.scaleX = scale
        orb.scaleY = scale
        orb.alpha = (0.25f + 0.75f * frontness) * (0.35f + 0.65f * t) * (1f - (t - 0.85f).coerceAtLeast(0f) * 4f).coerceIn(0f, 1f)
        orb.elevation = dpF(2) + frontness * dpF(10)
        logo.elevation = dpF(12)
        if (t > 0.9f) {
            val pulse = 1f + 0.04f * ((t - 0.9f) / 0.1f)
            logo.scaleX = pulse
            logo.scaleY = pulse
        }
    }

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        ).toInt()

    private fun dpF(value: Int): Float =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        )

    companion object {
        fun attach(activity: MainActivity, onComplete: () -> Unit): SplashOrbitOverlay {
            val root = activity.window.decorView as ViewGroup
            val overlay = SplashOrbitOverlay(activity).apply {
                alpha = 1f
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                )
            }
            root.addView(overlay)
            overlay.post {
                overlay.play {
                    root.removeView(overlay)
                    onComplete()
                }
            }
            return overlay
        }
    }
}
