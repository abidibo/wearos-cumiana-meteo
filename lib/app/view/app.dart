import 'package:net.abidibo.wearos.cumianameteo/ambient_mode/ambient_mode.dart';
import 'package:net.abidibo.wearos.cumianameteo/realtime/realtime.dart';
import 'package:net.abidibo.wearos.cumianameteo/l10n/l10n.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AmbientModeBuilder(
      child: const RealtimePage(),
      builder: (context, isAmbientModeActive, child) {
        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            // This makes elements such as buttons have a fewer pixels in
            // padding and general spacing. good for devices with limited screen
            // real state.
            visualDensity: VisualDensity.compact,
            // When in ambient mode, change the apps color scheme
            colorScheme: isAmbientModeActive
                ? const ColorScheme.dark(
                    primary: Colors.white24,
                    onSurface: Colors.white10,
                  )
                : const ColorScheme.dark(
                    primary: Color(0xFF00B5FF),
                  ),
          ),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => child!, // This is your home route
            '/charts': (context) => const RealtimeChartsPage(), // The new route
          },
          initialRoute: '/', // Set the home route as the initial route
        );
      },
    );
  }
}
