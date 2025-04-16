import 'dart:async';
import 'dart:convert'; // For jsonDecode
import 'dart:math';

import 'package:net.abidibo.wearos.cumianameteo/realtime/cubit/charts_cubit.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/cubit/station_cubit.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/model/day_data.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:wearable_rotary/wearable_rotary.dart' as wearable_rotary
    show rotaryEvents;
import 'package:wearable_rotary/wearable_rotary.dart' hide rotaryEvents;
import 'package:fl_chart/fl_chart.dart';

class ChartsView extends StatefulWidget {
  ChartsView({
    super.key,
    @visibleForTesting Stream<RotaryEvent>? rotaryEvents,
  }) : rotaryEvents = rotaryEvents ?? wearable_rotary.rotaryEvents;

  final Stream<RotaryEvent> rotaryEvents;

  @override
  State<ChartsView> createState() => _ChartsViewState();
}

class AppColors {
  static const Color mainGridLineColor = Color(0xFF101010);
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorCyan = Color(0xFF50E4FF);
}

class RealtimeChartsPage extends StatelessWidget {
  const RealtimeChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChartsCubit(initialScreen: ChartsScreen.temperature),
      child: ChartsView(),
    );
  }
}

class _ChartsViewState extends State<ChartsView> {
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
    final cubit = context.read<ChartsCubit>();

    try {
      final response = await http.get(
        Uri.parse(
          'https://torinometeo.org/api/v1/realtime/today/data/cumiana/',
        ),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;
        final timeDataList = <TimeData>[];
        for (final item in json) {
          final it = item as Map<String, dynamic>;
          final timeData = TimeData(
            datetime: it['datetime'] as String,
            temperature: double.parse(it['temperature'] as String),
            relativeHumidity: double.parse(it['relative_humidity'] as String),
            pressure: double.parse(it['pressure'] as String),
            windStrength: double.parse(it['wind_strength'] as String),
            rain: double.parse(it['rain'] as String),
          );
          timeDataList.add(timeData);
        }
        ;
        final dayData = DayData(
          timeDataList: timeDataList,
        );
        cubit.loadData(dayData);
      } else {
        setState(() {
          error = 'Error: ${response.statusCode}';
          isLoading = false;
        });
        log(1000);
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
          children: <Widget>[
            const ChartsLabelText(),
            const ChartsDatetimeText(),
            Chart(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.read<ChartsCubit>().prev(),
                  child: const Icon(Icons.arrow_back),
                ),
                ElevatedButton(
                  onPressed: fetchData,
                  child: const Icon(Icons.refresh),
                ),
                ElevatedButton(
                  onPressed: () => context.read<ChartsCubit>().next(),
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

class ChartsLabelText extends StatelessWidget {
  const ChartsLabelText({super.key});

  @override
  Widget build(BuildContext context) {
    final label = context.select(
      (ChartsCubit cubit) => cubit.state.dayData?.label(cubit.state.screen),
    );
    if (label == null) return const Text('Loading...');
    return Text(label);
  }
}

class ChartsDatetimeText extends StatelessWidget {
  const ChartsDatetimeText({super.key});

  @override
  Widget build(BuildContext context) {
    final date = context.select((ChartsCubit cubit) =>
        cubit.state.dayData?.timeDataList.isNotEmpty != null
            ? cubit.state.dayData!.timeDataList[0].datetime
            : null);
    if (date == '' || date == null) return const Text('');
    return Text(formatDateString(date), style: const TextStyle(fontSize: 10));
  }
}

class Chart extends StatelessWidget {
  Chart({super.key});

  final List<Color> gradientColors = [
    AppColors.contentColorCyan,
    AppColors.contentColorBlue,
  ];

  @override
  Widget build(BuildContext context) {
    final data = context
        .select((ChartsCubit cubit) => cubit.state.dayData?.timeDataList);
    final screen = context.select((ChartsCubit cubit) => cubit.state.screen);

    if (data == null) return const Text('');
    return AspectRatio(
      aspectRatio: 2,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 30,
          left: 24,
          top: 16,
          bottom: 0,
        ),
        child: LineChart(
          mainData(screen, data),
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 8,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('00:00', style: style);
      case 360:
        text = const Text('06:00', style: style);
      case 720:
        text = const Text('12:00', style: style);
      case 1080:
        text = const Text('18:00', style: style);
      case 1440:
        text = const Text('24:00', style: style);
      default:
        text = const Text('', style: style);
    }

    return SideTitleWidget(
      meta: meta,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 8,
    );
    final text = value.toInt().toString();
    return Text(text, style: style, textAlign: TextAlign.left);
  }

  List<FlSpot> toTimeSeriesFlSpots(List<TimeData> data, ChartsScreen screen) {
    if (data.isEmpty ?? true) return <FlSpot>[];

    // begin of day timestamp
    final firstDate = data.first.datetime;
    // add 6 hours because of timezone
    final parsedFirstDate =
        DateTime.parse(data.first.datetime).add(const Duration(hours: 6));
    final beginOfDay = DateTime(
      parsedFirstDate.year,
      parsedFirstDate.month,
      parsedFirstDate.day,
    ).millisecondsSinceEpoch.toDouble();

    final spots = data
        .map(
          (e) => FlSpot(
            (DateTime.parse(e.datetime).millisecondsSinceEpoch.toDouble() -
                    beginOfDay) /
                1000 /
                60, // minutes
            e.get(screen) ?? 0,
          ),
        )
        .toList();
    return spots;
  }

  LineChartData mainData(ChartsScreen screen, List<TimeData> data) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 10,
        verticalInterval: 360,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: AppColors.mainGridLineColor,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: AppColors.mainGridLineColor,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 20,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff101010)),
      ),
      // minX: 1744754446000,
      // maxX: 1744755048000,
      // minY: 0,
      // maxY: 40,
      lineBarsData: [
        LineChartBarData(
          spots: toTimeSeriesFlSpots(data, screen),
          // spots: const [
          //   FlSpot(0, 3),
          //   FlSpot(2.6, 2),
          //   FlSpot(4.9, 5),
          //   FlSpot(6.8, 3.1),
          //   FlSpot(8, 4),
          //   FlSpot(9.5, 3),
          //   FlSpot(11, 4),
          // ],
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withValues(alpha: 0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
