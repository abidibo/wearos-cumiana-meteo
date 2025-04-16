import 'dart:async';
import 'dart:convert'; // For jsonDecode

import 'package:net.abidibo.wearos.cumianameteo/realtime/cubit/station_cubit.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/model/realtime_data.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:wearable_rotary/wearable_rotary.dart' as wearable_rotary
    show rotaryEvents;
import 'package:wearable_rotary/wearable_rotary.dart' hide rotaryEvents;

class RealtimePage extends StatelessWidget {
  const RealtimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StationCubit(initialScreen: Screen.temperature),
      child: StationView(),
    );
  }
}

class StationView extends StatefulWidget {
  StationView({
    super.key,
    @visibleForTesting Stream<RotaryEvent>? rotaryEvents,
  }) : rotaryEvents = rotaryEvents ?? wearable_rotary.rotaryEvents;

  final Stream<RotaryEvent> rotaryEvents;

  @override
  State<StationView> createState() => _StationViewState();
}

class _StationViewState extends State<StationView> {
  late final StreamSubscription<RotaryEvent> rotarySubscription;
  String? valueFromApi;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    rotarySubscription = widget.rotaryEvents.listen(handleRotaryEvent);
    fetchData();
  }

  @override
  void dispose() {
    rotarySubscription.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    final cubit = context.read<StationCubit>();

    try {
      final response = await http.get(
        Uri.parse(
          'https://www.torinometeo.org/api/v1/realtime/data/cumiana/',
        ),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final realtimeData = RealtimeData(
          stationName:
              (json['station'] as Map<String, dynamic>)['name'] as String,
          weatherIcon:
              (json['weather_icon'] as Map<String, dynamic>)['icon'] as String,
          datetime: json['datetime'] as String,
          temperature: double.parse(json['temperature'] as String),
          temperatureMax: double.parse(json['temperature_max'] as String),
          temperatureMin: double.parse(json['temperature_min'] as String),
          relativeHumidity: double.parse(json['relative_humidity'] as String),
          relativeHumidityMax:
              double.parse(json['relative_humidity_max'] as String),
          relativeHumidityMin:
              double.parse(json['relative_humidity_min'] as String),
          pressure: double.parse(json['pressure'] as String),
          pressureMax: double.parse(json['pressure_max'] as String),
          pressureMin: double.parse(json['pressure_min'] as String),
          windStrength: double.parse(json['wind_strength'] as String),
          windDirection: json['wind_dir_text'] as String,
          windStrengthMax: double.parse(json['wind_strength_max'] as String),
          windDirectionMax: json['wind_dir_max_text'] as String,
          rainRate: double.parse(json['rain_rate'] as String),
          rain: double.parse(json['rain'] as String),
        );
        cubit.loadData(realtimeData);
      } else {
        setState(() {
          error = 'Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: fetch';
        isLoading = false;
      });
    }
  }

  void handleRotaryEvent(RotaryEvent event) {
    final cubit = context.read<StationCubit>();
    if (event.direction == RotaryDirection.clockwise) {
      cubit.next();
    } else {
      cubit.prev();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Cumiana',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFFBDBDBD),),
            ),
            const DatetimeText(),
            const SizedBox(
              height: 5,
            ),
            // const LabelText(),
            const DataText(),
            const DataExtremes(),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.read<StationCubit>().prev(),
                  child: const Icon(Icons.arrow_back),
                ),
                ElevatedButton(
                  onPressed: fetchData,
                  child: const Icon(Icons.refresh),
                ),
                ElevatedButton(
                  onPressed: () => context.read<StationCubit>().next(),
                  // onPressed: fetchData,
                  child: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DatetimeText extends StatelessWidget {
  const DatetimeText({super.key});

  @override
  Widget build(BuildContext context) {
    final date = context
        .select((StationCubit cubit) => cubit.state.realtimeData?.datetime);
    if (date == '' || date == null) return const Text('');
    return Text(formatDateString(date), style: const TextStyle(fontSize: 10));
  }
}

class LabelText extends StatelessWidget {
  const LabelText({super.key});

  @override
  Widget build(BuildContext context) {
    final label = context.select(
      (StationCubit cubit) =>
          cubit.state.realtimeData?.label(cubit.state.screen),
    );
    if (label == null) return const Text('');
    return Text(label, style: const TextStyle(fontSize: 10));
  }
}

class DataText extends StatelessWidget {
  const DataText({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = context.select(
      (StationCubit cubit) =>
          cubit.state.realtimeData?.data(cubit.state.screen, theme),
    );
    if (w == null) return const Text('');
    return w;
  }
}

class DataExtremes extends StatelessWidget {
  const DataExtremes({super.key});

  @override
  Widget build(BuildContext context) {
    final row = context.select(
      (StationCubit cubit) =>
          cubit.state.realtimeData?.dataExtremes(cubit.state.screen),
    );
    if (row == null) return const Text('');
    return row;
  }
}
