import 'package:bloc/bloc.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/model/day_data.dart';

enum ChartsScreen {
  temperature,
  relativeHumidity,
  pressure,
  wind,
  rain,
}

class ChartsState {
  ChartsState({required this.dayData, required this.screen});

  final DayData? dayData;
  final ChartsScreen screen;

  ChartsState copyWith({
    DayData? dayData,
    ChartsScreen? screen,
  }) {
    return ChartsState(
      dayData: dayData ?? this.dayData,
      screen: screen ?? this.screen,
    );
  }
}

class ChartsCubit extends Cubit<ChartsState> {
  ChartsCubit(
      {required ChartsScreen initialScreen, DayData? initialDayData,})
      : super(ChartsState(
            screen: initialScreen, dayData: initialDayData,),);

  final List<ChartsScreen> screens = [
    ChartsScreen.temperature,
    ChartsScreen.pressure,
    ChartsScreen.relativeHumidity,
    ChartsScreen.rain,
    ChartsScreen.wind,
  ];

  void loadData(DayData newData) {
    emit(state.copyWith(dayData: newData));
  }

  void next() {
    final currentIndex = screens.indexOf(state.screen);
    final nextIndex = (currentIndex + 1) % screens.length;

    emit(state.copyWith(screen: screens[nextIndex]));
  }

  void prev() {
    final currentIndex = screens.indexOf(state.screen);
    final prevIndex = (currentIndex - 1 + screens.length) % screens.length;

    emit(state.copyWith(screen: screens[prevIndex]));
  }
}
