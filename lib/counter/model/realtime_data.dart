import 'package:cumiana_meteo/counter/cubit/station_cubit.dart';
import 'package:flutter/cupertino.dart';
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

  String label (Screen screen) {
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

  String data (Screen screen) {
    switch (screen) {
      case Screen.temperature:
        return temperature.toString();
      case Screen.pressure:
        return pressure.toString();
      case Screen.relativeHumidity:
        return relativeHumidity.toString();
      case Screen.rain:
        return rain.toString();
      case Screen.weather:
        return weatherIcon;
      case Screen.wind:
        return '$windStrength $windDirection';
    }
  }

  Row dataExtremes (Screen screen) {
    switch (screen) {
      case Screen.temperature:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward),
            Text(temperatureMax.toString()),
            const Text(' / '),
            Text(temperatureMin.toString()),
            const Icon(Icons.arrow_downward),
          ],
        );
      case Screen.pressure:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward),
            Text(pressureMax.toString()),
            const Text(' / '),
            Text(pressureMin.toString()),
            const Icon(Icons.arrow_downward),

          ],
        );
      case Screen.relativeHumidity:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_upward),
            Text(relativeHumidityMax.toString()),
            const Text(' / '),
            Text(relativeHumidityMin.toString()),
            const Icon(Icons.arrow_downward),
          ],
        );
      case Screen.rain:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline),
            Text(rainRate.toString()),
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
            const Icon(Icons.arrow_upward),
            Text('$windStrengthMax $windDirectionMax'),
          ],
        );
    }
  }
}
