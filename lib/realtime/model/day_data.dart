import 'package:net.abidibo.wearos.cumianameteo/realtime/cubit/charts_cubit.dart';

class TimeData {
  TimeData({
    required this.datetime,
    required this.temperature,
    required this.relativeHumidity,
    required this.pressure,
    required this.windStrength,
    required this.rain,
  });

  final String datetime;
  final double temperature;
  final double relativeHumidity;
  final double pressure;
  final double windStrength;
  final double rain;

  double get (ChartsScreen screen) {
    switch (screen) {
      case ChartsScreen.temperature:
        return temperature;
      case ChartsScreen.pressure:
        return pressure;
      case ChartsScreen.relativeHumidity:
        return relativeHumidity;
      case ChartsScreen.rain:
        return rain;
      case ChartsScreen.wind:
        return windStrength;
    }
  }
}

class DayData {
  DayData({
    required this.timeDataList,
  });

  final List<TimeData> timeDataList;

  String label(ChartsScreen screen) {
    switch (screen) {
      case ChartsScreen.temperature:
        return 'T (°C)';
      case ChartsScreen.pressure:
        return 'P (hPa)';
      case ChartsScreen.relativeHumidity:
        return 'RH (%)';
      case ChartsScreen.rain:
        return 'Rain (mm)';
      case ChartsScreen.wind:
        return 'Wind (Km/h)';
    }
  }
}
