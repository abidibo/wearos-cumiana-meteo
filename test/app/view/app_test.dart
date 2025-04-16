import 'package:net.abidibo.wearos.cumianameteo/ambient_mode/ambient_mode.dart';
import 'package:net.abidibo.wearos.cumianameteo/app/app.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/realtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group('App', () {
    setUpAll(() {
      AmbientModeListener.instance.value = false;
    });

    group('renders the correct color scheme', () {
      testWidgets('on ambient mode updates', (tester) async {
        await tester.pumpWidget(const App());

        MaterialApp getMaterialApp() {
          return find.byType(MaterialApp).evaluate().first.widget
              as MaterialApp;
        }

        expect(
          getMaterialApp().theme?.colorScheme,
          const ColorScheme.dark(
            primary: Color(0xFF00B5FF),
          ),
        );

        await simulatePlatformCall('ambient_mode', 'onUpdateAmbient');
        await tester.pumpAndSettle();

        expect(
          getMaterialApp().theme?.colorScheme,
          const ColorScheme.dark(
            primary: Colors.white24,
            onSurface: Colors.white10,
          ),
        );

        await simulatePlatformCall('ambient_mode', 'onExitAmbient');
        await tester.pumpAndSettle();

        expect(
          getMaterialApp().theme?.colorScheme,
          const ColorScheme.dark(
            primary: Color(0xFF00B5FF),
          ),
        );
      });
    });
  });
}
