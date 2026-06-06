import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/tracking_metrics_provider.dart';
import 'providers/location_tracking_provider.dart';
import 'providers/supabase_sync_provider.dart';
import 'screens/map_screen.dart';
import 'location/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupCrashLogger();
  await initializeBackgroundService();
  
  try {
    await Supabase.initialize(
      url: 'https://ywzanyqlvqkibhfgbqrr.supabase.co',
      anonKey: 'sb_publishable__-8a1-Lp1WU6VuePjAhGZQ_x4q6pdEp',
    );
  } catch (e) {
    print("Supabase initialization skipped or failed: $e");
  }
  
  runApp(const TurfApp());
}

void setupCrashLogger() {
  FlutterError.onError = (FlutterErrorDetails details) async {
    FlutterError.presentError(details); // Print to console
    await _logCrash(details.exception.toString(), details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _logCrash(error.toString(), stack.toString());
    return true;
  };
}

Future<void> _logCrash(String exception, String stackTrace) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logFile = File('${directory.path}/crash_log.txt');
    final sink = logFile.openWrite(mode: FileMode.append);
    sink.writeln("=========================================");
    sink.writeln("CRASH TIME: ${DateTime.now()}");
    sink.writeln("EXCEPTION: $exception");
    sink.writeln("STACK TRACE:\n$stackTrace");
    sink.writeln("=========================================\n");
    await sink.close();
  } catch (e) {
    print("Crash logging failed: $e");
  }
}

class TurfApp extends StatelessWidget {
  const TurfApp({super.key});

  @override
  Widget build(BuildContext context) {
    final metricsProvider = TrackingMetricsProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: metricsProvider),
        ChangeNotifierProvider(create: (_) => LocationTrackingProvider(metricsProvider: metricsProvider)),
        ChangeNotifierProvider(create: (_) => SupabaseSyncProvider()),
      ],
      child: MaterialApp(
        title: 'TURF Walk Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF2196F3), // Vibrant blue
          scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Slate dark
          cardColor: const Color(0xFF1E293B), // Slate card bg
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2196F3),
            secondary: Color(0xFF4CAF50),
            surface: Color(0xFF1E293B),
            background: const Color(0xFF0F172A),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyMedium: TextStyle(
              fontSize: 14.0,
              color: Colors.white70,
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const MapScreen(),
      ),
    );
  }
}
