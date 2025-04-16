import 'package:net.abidibo.wearos.cumianameteo/realtime/cubit/station_cubit.dart';
import 'package:flutter/material.dart';

class RealtimeData {
  RealtimeData({
    required this.stationName,
    required this.weatherIcon,
    required this.datetime,
    required this.temperature,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.relativeHumidity,
    required this.relativeHumidityMax,
    required this.relativeHumidityMin,
    required this.pressure,
    required this.pressureMax,
    required this.pressureMin,
    required this.windStrength,
    required this.windDirection,
    required this.windStrengthMax,
    required this.windDirectionMax,
    required this.rainRate,
    required this.rain,
  });

  final String stationName;
  final String weatherIcon;
  final String datetime;
  final double temperature;
  final double temperatureMax;
  final double temperatureMin;
  final double relativeHumidity;
  final double relativeHumidityMax;
  final double relativeHumidityMin;
  final double pressure;
  final double pressureMax;
  final double pressureMin;
  final double windStrength;
  final String windDirection;
  final double windStrengthMax;
  final String windDirectionMax;
  final double rainRate;
  final double rain;

  String label(Screen screen) {
    switch (screen) {
      case Screen.temperature:
        return 'T (°C)';
      case Screen.pressure:
        return 'P (hPa)';
      case Screen.relativeHumidity:
        return 'RH (%)';
      case Screen.rain:
        return 'Rain (mm)';
      case Screen.weather:
        return 'Weather';
      case Screen.wind:
        return 'Wind (Km/h)';
    }
  }

  Color tempColor(double value) {
    if (value < 0) return const Color(0xFF0D47A1);
    if (value < 10) return const Color(0xFF00B8D4);
    if (value < 18) return const Color(0xFFFFEE58);
    if (value < 25) return const Color(0xFFFFAB40);
    return const Color(0xFFD84315);
  }

  Widget data(BuildContext context, Screen screen, ThemeData theme) {
    switch (screen) {
      case Screen.temperature:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/charts");
              },
              child: Text(
                '$temperature ',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: tempColor(temperature),
                ),
              ),
            ),
            const Text('°C', style: TextStyle(fontSize: 16)),
          ],
        );
      case Screen.pressure:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$pressure ', style: theme.textTheme.displaySmall),
            const Text('hPa', style: TextStyle(fontSize: 16)),
          ],
        );
      case Screen.relativeHumidity:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$relativeHumidity ', style: theme.textTheme.displaySmall),
            const Text('%', style: TextStyle(fontSize: 16)),
          ],
        );
      case Screen.rain:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$rainRate ', style: theme.textTheme.displaySmall),
            const Text('mm/h', style: TextStyle(fontSize: 16)),
          ],
        );
      case Screen.weather:
        return Image.network(
          width: 60,
          height: 60,
          weatherIcon,
        );
      case Screen.wind:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$windStrength ', style: theme.textTheme.displaySmall),
            Text('$windDirection ', style: theme.textTheme.displaySmall),
            const Text('Km/h ', style: TextStyle(fontSize: 16)),
          ],
        );
    }
  }

  Row dataExtremes(Screen screen) {
    switch (screen) {
      case Screen.temperature:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward, size: 14),
            Text(
              temperatureMax.toString(),
              style: TextStyle(
                color: tempColor(temperatureMax),
              ),
            ),
            const Text(' / '),
            Text(
              temperatureMin.toString(),
              style: TextStyle(
                color: tempColor(temperatureMin),
              ),
            ),
            const Icon(Icons.arrow_downward, size: 14),
          ],
        );
      case Screen.pressure:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward, size: 14),
            Text(pressureMax.toString()),
            const Text(' / '),
            Text(pressureMin.toString()),
            const Icon(Icons.arrow_downward, size: 14),
          ],
        );
      case Screen.relativeHumidity:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward, size: 14),
            Text(relativeHumidityMax.toString()),
            const Text(' / '),
            Text(relativeHumidityMin.toString()),
            const Icon(Icons.arrow_downward, size: 14),
          ],
        );
      case Screen.rain:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.area_chart, size: 14),
            const Text(' '),
            Text(rain.toString()),
            const Text(' mm'),
          ],
        );
      case Screen.weather:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
        );
      case Screen.wind:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward, size: 14),
            Text('$windStrengthMax $windDirectionMax'),
          ],
        );
    }
  }
}
