package net.abidibo.wearos.cumianameteo.tile

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class WeatherFetcher(private val cache: WeatherCache) {

    /**
     * Fetches the realtime payload and downloads the weather icon to a file.
     * Returns null on any failure (network, parse, non-200). The caller is
     * expected to fall back to the previously cached snapshot.
     */
    suspend fun fetch(): WeatherSnapshot? = withContext(Dispatchers.IO) {
        runCatching {
            val payload = httpGet(API_URL) ?: return@runCatching null
            val json = JSONObject(payload)
            val temperature = json.getString("temperature").toDouble()
            val iconUrl = json.getJSONObject("weather_icon").getString("icon")
            val iconFilename = iconUrl.substringAfterLast('/')
            downloadTo(iconUrl, cache.iconFile())
            WeatherSnapshot(
                temperature = temperature,
                iconFilename = iconFilename,
                fetchedAtMillis = System.currentTimeMillis(),
            )
        }.getOrNull()
    }

    private fun httpGet(url: String): String? {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = TIMEOUT_MS
            readTimeout = TIMEOUT_MS
            requestMethod = "GET"
        }
        return try {
            if (conn.responseCode != 200) return null
            conn.inputStream.bufferedReader().use { it.readText() }
        } finally {
            conn.disconnect()
        }
    }

    private fun downloadTo(url: String, file: File) {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = TIMEOUT_MS
            readTimeout = TIMEOUT_MS
            requestMethod = "GET"
        }
        try {
            if (conn.responseCode != 200) return
            conn.inputStream.use { input ->
                file.outputStream().use { output -> input.copyTo(output) }
            }
        } finally {
            conn.disconnect()
        }
    }

    companion object {
        private const val API_URL = "https://www.torinometeo.org/api/v1/realtime/data/cumiana/"
        private const val TIMEOUT_MS = 3_000
    }
}
