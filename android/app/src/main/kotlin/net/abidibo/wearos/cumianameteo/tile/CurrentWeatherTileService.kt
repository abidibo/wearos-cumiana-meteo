package net.abidibo.wearos.cumianameteo.tile

import android.graphics.BitmapFactory
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.LayoutElementBuilders.Column
import androidx.wear.protolayout.LayoutElementBuilders.FontStyles
import androidx.wear.protolayout.LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER
import androidx.wear.protolayout.LayoutElementBuilders.Image
import androidx.wear.protolayout.LayoutElementBuilders.Layout
import androidx.wear.protolayout.LayoutElementBuilders.Spacer
import androidx.wear.protolayout.LayoutElementBuilders.Text
import androidx.wear.protolayout.LayoutElementBuilders.VERTICAL_ALIGN_CENTER
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.TypeBuilders.StringProp
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.guava.future
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import net.abidibo.wearos.cumianameteo.MainActivity
import java.util.Locale
import kotlin.math.roundToInt

class CurrentWeatherTileService : TileService() {

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val cache by lazy { WeatherCache(this) }
    private val fetcher by lazy { WeatherFetcher(cache) }

    override fun onDestroy() {
        serviceScope.cancel()
        super.onDestroy()
    }

    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> = serviceScope.future {
        val initial = cache.read()
        val stale = initial == null ||
            (System.currentTimeMillis() - initial.fetchedAtMillis) > STALE_MS

        val snapshot = if (stale) {
            val fresh = withTimeoutOrNull(INLINE_FETCH_BUDGET_MS) { fetcher.fetch() }
            if (fresh != null) {
                cache.write(fresh)
                fresh
            } else {
                // Best-effort background refresh to populate the next tile request.
                if (initial == null) scheduleBackgroundRefresh()
                initial
            }
        } else {
            initial
        }

        buildTile(snapshot)
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> = serviceScope.future {
        buildResources(requestParams.version)
    }

    private fun scheduleBackgroundRefresh() {
        serviceScope.launch {
            val fresh = fetcher.fetch() ?: return@launch
            cache.write(fresh)
            getUpdater(this@CurrentWeatherTileService)
                .requestUpdate(CurrentWeatherTileService::class.java)
        }
    }

    private fun buildTile(snapshot: WeatherSnapshot?): TileBuilders.Tile {
        val resourcesVersion = snapshot?.iconFilename ?: RESOURCES_VERSION_EMPTY
        val layout = Layout.Builder().setRoot(rootLayout(snapshot)).build()
        return TileBuilders.Tile.Builder()
            .setResourcesVersion(resourcesVersion)
            .setTileTimeline(
                TimelineBuilders.Timeline.Builder()
                    .addTimelineEntry(
                        TimelineBuilders.TimelineEntry.Builder()
                            .setLayout(layout)
                            .build(),
                    )
                    .build(),
            )
            // 5 min freshness ⇒ system will re-request after this elapses.
            .setFreshnessIntervalMillis(STALE_MS)
            .build()
    }

    private fun rootLayout(snapshot: WeatherSnapshot?): LayoutElementBuilders.LayoutElement {
        val tempText = snapshot?.let { formatTemperature(it.temperature) } ?: "—"
        val ageText = snapshot?.let { formatAge(System.currentTimeMillis() - it.fetchedAtMillis) }
            ?: getString(net.abidibo.wearos.cumianameteo.R.string.tile_no_data)

        val columnBuilder = Column.Builder()
            .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)
            .addContent(stationLabel())
            .addContent(spacer(2))
        if (snapshot != null) {
            columnBuilder.addContent(weatherIcon()).addContent(spacer(2))
        }
        columnBuilder
            .addContent(bigTemperature(tempText))
            .addContent(spacer(4))
            .addContent(ageLabel(ageText))

        return LayoutElementBuilders.Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)
            .setVerticalAlignment(VERTICAL_ALIGN_CENTER)
            .setModifiers(
                ModifiersBuilders.Modifiers.Builder()
                    .setClickable(launchAppClickable())
                    .build(),
            )
            .addContent(columnBuilder.build())
            .build()
    }

    private fun stationLabel(): Text =
        Text.Builder()
            .setText(getString(net.abidibo.wearos.cumianameteo.R.string.tile_station))
            .setFontStyle(
                FontStyles.title2(deviceParameters())
                    .setColor(argb(COLOR_SECONDARY))
                    .build(),
            )
            .build()

    private fun weatherIcon(): Image =
        Image.Builder()
            .setResourceId(RESOURCE_ID_ICON)
            .setWidth(dp(40f))
            .setHeight(dp(40f))
            .setContentScaleMode(LayoutElementBuilders.CONTENT_SCALE_MODE_FIT)
            .build()

    private fun bigTemperature(text: String): Text =
        Text.Builder()
            .setText(text)
            .setFontStyle(
                FontStyles.display2(deviceParameters())
                    .setColor(argb(COLOR_PRIMARY))
                    .build(),
            )
            .build()

    private fun ageLabel(text: String): Text =
        Text.Builder()
            .setText(text)
            .setFontStyle(
                FontStyles.body1(deviceParameters())
                    .setColor(argb(COLOR_TERTIARY))
                    .build(),
            )
            .build()

    private fun spacer(heightDp: Int): Spacer =
        Spacer.Builder().setHeight(dp(heightDp.toFloat())).build()

    private fun launchAppClickable(): ModifiersBuilders.Clickable =
        ModifiersBuilders.Clickable.Builder()
            .setId(CLICKABLE_ID_OPEN_APP)
            .setOnClick(
                ActionBuilders.LaunchAction.Builder()
                    .setAndroidActivity(
                        ActionBuilders.AndroidActivity.Builder()
                            .setClassName(MainActivity::class.java.name)
                            .setPackageName(packageName)
                            .build(),
                    )
                    .build(),
            )
            .build()

    private fun deviceParameters() =
        androidx.wear.protolayout.DeviceParametersBuilders.DeviceParameters.Builder()
            .setScreenWidthDp(192)
            .setScreenHeightDp(192)
            .setScreenDensity(resources.displayMetrics.density)
            .setScreenShape(androidx.wear.protolayout.DeviceParametersBuilders.SCREEN_SHAPE_ROUND)
            .setDevicePlatform(androidx.wear.protolayout.DeviceParametersBuilders.DEVICE_PLATFORM_WEAR_OS)
            .build()

    private fun buildResources(version: String): ResourceBuilders.Resources {
        val builder = ResourceBuilders.Resources.Builder().setVersion(version)
        val iconFile = cache.iconFile()
        if (iconFile.exists()) {
            val bytes = iconFile.readBytes()
            val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
            if (opts.outWidth > 0 && opts.outHeight > 0) {
                builder.addIdToImageMapping(
                    RESOURCE_ID_ICON,
                    ResourceBuilders.ImageResource.Builder()
                        .setInlineResource(
                            ResourceBuilders.InlineImageResource.Builder()
                                .setData(bytes)
                                .setWidthPx(opts.outWidth)
                                .setHeightPx(opts.outHeight)
                                .setFormat(ResourceBuilders.IMAGE_FORMAT_UNDEFINED)
                                .build(),
                        )
                        .build(),
                )
            }
        }
        return builder.build()
    }

    private fun formatTemperature(value: Double): String {
        // Round to 1 decimal, drop trailing .0 to keep the glyph count low.
        val rounded = (value * 10.0).roundToInt() / 10.0
        val text = if (rounded == rounded.toLong().toDouble()) {
            rounded.toLong().toString()
        } else {
            String.format(Locale.ROOT, "%.1f", rounded)
        }
        return "$text°"
    }

    private fun formatAge(ageMs: Long): String {
        val minutes = ageMs / 60_000
        return when {
            minutes < 1 -> "just now"
            minutes < 60 -> "${minutes}m ago"
            minutes < 24 * 60 -> "${minutes / 60}h ago"
            else -> "stale"
        }
    }

    companion object {
        private const val STALE_MS = 5L * 60 * 1000
        private const val INLINE_FETCH_BUDGET_MS = 2_500L
        private const val RESOURCE_ID_ICON = "weather_icon"
        private const val RESOURCES_VERSION_EMPTY = "empty"
        private const val CLICKABLE_ID_OPEN_APP = "open_app"

        // ARGB ints — primary cyan/blue, near-white secondary, dim tertiary.
        private const val COLOR_PRIMARY = 0xFF00B5FF.toInt()
        private const val COLOR_SECONDARY = 0xFFBDBDBD.toInt()
        private const val COLOR_TERTIARY = 0xFF757575.toInt()
    }
}
