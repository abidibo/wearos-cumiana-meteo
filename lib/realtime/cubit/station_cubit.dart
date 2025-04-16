import 'package:bloc/bloc.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/model/realtime_data.dart';

enum Screen {
  temperature,
  weather,
  relativeHumidity,
  pressure,
  wind,
  rain,
}

class StationState {
  StationState({required this.realtimeData, required this.screen});

  final RealtimeData? realtimeData;
  final Screen screen;

  StationState copyWith({
    RealtimeData? realtimeData,
    Screen? screen,
  }) {
    return StationState(
      realtimeData: realtimeData ?? this.realtimeData,
      screen: screen ?? this.screen,
    );
  }
}

class StationCubit extends Cubit<StationState> {
  StationCubit(
      {required Screen initialScreen, RealtimeData? initialRealtimeData,})
      : super(StationState(
            screen: initialScreen, realtimeData: initialRealtimeData,),);

  final List<Screen> screens = [
    Screen.temperature,
    Screen.pressure,
    Screen.relativeHumidity,
    Screen.rain,
    Screen.wind,
    Screen.weather,
  ];

  void loadData(RealtimeData newData) {
    emit(state.copyWith(realtimeData: newData));
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
