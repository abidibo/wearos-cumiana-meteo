package net.abidibo.wearos.cumianameteo.tile

import android.content.Context
import java.io.File

/**
 * Cached weather snapshot used to render the tile.
 *
 * Persisted across processes via SharedPreferences (tile runs in its own
 * process). The icon PNG is stored as a file in filesDir to avoid base64'ing
 * binary data into preferences.
 */
data class WeatherSnapshot(
    val temperature: Double,
    val iconFilename: String,
    val fetchedAtMillis: Long,
)

class WeatherCache(private val context: Context) {

    private val prefs by lazy {
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun read(): WeatherSnapshot? {
        if (!prefs.contains(KEY_FETCHED_AT)) return null
        return WeatherSnapshot(
            temperature = java.lang.Double.longBitsToDouble(prefs.getLong(KEY_TEMPERATURE, 0)),
            iconFilename = prefs.getString(KEY_ICON_FILENAME, "") ?: "",
            fetchedAtMillis = prefs.getLong(KEY_FETCHED_AT, 0),
        )
    }

    fun write(snapshot: WeatherSnapshot) {
        prefs.edit()
            .putLong(KEY_TEMPERATURE, java.lang.Double.doubleToRawLongBits(snapshot.temperature))
            .putString(KEY_ICON_FILENAME, snapshot.iconFilename)
            .putLong(KEY_FETCHED_AT, snapshot.fetchedAtMillis)
            .apply()
    }

    fun iconFile(): File = File(context.applicationContext.filesDir, ICON_FILENAME)

    companion object {
        private const val PREFS_NAME = "cumiana_tile_cache"
        private const val KEY_TEMPERATURE = "temperature"
        private const val KEY_ICON_FILENAME = "icon_filename"
        private const val KEY_FETCHED_AT = "fetched_at"
        const val ICON_FILENAME = "weather_icon.png"
    }
}
