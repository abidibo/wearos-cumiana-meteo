package net.abidibo.wearos.cumianameteo.complication

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Intent
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.data.SmallImage
import androidx.wear.watchface.complications.data.SmallImageType
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceService
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import android.graphics.drawable.Icon
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import net.abidibo.wearos.cumianameteo.MainActivity
import net.abidibo.wearos.cumianameteo.R
import net.abidibo.wearos.cumianameteo.tile.WeatherCache
import net.abidibo.wearos.cumianameteo.tile.WeatherFetcher
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Short-text complication showing the current Cumiana temperature with a
 * thermometer icon. Reuses the tile's cache/fetcher so the two keep each
 * other's data warm (shared SharedPreferences).
 *
 * Unlike a tile, the complication system polls on its own schedule and cannot
 * await a long fetch, so we serve the cache immediately and, when it is stale,
 * kick off a background refresh that asks the system to re-request.
 */
class CurrentWeatherComplicationService : ComplicationDataSourceService() {

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val cache by lazy { WeatherCache(this) }
    private val fetcher by lazy { WeatherFetcher(cache) }

    override fun onDestroy() {
        serviceScope.cancel()
        super.onDestroy()
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        if (type != ComplicationType.SHORT_TEXT) return null
        return shortText("21°")
    }

    override fun onComplicationRequest(
        request: ComplicationRequest,
        listener: ComplicationRequestListener,
    ) {
        if (request.complicationType != ComplicationType.SHORT_TEXT) {
            listener.onComplicationData(null)
            return
        }

        val snapshot = cache.read()
        val stale = snapshot == null ||
            (System.currentTimeMillis() - snapshot.fetchedAtMillis) > STALE_MS

        if (stale) scheduleBackgroundRefresh()

        listener.onComplicationData(
            shortText(snapshot?.let { formatTemperature(it.temperature) } ?: PLACEHOLDER_TEXT),
        )
    }

    private fun scheduleBackgroundRefresh() {
        serviceScope.launch {
            val fresh = withTimeoutOrNull(FETCH_BUDGET_MS) { fetcher.fetch() } ?: return@launch
            cache.write(fresh)
            // Ask the system to re-request this complication with the new data.
            requestUpdateAll()
        }
    }

    private fun requestUpdateAll() {
        ComplicationDataSourceUpdateRequester
            .create(
                this,
                ComponentName(this, CurrentWeatherComplicationService::class.java),
            )
            .requestUpdateAll()
    }

    private fun shortText(text: String): ComplicationData {
        val contentDescription = PlainComplicationText.Builder(
            getString(R.string.complication_label),
        ).build()

        return ShortTextComplicationData.Builder(
            text = PlainComplicationText.Builder(text).build(),
            contentDescription = contentDescription,
        )
            // Monochromatic for faces that tint it; SmallImage keeps fixed
            // colors on faces that would otherwise wash it out to theme gray.
            .setMonochromaticImage(
                MonochromaticImage.Builder(
                    Icon.createWithResource(this, R.drawable.ic_thermometer),
                ).build(),
            )
            .setSmallImage(
                SmallImage.Builder(
                    Icon.createWithResource(this, R.drawable.ic_thermometer_color),
                    SmallImageType.ICON,
                ).build(),
            )
            .setTapAction(launchAppPendingIntent())
            .build()
    }

    private fun launchAppPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun formatTemperature(value: Double): String {
        val rounded = (value * 10.0).roundToInt() / 10.0
        val text = if (rounded == rounded.toLong().toDouble()) {
            rounded.toLong().toString()
        } else {
            String.format(Locale.ROOT, "%.1f", rounded)
        }
        return "$text°"
    }

    companion object {
        private const val STALE_MS = 5L * 60 * 1000
        private const val FETCH_BUDGET_MS = 5_000L
        private const val PLACEHOLDER_TEXT = "—°"
    }
}
